#!/bin/bash


# $1 - linux kernel sources directory
# $2 - inline definitions file
# $3 - inline names file 

rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.h')
do
	./extract_inline.pl "$i" | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
done

sed -i -e 's/\*[[:space:]]\+\*/**/g' "$2"
sed -i -e 's/\([[:alnum:]_]\+\)[[:space:]]\+(/\1(/' "$2"

