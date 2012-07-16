#!/bin/bash

#$1 - linux kernel sources directory
#cscope bug workaround

for i in $(find "$1" -type f -name '*.[ch]')
do
   sed -i -e 's/__printf([[:space:]]*[[:digit:]]\+[[:space:]]*,[[:space:]]*[[:digit:]]\+[[:space:]]*)//g' -e 's/__aligned([[:space:]]*[[:digit:]]\+[[:space:]]*)//g' "$i"
   perl -i -n -e '/(__acquire|__release)\(\s*(?!x)[\w->&]+\s*\)/; print;' "$i"
done

