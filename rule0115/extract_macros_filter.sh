#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros definitions file
# $3 - macros names file 


rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.h')
do
	grep -oe '^[[:space:]]*#define[[:space:]]*[[:alnum:]_]*([[:alnum:][:space:]_,]*)' "$i" |
	sed -e 's/[[:space:]]*#define[[:space:]]*//' | tee -a -i "$2" |
	sed -ne 's/^\([[:alnum:]_]*\)(.*$/\1/p' >> "$3"
done

