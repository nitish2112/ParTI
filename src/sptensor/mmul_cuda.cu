#include <SpTOL.h>
#include <stdio.h>
#include <stdlib.h>

__global__ static void spt_TTMKernel(
    sptScalar *Y_val, size_t Y_stride, size_t Y_nnz,
    const sptScalar *X_val, size_t X_nnz, size_t *X_inds_m,
    size_t *fiberidx_val, size_t fiberidx_len,
    const sptScalar *U_val, size_t U_nrows, size_t U_ncols, size_t U_stride,
    size_t block_offset
) {
    extern __shared__ char mem_pool[];
    const size_t bid = blockIdx.x + block_offset;
    const size_t tid = threadIdx.x;
    // jli: no need to store Y_shr, X_shr, and r_shr in shared memory, Only U.
    sptScalar *const Y_shr = (sptScalar *) &mem_pool[0]; // size U_ncols
    sptScalar *const X_shr = (sptScalar *) &mem_pool[U_ncols * sizeof (sptScalar)]; // size U_nrows
    size_t *const r_shr = (size_t *) &mem_pool[(U_ncols+U_nrows) * sizeof (sptScalar)]; // size U_nrows

    const size_t inz_begin = fiberidx_val[bid];
    const size_t inz_end = fiberidx_val[bid+1];
    size_t i, j;
    // Fill Y_shr with 0, length U_ncols
    Y_shr[tid] = 0;
    // Fill X_shr with X_val, length inz_end-inz_begin
    for(i = tid; i < inz_end-inz_begin; i += blockDim.x) {
        X_shr[i] = X_val[i+inz_begin];
    }
    // Fill r_shr with X_inds_m, length inz_end-inz_begin
    for(i = tid; i < inz_end-inz_begin; i += blockDim.x) {
        r_shr[i] = X_inds_m[i+inz_begin];
    }
    __syncthreads();
    // Do calculations, length U_ncols
    for(i = tid; i < U_ncols; i += blockDim.x) {
        for(j = 0; j < inz_end-inz_begin; ++j) {
            Y_shr[i] += X_shr[j] * U_val[r_shr[j]*U_stride + i];
        }
    }
    __syncthreads();
    // Write back from Y_shr, length U_ncols
    for(i = tid; i < U_ncols; ++i) {
        Y_val[bid*Y_stride + i] = Y_shr[i];
    }
}

__global__ static void spt_TTMNaiveKernel(
    sptScalar *Y_val, size_t Y_stride, size_t Y_nnz,
    const sptScalar *X_val, size_t X_nnz, size_t *X_inds_m,
    size_t *fiberidx_val, size_t fiberidx_len,
    const sptScalar *U_val, size_t U_nrows, size_t U_ncols, size_t U_stride,
    size_t block_offset
) {
    const size_t i = blockIdx.x + block_offset;
    const size_t tid = threadIdx.x;
    const size_t inz_begin = fiberidx_val[i];
    const size_t inz_end = fiberidx_val[i+1];
    for(size_t k = tid; k < U_ncols; k += blockDim.x) {
        Y_val[i*Y_stride + k] = 0;
        for(size_t j = inz_begin; j < inz_end; ++j) {
            size_t r = X_inds_m[j];
            Y_val[i*Y_stride + k] += X_val[j] * U_val[r*U_stride + k];
        }
    }
}

