#!/bin/bash

# $1 - linux kernel sources directory
# $2 - export definitions file
# $3 - export names file 

rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.[ch]')
do
	cat "$i" | ./remove_cmnts.pl | ./remove_macros.pl | ./extract_export.pl | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
done 

sed -i -e 's/\*[[:space:]]\+\*/**/g' "$2"
sed -i -e 's/\([[:alnum:]_]\+\)[[:space:]]\+(/\1(/' "$2"

