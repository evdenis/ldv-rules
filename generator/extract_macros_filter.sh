#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros names file 

# extraction of non-function-like macros

rm -f "$2"

grep -r -h -I --include '*.h' -oe '^[[:space:]]*#[[:space:]]*define[[:space:]]\+[[:alnum:]_]\+[[:space:]]' "$1" |
sed -e 's/[[:space:]]*#[[:space:]]*define[[:space:]]\+//' |
sed -ne 's/^\([[:alnum:]_]\+\).*$/\1/p' >> "$2"

