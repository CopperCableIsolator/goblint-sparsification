#!/bin/bash

rm output_trace.txt

# Loop from 01 to 20
for i in $(seq -w 1 20); do
    ./regtest.sh 63 $i --trace arrayMatrix 2>> output_trace.txt
done

call_count=$(grep -c "^%%% arrayMatrix:" output_trace.txt)

# Append the counts to the file
echo "Number of lines starting with '%%% arrayMatrix:': $call_count" >> output_trace.txt
