#!/bin/bash -x

lev="$1"
dir="$2"

# cd desire_kernel_dir

pushd "$dir" > /dev/null
	make cscope
popd > /dev/null

mkdir rule_cache

#macros_names=$(mktemp)
#macros_definitions=$(mktemp)
macros_names=./rule_cache/mnames
macros_definitions=./rule_cache/mdefinitions

#inline_names=$(mktemp)
#inline_definitions=$(mktemp)
inline_names=./rule_cache/inames
inline_definitions=./rule_cache/idefinitions

#export_names=$(mktemp)
#export_definitions=$(mktemp)
export_names=./rule_cache/enames
export_definitions=./rule_cache/edefinitions

graph="./rule_cache/graph.dot$lev"

[[ ! ( -r "$inline_definitions" && -r "$inline_names" ) ]] && ./extract_inline.sh "$dir" "$inline_definitions" "$inline_names"
[[ ! ( -r "$macros_definitions" && -r "$macros_names" ) ]] && ./extract_macros.sh "$dir" "$macros_definitions" "$macros_names"
[[ ! ( -r "$export_definitions" && -r "$export_names" ) ]] && ./extract_export.sh "$dir" "$export_definitions" "$export_names"

./filter.sh "$dir" "$export_definitions"
./filter.sh "$dir" "$inline_definitions"

[[ ! -r "$graph" ]] && ./call.rb "$dir" "./rule_cache/" "$lev"

cp -f model0115_1a-blast.aspect.in model0115_1a-blast.aspect

for func in $(./intersect.sh "$graph" "$export_names")
do
	while read i
	do
		echo -e "after: call( $(echo "$i" | tr -d '\n') )\n{\n\tcheck_in_interrupt();\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$export_definitions" | sort | uniq )
done

#rm -f "$export_names" "$export_definitions"

for func in $(./intersect.sh "$graph" "$inline_names")
do
	while read i
	do
		echo -e "after: call( $(echo "$i" | tr -d '\n') )\n{\n\tcheck_in_interrupt();\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$inline_definitions" | sort | uniq )
done

#rm -f "$inline_names" "$inline_definitions"

for macros in $(./intersect.sh "$graph" "$macros_names")
do
	while read i
	do
		echo -e "around: define( $(echo "$i" | tr -d '\n') )\n{\n\t({ check_in_interrupt(); 0 })\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "^$macros[[:space:]]*(" "$macros_definitions" | tr -d ' ' | sort | uniq )
done

#rm -f "$macros_names" "$macros_definitions"

