#!/bin/bash

rm "define.txt"

for i in $(find . -type f -name '*.h')
do
	sed -ne 's/^[[:space:]]*#define[[:space:]]*\([[:alnum:]_]*\)(.*$/\1/p' $i >> "./define.txt"
done

