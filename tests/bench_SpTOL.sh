#!/bin/bash

do_test() {
    ~/Work/SpTOL/tests/ttm_new "$1" "999" 0 2>&1
#    for mode in `seq 0 "$(($2 - 1))"`
#    do
#        echo "File: $1, mode $mode"
#        SPTOL_TTM_NTHX=64 ~/Work/SpTOL/tests/ttm_new "$1" "$mode" 0 2>&1
#        SPTOL_TTM_NTHX=32 ~/Work/SpTOL/tests/ttm_new "$1" "$mode" 0 2>&1
#        SPTOL_TTM_NTHX=16 ~/Work/SpTOL/tests/ttm_new "$1" "$mode" 0 2>&1
#        SPTOL_TTM_NTHX=8 ~/Work/SpTOL/tests/ttm_new "$1" "$mode" 0 2>&1
#    done
}

do_test1() {
    for mode in `seq 0 "$(($2 - 1))"`
    do
        for dev in -2 -1
        do
            echo
            echo "File: $1, mode $mode"
            ~/Work/SpTOL/tests/ttm_new "$1" "$mode" "$dev" 2>&1
        done
        for dev in 0 1
        do
            echo
            echo "File: $1, mode $mode, dev $dev, normal kernel"
            ~/Work/SpTOL/tests/ttm_new "$1" "$mode" "$dev" 2>&1
            echo "File: $1, mode $mode, dev $dev, naïve kernel"
            SPTOL_TTM_KERNEL=naive ~/Work/SpTOL/tests/ttm_new "$1" "$mode" "$dev" 2>&1
        done
    done
}

main() {
    OMP_NUM_THREADS="`nproc`"
    echo "Number of CPU cores (including hyperthreads): $OMP_NUM_THREADS"
    lscpu
    /usr/local/cuda/samples/1_Utilities/deviceQuery/deviceQuery
    do_test /mnt/BIGDATA/jli/BIGTENSORS/brainq.fixed.tns 3
    do_test /mnt/BIGDATA/jli/BIGTENSORS/nell2.tns 3
    do_test /mnt/BIGDATA/jli/BIGTENSORS/delicious.tns 3
    do_test /mnt/BIGDATA/jli/BIGTENSORS/nell1.tns 3
    do_test /mnt/BIGDATA/jli/BIGTENSORS/3D_99883309.dat 3
    do_test /mnt/BIGDATA/jli/BIGTENSORS/3D_124996124.dat 3
}

echo "Log to test_log.txt"
main | tee test_log.txt
