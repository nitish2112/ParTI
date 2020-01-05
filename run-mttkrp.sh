#!/bin/bash

#nvprof --analysis-metrics --log-file mttkrp-analysis.log -o mttkrp-analysis.nvprof ./build/examples/mttkrp_gpu -i $1-parti.tns -o $1.out -m $2 -s 1 -d 2 -r 32 -p 15
./build/examples/mttkrp_gpu -i $1-parti.tns -o $1.out -m $2 -s 1 -d 2 -r 32 -p 15
