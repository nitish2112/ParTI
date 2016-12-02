/*
    This file is part of ParTI!.

    ParTI! is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of
    the License, or (at your option) any later version.

    ParTI! is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with ParTI!.
    If not, see <http://www.gnu.org/licenses/>.
*/

#include <ParTI.h>
#include "sptensor.h"

int sptSparseTensorDivScalar(sptSparseTensor *X, sptScalar a) {
    if(a != 0) {
        size_t i;
        #pragma omp parallel for schedule(static)
        for(i = 0; i < X->nnz; ++i) {
            X->values.data[i] /= a;
        }
        return 0;
    } else {
        spt_CheckError(SPTERR_ZERO_DIVISION, "SpTns Div", "divide by zero");
    }
}
