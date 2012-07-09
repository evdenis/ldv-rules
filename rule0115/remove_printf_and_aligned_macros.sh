#!/bin/bash

#$1 - linux kernel sources directory
#cscope bug workaround

for i in $(find "$1" -type d \( -path '*/Documentation/*' -o -path '*/firmware/*' -o -path '*/samples/*' -o -path '*/scripts/*' -o -path '*/tools/*' \)  -prune -o -type f -name '*.[ch]' -print)
do
   sed -i -e 's/__printf([[:space:]]*[[:digit:]]\+[[:space:]]*,[[:space:]]*[[:digit:]]\+[[:space:]]*)//g' -e 's/__aligned([[:space:]]*[[:digit:]]\+[[:space:]]*)//g' "$i"
done

