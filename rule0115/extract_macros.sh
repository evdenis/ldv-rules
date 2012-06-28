#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros definitions file
# $3 - macros names file


rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.h')
do
	./extract_macros.pl "$i" | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
done

