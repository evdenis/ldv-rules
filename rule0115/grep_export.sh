#!/bin/bash

for i in $(find . -type f -name '*.[ch]')
do
	for j in $(sed -ne 's/^[[:space:]]*EXPORT_SYMBOL_GPL([[:blank:]]*\([[:alnum:]_]*\)[[:blank:]]*);.*$/\1/p' $i)
	do
		
	done
done 
