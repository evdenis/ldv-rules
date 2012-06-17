#!/bin/bash

cat ./export.txt > ./functions_.txt
cat ./define.txt >> ./functions_.txt
cat ./inline.txt >> ./functions_.txt

cat ./functions_.txt | sort | uniq > ./functions.txt

rm ./functions_.txt

comm -12 <(grep -e label ./graph.dot1 | cut -d '=' -f 2 | cut -b 2- | sort) ./functions.txt

