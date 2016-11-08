/*
    This file is part of SpTOL.

    SpTOL is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as
    published by the Free Software Foundation, either version 3 of
    the License, or (at your option) any later version.

    SpTOL is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with SpTOL.
    If not, see <http://www.gnu.org/licenses/>.
*/

#include <SpTOL.h>

int sptSparseTensorMulScalar(sptSparseTensor *X, sptScalar a) {
    if(a != 0) {
        size_t i;
        #pragma omp parallel for schedule(static)
        for(i = 0; i < X->nnz; ++i) {
            X->values.data[i] *= a;
        }
    } else {
        X->nnz = 0;
        X->values.len = 0;
    }
    return 0;
}
