#!/bin/bash

# $1 - linux kernel sources directory
# $2 - export definitions file
# $3 - export names file 

rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.[ch]')
do
	cat "$i" | ./extract_export.pl | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
done 

