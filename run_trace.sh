#!/bin/bash

# Loop from 01 to 20
for i in $(seq -w 1 20); do
    ./regtest.sh 63 $i --trace col --trace row 2>> output_trace.txt
done

# Count the occurrences of lines beginning with '%%% row:' and '%%% col:' in the output file
row_count=$(grep -c "^%%% row:" output_trace.txt)
col_count=$(grep -c "^%%% col:" output_trace.txt)

# Append the counts to the file
echo "Number of lines starting with '%%% row:': $row_count" >> output_trace.txt
echo "Number of lines starting with '%%% col:': $col_count" >> output_trace.txt