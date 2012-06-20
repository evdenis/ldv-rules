#!/bin/bash

# $1 - linux kernel sources directory
# $2 - export definitions file
# $3 - export names file 

rm -f "$2" "$3"


for i in $(find "$1" -type f -name '*.[ch]')
do
	#tmp=$(pcregrep -M -o '[^\(\)\{\}\[\];,/#]+\w+\s*\([\w\s,*]*?\)\s*\{([^\{\}]|(?0))*\}\s*\n\s*EXPORT_SYMBOL_GPL\(\s*\w+\s*\)\s*;' "$i")
	#for j in $(echo $tmp | sed -ne 's/^[[:space:]]*EXPORT_SYMBOL_GPL([[:blank:]]*\([[:alnum:]_]*\)[[:blank:]]*);.*$/\1/p')
	#do
	#	name=$(echo $tmp | pcregrep -M -o "[^\(\)\{\}\[\];,/#]+$j+\s*\(" | tr -d '\n' )

	#	if [[ -n "$name" ]]
	#	then
	#		echo "$name" | sed -e 's/(/(..)/' >> "$2"
	#		echo "$j" >> "$3"
	#	else
	#		echo $j
	#	fi
	#done

done 

