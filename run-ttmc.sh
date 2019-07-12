#!/bin/bash

gdb -args ./build/tests/test_tucker -o $1.out  --dev $3 $1-parti.tns #-r 64
