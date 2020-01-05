#!/bin/bash

source setup.sh &&
rm -rf OpenBLAS install build &&
mkdir install &&
git clone https://github.com/xianyi/OpenBLAS.git &&
cd OpenBLAS &&
make -j8 &&
make PREFIX=/work/zhang-x1/users/nks45/ParTI/install install &&
cd .. &&
export CMAKE_PREFIX_PATH=$PWD/install &&
./build.sh

