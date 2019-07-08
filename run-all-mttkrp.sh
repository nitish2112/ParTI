#!/bin/bash

set -x

declare -a arr=("nell-2" "netflix" "poisson3D" "ml20m")

rm -rf result.log &&

for tensor in "${arr[@]}"
do
  echo "==========================================================" | tee -a result.log
  echo $tensor | tee -a result.log
  echo "==========================================================" | tee -a result.log
  for mode in `seq 0 2`
  do
    echo "**************** Mode $mode ****************" | tee -a result.log
    ./run-mttkrp.sh $tensor $mode 2>&1 | tee -a result.log
  done
done
