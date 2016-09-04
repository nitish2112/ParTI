#include <SpTOL.h>
#include <stdlib.h>

int sptOmpSparseTensorMulMatrix(sptSemiSparseTensor *Y, sptSparseTensor *X, const sptMatrix *U, size_t mode) {
    int result;
    size_t *ind_buf;
    size_t m, i;
    sptSizeVector fiberidx;
    if(mode >= X->nmodes) {
        sptCheckError(-1, "OMP  SpTns * Mtx");
    }
    if(X->ndims[mode] != U->nrows) {
        sptCheckError(-1, "OMP  SpTns * Mtx");
    }
    if(X->sortkey != mode) {
        sptSparseTensorSortIndexAtMode(X, mode);
    }
    // jli: try to avoid malloc in all operation functions.
    ind_buf = malloc(X->nmodes * sizeof *ind_buf);
    if(!ind_buf) {
        sptCheckError(-1, "OMP  SpTns * Mtx");
    }
    for(m = 0; m < X->nmodes; ++m) {
        ind_buf[m] = X->ndims[m];
    }
    ind_buf[mode] = U->ncols;
    // jli: use pre-processing to allocate Y size outside this function.
    result = sptNewSemiSparseTensor(Y, X->nmodes, mode, ind_buf);
    free(ind_buf);
    sptCheckError(result, "OMP  SpTns * Mtx");
    sptSemiSparseTensorSetIndices(Y, &fiberidx, X);

    sptTimer timer;
    sptNewTimer(&timer, 0);
    sptStartTimer(timer);

    #pragma omp parallel for
    for(i = 0; i < Y->nnz; ++i) {
        size_t inz_begin = fiberidx.data[i];
        size_t inz_end = fiberidx.data[i+1];
        size_t j, k;
        // jli: exchange two loops
        for(j = inz_begin; j < inz_end; ++j) {
            size_t r = X->inds[mode].data[j];
            for(k = 0; k < U->ncols; ++k) {
                Y->values.values[i*Y->stride + k] += X->values.data[j] * U->values[r*U->stride + k];
            }
        }
    }

    sptStopTimer(timer);
    sptPrintElapsedTime(timer, "OMP  SpTns * Mtx");
    sptFreeTimer(timer);

    sptFreeSizeVector(&fiberidx);
    return 0;
}
