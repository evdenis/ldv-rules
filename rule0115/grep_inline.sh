#!/bin/bash


for i in $(find . -type f -name '*.h')
do
	sed -ne 's/^[[:blank:]]*static[[:space:]]*inline[[:space:]]*\([[:alnum:]_]*\**[[:space:]]*\)*\([[:alnum:]_]*\)[[:space:]]*(.*$/\1/p' $i | tr -d ' '
#	grep -oe '^[[:blank:]]*static[[:space:]]*inline[[:space:]]*\([[:alnum:]_]*\**[[:space:]]*\)*\([[:alnum:]_]*\)[[:space:]]*(.*$' $i >> "./inline.txt"
done

