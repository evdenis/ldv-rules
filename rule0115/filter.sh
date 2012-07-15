#!/bin/bash

# $1 - linux kernel sources
# $2 - filter without args file
# $3 - filter file
# $4 - file to filter
# $5 - output

dir="$1"
filter_define_wa="$2"
filter_define="$3"
file="$4"
out="${5:-${file}}"

tmp="$(mktemp)"

#configuration
filter_step=1000

#attribute filter
perl -n -e 's/__attribute__[ \t]*\((?<b>\((?:[^\(\)]|(?&b))*\))\)[ \t]*//g; print' "$file" > "$tmp"
sed -i -e 's/asmlinkage//g' "$tmp"

#macros filter construction
filter=''
nol=$(cat "$filter_define_wa" | wc -l)
for (( i=1; i<$nol; i+=$filter_step ))
do
   filter=$(tail -n +${i} "$filter_define_wa" | head -n $filter_step | tr '\n' '|' | sed -e 's/|$//')
   if [[ -n "$filter" ]]
   then
      perl -i -n -e "s/\s*(?:$filter)(\s+)(?!\()/\1/g; print;" "$tmp"
   fi
done

filter=''
nol=$(cat "$filter_define" | wc -l)
for (( i=1; i<$nol; i+=$filter_step ))
do
   filter=$(tail -n +${i} "$filter_define" | head -n $filter_step | tr '\n' '|' | sed -e 's/|$//')
   if [[ -n "$filter" ]]
   then
      perl -i -n -e "s/\s*(?:$filter)\s*(?<args>\((?:[^\(\)]|(?&args))+\))(?!\s*$)//g; print;" "$tmp"
   fi
done

sed -i -e 's/^[[:space:]]\+//' "$tmp"
sed -i -e 's/\*[[:space:]]\+\*/**/g' "$tmp"
sed -i -e 's/\([[:alnum:]_]\+\)[[:space:]]\+(/\1(/' "$tmp"

cp -f "$tmp" "$out"
rm -f "$tmp"

