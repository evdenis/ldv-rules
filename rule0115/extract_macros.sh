#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros definitions file
# $3 - macros names file


extracted="$(mktemp)"

rm -f "$2" "$3"

for i in $(find "$1" -type f -name '*.h')
do
	./extract_macros.pl "$i" >> "$extracted"
done

cat "$extracted" | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
rm -f "$extracted"

sed -i -e 's/[[:space:]]\+//g' "$2"

