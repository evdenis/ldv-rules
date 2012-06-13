#!/bin/bash

rm "export.txt"

for i in $(find . -type f -name '*.[ch]')
do
	sed -ne 's/^[[:space:]]*EXPORT_SYMBOL_GPL([[:blank:]]*\([[:alnum:]_]*\)[[:blank:]]*);.*$/\1/p' $i >> "./export.txt"
done 

