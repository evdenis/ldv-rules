#!/bin/bash

# $1 - linux kernel sources directory
# $2 - export definitions file
# $3 - export names file 

rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.[ch]')
do
	for j in $(sed -ne 's/^[[:space:]]*EXPORT_SYMBOL_GPL([[:blank:]]*\([[:alnum:]_]*\)[[:blank:]]*);.*$/\1/p' "$i")
	do
		tmp=$(grep -oe "^\([[:alnum:]_]*\**[[:space:]]*\)*$j[[:space:]]*(" "$i" | sed -e '/^[[:space:]]*\**[[:space:]]*.*$/d' -e "/^[[:space:]]*$j.*$/d" )
		if [[ -n "$tmp" ]]
		then
			echo "$tmp" | sed -e 's/(/(..)/' >> "$2"
			echo "$j" >> "$3"
		else
			echo $j
		fi
	done
done 

