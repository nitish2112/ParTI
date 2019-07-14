#!/bin/bash

./build/tests/test_tucker -o $1.out  --dev $2 $1-parti.tns 64 64 64 0 1 2 #-r 64
