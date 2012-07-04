#!/bin/bash -x

lev="$1"
dir="$2"

# cd desire_kernel_dir

pushd "$dir" > /dev/null
	make cscope
popd > /dev/null

mkdir -p rule_cache

#macros_names=$(mktemp)
#macros_definitions=$(mktemp)
macros_names=./rule_cache/mnames.raw
macros_definitions=./rule_cache/mdefinitions.raw

#inline_names=$(mktemp)
#inline_definitions=$(mktemp)
inline_names=./rule_cache/inames.raw
inline_definitions=./rule_cache/idefinitions.raw

#export_names=$(mktemp)
#export_definitions=$(mktemp)
export_names=./rule_cache/enames.raw
export_definitions=./rule_cache/edefinitions.raw

err_log=./rule_cache/err.log
inline_blacklist=./rule_cache/inline.blacklist.dynamic
macros_blacklist=./rule_cache/macros.blacklist.dynamic
export_blacklist=./rule_cache/export.blacklist.dynamic

graph="./rule_cache/graph.dot$lev"

[[ ! ( -r "$inline_definitions" && -r "$inline_names" ) ]] && ./extract_inline.sh "$dir" "$inline_definitions" "$inline_names"
[[ ! ( -r "$macros_definitions" && -r "$macros_names" ) ]] && ./extract_macros.sh "$dir" "$macros_definitions" "$macros_names"
[[ ! ( -r "$export_definitions" && -r "$export_names" ) ]] && ./extract_export.sh "$dir" "$export_definitions" "$export_names"

./filter.sh "$dir" "$export_definitions" "${export_definitions/%.raw/.filtered}"
./filter.sh "$dir" "$inline_definitions" "${inline_definitions/%.raw/.filtered}"

export_definitions="${export_definitions/%.raw/.filtered}"
inline_definitions="${inline_definitions/%.raw/.filtered}"

for i in inline_definitions inline_names macros_definitions macros_names export_definitions export_names
do
   sort -bi -u -o "${!i/%.raw/.filtered}" "${!i}"
   eval $i="${!i/%.raw/.filtered}"
done

rm -f "$inline_blacklist" "$macros_blacklist" "$export_blacklist"

#Filtering bug. Please, don't remove this check.
echo "Inline problems:" | tee "$err_log"
sed -n -e '/^[[:space:]]*static[[:space:]]\+inline[[:space:]]\+[[:alnum:]_]\+[[:space:]]*(/p' "$inline_definitions" | tee -a "$err_log" "$inline_blacklist"

#Filtering bug. Please, don't remove this check.
echo "Export problems:" | tee -a "$err_log"
sed -n -e '/^[[:space:]]*\(static[[:space:]]\+\)\?\(inline[[:space:]]\+\)\?\(\(const\|enum\|struct\)[[:space:]]\+\)\?\(\*+[[:space:]]\+\)*[[:alnum:]_]\+[[:space:]]*(/p' "$export_definitions" | tee -a "$err_log" "$export_blacklist"

#Aspectator bug. typedefs
grep -v -e '^[[:space:]]*\(\(static\|inline\|extern\|const\|enum\|struct\|union\|unsigned\|float\|double\|long\|int\|char\|short\|void\)\*\?[[:space:]]\+\)' "$export_definitions" | tee -a "$err_log" "$export_blacklist"
#Aspectator bug. This check should be removed as soon as bug will be fixed.
echo "Macros problems:" | tee -a "$err_log"
sed -n -e '/^[[:space:]]*[[:alnum:]_]\+([[:space:]]*)/p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist"

set +x

#TODO: detect from which list to exclude. Or just use comm
while read macro
do
   sed -i -e "/$macro/d" "$macros_names"
done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' ./macros.blacklist.static )

#TODO: detect from which list to exclude. Or just use comm
while read func
do
   sed -i -e "/$func/d" "$inline_names"
   sed -i -e "/$func/d" "$export_names"
done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' ./functions.blacklist.static )

tmp="$(mktemp)"
comm -23 "$inline_definitions" "$inline_blacklist" > "$tmp"; cp -f "$tmp" "$inline_definitions"
comm -23 "$export_definitions" "$export_blacklist" > "$tmp"; cp -f "$tmp" "$export_definitions"
comm -23 "$macros_definitions" "$macros_blacklist" > "$tmp"; cp -f "$tmp" "$macros_definitions"
rm -f "$tmp"
unset tmp

set -x

[[ ! -r "$graph" ]] && ./call.rb "$dir" "./rule_cache/" "$lev"

cp -f model0115_1a-blast.aspect.in model0115_1a-blast.aspect

set +x

for func in $(./intersect.sh "$graph" "$export_names")
do
	while read i
	do
		echo -e "after: call( $(echo "$i" | tr -d '\n') )\n{\n\tcheck_in_interrupt();\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$export_definitions" )
done

rm -f "$export_names" "$export_definitions"

for func in $(./intersect.sh "$graph" "$inline_names")
do
	while read i
	do
		echo -e "after: call( $(echo "$i" | tr -d '\n') )\n{\n\tcheck_in_interrupt();\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$inline_definitions" )
done

rm -f "$inline_names" "$inline_definitions"

for macros in $(./intersect.sh "$graph" "$macros_names")
do
	while read i
	do
		echo -e "around: define( $(echo "$i" | tr -d '\n') )\n{\n\t({ check_in_interrupt(); 0; })\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "^$macros[[:space:]]*(" "$macros_definitions" )
done

rm -f "$macros_names" "$macros_definitions"

