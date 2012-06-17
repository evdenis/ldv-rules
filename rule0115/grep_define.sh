#!/bin/bash

for i in $(find . -type f -name '*.h')
do
	sed -ne 's/^[[:space:]]*#define[[:space:]]*\([[:alnum:]_]*\)(.*$/\1/p' $i
#	cat "$i" | tr -d '\n' | sed -ne 's/^[[:space:]]*#define[[:space:]]*\([[:alnum:]_]*([[:alnum:],_]*)\).*$/\1/gp' >> "./define.txt"'
done

