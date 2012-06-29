#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros names file 

# extraction of non-function-like macros

rm -f "$2"

for i in $(find "$1" -type f -name '*.h')
do
	grep -oe '^[[:space:]]*#[[:space:]]*define[[:space:]]\+[[:alnum:]_]\+[[:space:]]' "$i" |
	sed -e 's/[[:space:]]*#[[:space:]]*define[[:space:]]\+//' |
	sed -ne 's/^\([[:alnum:]_]\+\).*$/\1/p' >> "$2"
done

