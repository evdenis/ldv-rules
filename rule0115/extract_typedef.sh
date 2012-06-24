#!/bin/bash

# $1 - linux kernel sources directory
# $2 - typedef names file

rm -f "$2"

for i in $(find "$1" -type f -name '*.h')
do
	./extract_typedef.pl "$i" >> "$2"
done 

