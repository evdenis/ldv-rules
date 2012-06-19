#!/bin/bash -x

lev="$1"
dir="$2"

# cd desire_kernel_dir

pushd "$dir" > /dev/null
	make cscope
popd > /dev/null

macros_names=$(mktemp)
macros_definitions=$(mktemp)

inline_names=$(mktemp)
inline_definitions=$(mktemp)

#export_names=$(mktemp)
#export_definitions=$(mktemp)

./extract_inline.sh "$dir" "$inline_definitions" "$inline_names"
./extract_macros.sh "$dir" "$macros_definitions" "$macros_names"

#./extract_export.sh "$dir" "$export_definitions" "$export_names"

./call.rb "$dir" "$lev"

cp -f model0115_1a-blast.aspect.in model0115_1a-blast.aspect

#while read func
#do
#done < i_export.txt
#./intersect.sh graph.dot$lev export.txt > i_export.txt

for func in $(./intersect.sh "graph.dot$lev" "$inline_names")
do
	while read i
	do
		echo -e "after: call( $(echo "$i" | tr -d '\n') )\n{\n\tldv_asssert(LDV_IN_INTERRUPT==1);\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$inline_definitions" | sort | uniq )
done

rm -f "$inline_names" "$inline_definitions"

for macros in $(./intersect.sh "graph.dot$lev" "$macros_names")
do
	while read i
	do
		#echo -e "around: define( $(echo "$i" | tr -d '\n') )\n{\n\tldv_assert(LDV_IN_INTERRUPT==1)\n}\n" >> model0115_1a-blast.aspect
		echo -e "around: define( $(echo "$i" | tr -d '\n') )\n{\n\t({ ldv_assert(LDV_IN_INTERRUPT==1); 0 })\n}\n" >> model0115_1a-blast.aspect
	done < <( grep -e "^$macros[[:space:]]*(" "$macros_definitions" | tr -d ' ' | sort | uniq )
done

rm -f "$macros_names" "$macros_definitions"

