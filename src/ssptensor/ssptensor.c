#include <SpTOL.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "ssptensor.h"

int sptNewSemiSparseTensor(sptSemiSparseTensor *tsr, size_t nmodes, size_t mode, const size_t ndims[]) {
    size_t i;
    int result;
    if(nmodes < 2) {
        spt_CheckError(SPERR_SHAPE_MISMATCH, "SspTns New", "nmodes < 2");
    }
    tsr->nmodes = nmodes;
    tsr->ndims = malloc(nmodes * sizeof *tsr->ndims);
    spt_CheckOSError(!tsr->ndims, "SspTns New");
    memcpy(tsr->ndims, ndims, nmodes * sizeof *tsr->ndims);
    tsr->mode = mode;
    tsr->nnz = 0;
    tsr->inds = malloc(nmodes * sizeof *tsr->inds);
    spt_CheckOSError(!tsr->inds, "SspTns New");
    for(i = 0; i < nmodes; ++i) {
        result = sptNewSizeVector(&tsr->inds[i], 0, 0);
        spt_CheckError(result, "SspTns New", NULL);
    }
    tsr->stride = ((ndims[mode]-1)/8+1)*8;
    result = sptNewMatrix(&tsr->values, 0, tsr->stride);
    spt_CheckError(result, "SspTns New", NULL);
    return 0;
}

int sptCopySemiSparseTensor(sptSemiSparseTensor *dest, const sptSemiSparseTensor *src) {
    size_t i;
    int result;
    assert(src->nmodes >= 2);
    dest->nmodes = src->nmodes;
    dest->ndims = malloc(dest->nmodes * sizeof *dest->ndims);
    spt_CheckOSError(!dest->ndims, "SspTns Copy");
    memcpy(dest->ndims, src->ndims, src->nmodes * sizeof *src->ndims);
    dest->mode = src->mode;
    dest->nnz = src->nnz;
    dest->inds = malloc(dest->nmodes * sizeof *dest->inds);
    spt_CheckOSError(!dest->inds, "SspTns Copy");
    for(i = 0; i < dest->nmodes; ++i) {
        result = sptCopySizeVector(&dest->inds[i], &src->inds[i]);
        spt_CheckError(result, "SspTns Copy", NULL);
    }
    dest->stride = src->stride;
    result = sptCopyMatrix(&dest->values, &src->values);
    spt_CheckError(result, "SspTns Copy", NULL);
    return 0;
}

void sptFreeSemiSparseTensor(sptSemiSparseTensor *tsr) {
    size_t i;
    for(i = 0; i < tsr->nmodes; ++i) {
        sptFreeSizeVector(&tsr->inds[i]);
    }
    free(tsr->ndims);
    free(tsr->inds);
    sptFreeMatrix(&tsr->values);
}
