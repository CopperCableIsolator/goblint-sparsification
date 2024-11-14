#!/bin/bash

rm output_timing.txt

# Loop from 01 to 20
for i in $(seq -w 1 20); do
    ./regtest.sh 63 $i --enable dbg.timing.enabled 2>> output_timing.txt
done