int sptCudaSparseTensorMulMatrix(
    sptSemiSparseTensor *Y,
    sptSparseTensor *X,
    const sptMatrix *U,
    size_t mode
) {
    int result;
    size_t *ind_buf;
    size_t m;
    sptSizeVector fiberidx;
    if(mode >= X->nmodes) {
        return -1;
    }
    if(X->ndims[mode] != U->nrows) {
        return -1;
    }
    if(X->sortkey != mode) {
        sptSparseTensorSortIndexAtMode(X, mode);
    }
    ind_buf = new size_t[X->nmodes * sizeof *ind_buf];
    if(!ind_buf) {
        return -1;
    }
    for(m = 0; m < X->nmodes; ++m) {
        ind_buf[m] = X->ndims[m];
    }
    ind_buf[mode] = U->ncols;
    result = sptNewSemiSparseTensor(Y, X->nmodes, mode, ind_buf);
    delete[] ind_buf;
    if(result) {
        return result;
    }
    sptSemiSparseTensorSetIndices(Y, &fiberidx, X);

    sptScalar *Y_val = NULL;
    result = cudaMalloc((void **) &Y_val, Y->nnz * Y->stride * sizeof (sptScalar));
    if(result != 0) {
        return result; // TODO: map error code?
    }
    // jli: Add memset to Y.
    cudaMemset(Y_val, 0, Y->nnz * Y->stride * sizeof (sptScalar));
    sptScalar *X_val = NULL;
    result = cudaMalloc((void **) &X_val, X->nnz * sizeof (sptScalar));
    if(result != 0) {
        return result; // TODO: map error code?
    }
    cudaMemcpy(X_val, X->values.data, X->nnz * sizeof (sptScalar), cudaMemcpyHostToDevice);
    size_t *X_inds_m = NULL;
    result = cudaMalloc((void **) &X_inds_m, X->nnz * sizeof (size_t));
    if(result != 0) {
        return result; // TODO: map error code?
    }
    cudaMemcpy(X_inds_m, X->inds[mode].data, X->nnz * sizeof (size_t), cudaMemcpyHostToDevice);
    sptScalar *U_val = NULL;
    result = cudaMalloc((void **) &U_val, U->nrows * U->stride * sizeof (sptScalar));
    if(result != 0) {
        return result;
    }
    cudaMemcpy(U_val, U->values, U->nrows * U->stride * sizeof (sptScalar), cudaMemcpyHostToDevice);
    size_t *fiberidx_val = NULL;
    result = cudaMalloc((void **) &fiberidx_val, fiberidx.len * sizeof (size_t));
    if(result != 0) {
        return result;
    }
    cudaMemcpy(fiberidx_val, fiberidx.data, fiberidx.len * sizeof (size_t), cudaMemcpyHostToDevice);

    const char *env_SPTOL_TTM_KERNEL = getenv("SPTOL_TTM_KERNEL");
    const bool use_naive_kernel = env_SPTOL_TTM_KERNEL && !strcmp(env_SPTOL_TTM_KERNEL, "naive");

    const size_t max_nblocks = 32768;
    const size_t max_nthreads = 1024;
    size_t sharedMem = (Y->ndims[mode] + X->ndims[mode])*sizeof (sptScalar) + X->ndims[mode]*sizeof (size_t);
    size_t nblocks = Y->nnz < max_nblocks ? Y->nnz : max_nblocks;
    size_t nthreads = U->ncols < max_nthreads ? U->ncols : max_nthreads;
    if(!use_naive_kernel) {
        fprintf(stderr, "[CUDA SpTns * Mtx] spt_TTMKernel<<<%zu, %zu, %zu>>>\n", nblocks, nthreads, sharedMem);
    } else {
        fprintf(stderr, "[CUDA SpTns * Mtx] spt_TTMNaiveKernel<<<%zu, %zu, 0>>>\n", nblocks, nthreads);
    }

    sptTimer timer;
    sptNewTimer(&timer, 0);
    sptStartTimer(timer);

    for(size_t block_offset = 0; block_offset < Y->nnz; block_offset += max_nblocks) {
        size_t nblocks = Y->nnz - block_offset;
        if(nblocks > max_nblocks) {
            nblocks = max_nblocks;
        }
        if(!use_naive_kernel) {
            spt_TTMKernel<<<nblocks, nthreads, sharedMem>>>(
                Y_val, Y->stride, Y->nnz,
                X_val, X->nnz, X_inds_m,
                fiberidx_val, fiberidx.len,
                U_val, U->nrows, U->ncols, U->stride,
                block_offset
            );
        } else {
            spt_TTMNaiveKernel<<<nblocks, nthreads>>>(
                Y_val, Y->stride, Y->nnz,
                X_val, X->nnz, X_inds_m,
                fiberidx_val, fiberidx.len,
                U_val, U->nrows, U->ncols, U->stride,
                block_offset
            );
        }
        result = cudaGetLastError();
        if(result != 0) {
            return result;
        }
    }

    sptStopTimer(timer);
    sptPrintElapsedTime(timer, "CUDA SpTns * Mtx");
    sptFreeTimer(timer);

    cudaMemcpy(Y->values.values, Y_val, Y->nnz * Y->stride * sizeof (sptScalar), cudaMemcpyDeviceToHost);
    cudaFree(fiberidx_val); cudaFree(U_val); cudaFree(X_inds_m); cudaFree(X_val); cudaFree(Y_val);
    sptFreeSizeVector(&fiberidx);

    return 0;
}
