#!/bin/bash

set -x

if [ ! -d $(PWD)/lib/backward-cpp ]; then git clone https://github.com/bombela/backward-cpp.git lib/backward-cpp fi
rm -rf install OpenBLAS build &&
source setup.sh &&
mkdir install &&
git clone https://github.com/xianyi/OpenBLAS.git &&
cd OpenBLAS &&
make -j8 &&
make PREFIX=/work/zhang-x1/users/nks45/ParTI/install install &&
cd .. &&
export CMAKE_PREFIX_PATH=$PWD/install &&
./build.sh
