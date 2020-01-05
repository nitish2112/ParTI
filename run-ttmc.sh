#!/bin/bash

./build/tests/test_tucker -o $1.out  --dev $2 $1-parti.tns 16 16 16 0 1 2 #-r 64
