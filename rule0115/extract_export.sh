#!/bin/bash

# $1 - linux kernel sources directory
# $2 - export definitions file
# $3 - export names file 

extracted="$(mktemp)"

rm -f "$2" "$3"

for i in $(find "$1" -type d \( -path '*/Documentation/*' -o -path '*/firmware/*' -o -path '*/samples/*' -o -path '*/scripts/*' -o -path '*/tools/*' \)  -prune -o -type f -name '*.[ch]' -print)
do
	cat "$i" | ./remove_cmnts.pl | ./remove_macros.pl | ./extract_export.pl >> "$extracted"
done

cat "$extracted" | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null
rm -f "$extracted"

sed -i -e 's/\*[[:space:]]\+\*/**/g' "$2"
sed -i -e 's/\([[:alnum:]_]\+\)[[:space:]]\+(/\1(/' "$2"

