#!/bin/bash


# $1 - linux kernel sources directory
# $2 - inline definitions file
# $3 - inline names file 


rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.h')
do
	grep -oe '^[[:space:]]*static[[:space:]]*inline[[:space:]]*\([[:alnum:]_]*\**[[:space:]]*\)*[[:alnum:]_]*[[:space:]]*(' "$i" |
	sed -e 's/^[[:space:]]*//' -e 's/(/(..)/' |
	tee -a -i "$2" |
	sed -ne 's/^[[:blank:]]*static[[:space:]]*inline[[:space:]]*\([[:alnum:]_]*\**[[:space:]]*\)*\([[:alnum:]_]*\)[[:space:]]*(.*$/\1/p' >> "$3"
done

