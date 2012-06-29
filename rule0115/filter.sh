#!/bin/bash

# $1 - linux kernel sources
# $2 - file to filter

dir="$1"
file="$2"

tmp="$(mktemp)"
#file_define="$(mktemp)"
file_define="./rule_cache/macros_without_args"
filter_define="./rule_cache/macros_filter"

#configuration
filter_step=1000

[[ ! -r "$file_define" ]] && ./extract_macros_filter.sh "$dir" "$file_define"


if [[ ! -r "$filter_define" ]]
then
   cat ./filter.preset > "$filter_define"
   #FIXME: explicit naming
   #TODO: proper filtering of function-like macros
   #grep -h -e '^__[a-z][a-z_]*$' "$file_define" ./rule_cache/mnames >> "$filter_define"
   grep -h -e '^__[a-z][a-z_]*$' "$file_define" >> "$filter_define"
   sort -bi -u -o "$filter_define" "$filter_define"
fi


#attribute filter
perl -n -e 's/__attribute__[ \t]*\((?<b>\((?:[^\(\)]|(?&b))*\))\)[ \t]*//g; print' "$file" > "$tmp"

#macros filter construction
filter=''
nol=$(cat "$filter_define" | wc -l)
for (( i=1; i<$nol; i+=$filter_step ))
do
   filter=$(tail -n +${i} "$filter_define" | head -n $filter_step | tr '\n' '|' | sed -e 's/|$//')
   if [[ -n "$filter" ]]
   then
      perl -i -n -e "s/\s*(?:$filter)((\s|\*)+)(?!\()/\$1/g; print;" "$tmp"
   fi
done

sed -i -e 's/^[[:space:]]\+//' "$tmp"
sed -i -e 's/\*[[:space:]]\+\*/**/g' "$tmp"
sed -i -e 's/\([[:alnum:]_]\+\)[[:space:]]\+(/\1(/' "$tmp"

cp -f "$tmp" "$file"
rm -f "$tmp"

