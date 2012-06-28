#!/bin/bash

# $1 - linux kernel sources
# $2 - file to filter

dir="$1"
file="$2"

tmp="$(mktemp)"
#filter="$(mktemp)"
fdefine="./rule_cache/mfilter"

#configuration
filter_step=1000

[[ ! -r "$fdefine" ]] && ./extract_macros_filter.sh "$dir" "$fdefine"

cat "$fdefine" | sort | uniq > "$tmp"
cp -f "$tmp" "$fdefine"

#attribute filter
perl -n -e 's/__attribute__[ \t]*\((?<b>\((?:[^\(\)]|(?&b))*\))\)[ \t]*//g; print' "$file" > "$tmp"


#macros filter construction
filter=''
for (( i=1; i<$(cat "$fdefine" | wc -l); i+=$filter_step ))
do
   filter=$(tail -n +${i} "$fdefine" | head -n $filter_step | sed -e 's/^/\\([^[:alnum:]_]\\|^\\)/' -e 's/$/[^[:alnum:]_]/' | tr '\n' '|' | sed -e 's/|/\\|/g' | sed -e 's/\\|$//')
	if [[ -n "$filter" ]]
	then
		sed -i -e "s/$filter//g" "$tmp"
	fi
done

cp -f "$tmp" "$file"
rm -f "$tmp"

