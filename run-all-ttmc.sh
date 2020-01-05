#!/bin/bash

set -x

declare -a arr=("nell-2" "netflix" "poisson3D" "ml20m")

rm -rf result.log &&

for tensor in "${arr[@]}"
do
  echo "==========================================================" | tee -a result.log
  echo $tensor | tee -a result.log
  echo "==========================================================" | tee -a result.log
  ./run-ttmc.sh $tensor $1 2>&1 | tee -a result.log
done
