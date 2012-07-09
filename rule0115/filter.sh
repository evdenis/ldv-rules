#!/bin/bash

# $1 - linux kernel sources
# $2 - file to filter
# $3 - output

dir="$1"
file="$2"
out="${3:-${file}}"

tmp="$(mktemp)"
#file_define="$(mktemp)"
file_define="./rule_cache/macros_wa"
filter_define_wa="./rule_cache/macros_wa_filter"
filter_define="./rule_cache/macros_filter"

#configuration
filter_step=1000

[[ ! -r "$file_define" ]] && ./extract_macros_filter.sh "$dir" "$file_define"

#TODO: separate presets && blacklists
if [[ ! -r "$filter_define_wa" ]]
then
   cat ./filter.preset > "$filter_define_wa"
   #FIXME: explicit naming
   grep -h -e '^__[a-z][a-z_]*$' "$file_define" >> "$filter_define_wa"
   sort -u -o "$filter_define_wa" "$filter_define_wa"
   comm -23 "$filter_define_wa" <(cat ./filter.blacklist | sort -u) > "$tmp" && cp -f "$tmp" "$filter_define_wa"
fi

#TODO: separate presets && blacklists
if [[ ! -r "$filter_define" ]]
then
   cat ./filter.preset > "$filter_define"
   #FIXME: explicit naming
   grep -h -e '^__[a-z][a-z_]*$' "./rule_cache/mnames.raw" >> "$filter_define"
   sort -u -o "$filter_define" "$filter_define"
   comm -23 "$filter_define" <(cat ./filter.blacklist | sort -u) > "$tmp" && cp -f "$tmp" "$filter_define"
fi

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

