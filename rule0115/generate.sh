#!/bin/bash -x

lev="$1"
dir="$(readlink -e -n $2)"

rdir="$( cd "$( dirname "$0" )" && pwd )"


export PR_COEFF=1

declare -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
declare -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
[[ $threads_num -eq 0 ]] && threads_num=1


#cscope workarounds
if [[ ! ( -r "$dir/cscope.files" && -r "$dir/cscope.out" && -r "$dir/cscope.out.in" && -r "$dir/cscope.out.po" ) ]]
then
   pushd "$dir" > /dev/null
      if [[ -d .git/ ]]
      then
         git stash save | grep -q -F 'No local changes to save'
         git_save=$?
      fi
      find "$dir" -type f -name '*.[ch]' -print0 |
         xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % \
            perl -i -n -e \
               's/(__acquire|__release)s\(\s*(?!x\s*\))[\w->&.]+\s*\)//g;
                s/__printf\(\s*\d+\s*,\s*\d+\s*\)//g;
                s/__aligned\(\s*\d+\s*\)//g;
                print;' \
            '%'
      make ALLSOURCE_ARCHS=all cscope
      if [[ -d .git/ ]]
      then
         git checkout . > /dev/null
         [[ $git_save -ne 0 ]] && git stash pop > /dev/null 2>&1
      fi
   popd > /dev/null
fi

source <(head -n 4 "${dir}/Makefile" | tr -d ' ' | sed -e 's/^/KERNEL_/')
rule_cache="./rule_cache-${KERNEL_VERSION:-0}.${KERNEL_PATCHLEVEL:-0}.${KERNEL_SUBLEVEL:-0}${KERNEL_EXTRAVERSION:-}/"

mkdir -p $rule_cache

#macros_names=$(mktemp)
#macros_definitions=$(mktemp)
macros_names="${rule_cache}/mnames.raw"
macros_definitions="${rule_cache}/mdefinitions.raw"

#inline_names=$(mktemp)
#inline_definitions=$(mktemp)
inline_names="${rule_cache}/inames.raw"
inline_definitions="${rule_cache}/idefinitions.raw"

#export_names=$(mktemp)
#export_definitions=$(mktemp)
export_names="${rule_cache}/enames.raw"
export_definitions="${rule_cache}/edefinitions.raw"

err_log="${rule_cache}/err.log"
inline_blacklist="${rule_cache}/inline.blacklist.dynamic"
macros_blacklist="${rule_cache}/macros.blacklist.dynamic"
export_blacklist="${rule_cache}/export.blacklist.dynamic"

graph="${rule_cache}/graph.dot$lev"

file_define="${rule_cache}/macros_wa"
filter_define_wa="${rule_cache}/macros_wa_filter"
filter_define="${rule_cache}/macros_filter"


[[ ! ( -r "$inline_definitions" && -r "$inline_names" ) ]] && ./extract_inline.sh "$dir" "$inline_definitions" "$inline_names"
[[ ! ( -r "$macros_definitions" && -r "$macros_names" ) ]] && ./extract_macros.sh "$dir" "$macros_definitions" "$macros_names"
[[ ! ( -r "$export_definitions" && -r "$export_names" ) ]] && ./extract_export.sh "$dir" "$export_definitions" "$export_names"


[[ ! -r "$file_define" ]] && ./extract_macros_filter.sh "$dir" "$file_define"
(
   #TODO: separate presets && blacklists
   if [[ ! -r "$filter_define_wa" ]]
   then
      cat ./filter.preset > "$filter_define_wa"
      perl -n -e '/^__[a-z][a-z_]*(?<!_t)$/ && print;' "$file_define" >> "$filter_define_wa"
      sort -u -o "$filter_define_wa" "$filter_define_wa"
      tmp1="$(mktemp)"
         comm -23 "$filter_define_wa" <( sort -u < ./filter.blacklist ) > "$tmp1" && cp -f "$tmp1" "$filter_define_wa"
      rm -f "$tmp1"
      unset tmp1
   fi
) &
(
   #TODO: separate presets && blacklists
   if [[ ! -r "$filter_define" ]]
   then
      cat ./filter.preset > "$filter_define"
      perl -n -e '/^__[a-z][a-z_]*(?<!_t)$/ && print;' "$macros_names" >> "$filter_define"
      sort -u -o "$filter_define" "$filter_define"
      tmp2="$(mktemp)"
            comm -23 "$filter_define" <( sort -u < ./filter.blacklist ) > "$tmp2" && cp -f "$tmp2" "$filter_define"
      rm -f "$tmp2"
      unset tmp2
   fi
) &
wait

./filter.sh "$dir" "$filter_define_wa" "$filter_define" "$export_definitions" "${export_definitions/%.raw/.filtered}" &
./filter.sh "$dir" "$filter_define_wa" "$filter_define" "$inline_definitions" "${inline_definitions/%.raw/.filtered}" &
wait

export_definitions="${export_definitions/%.raw/.filtered}"
inline_definitions="${inline_definitions/%.raw/.filtered}"

set +x

for i in inline_definitions inline_names macros_definitions macros_names export_definitions export_names
do
   sort -u -o "${!i/%.raw/.filtered}" "${!i}" &
   eval $i="${!i/%.raw/.filtered}"
done
wait

rm -f "$inline_blacklist" "$macros_blacklist" "$export_blacklist"

set -x

#Filtering bug. Please, don't remove this check.
echo "Inline problems:" | tee "$err_log"
sed -n -e '/^[[:space:]]*static[[:space:]]\+inline[[:space:]]\+[[:alnum:]_]\+[[:space:]]*(/p' "$inline_definitions" | tee -a "$err_log" "$inline_blacklist"
echo >> "$err_log"

#Filtering bug. Please, don't remove this check.
echo "Export problems:" | tee -a "$err_log"
sed -n -e '/^[[:space:]]*\(static[[:space:]]\+\)\?\(inline[[:space:]]\+\)\?\(\(const\|enum\|struct\)[[:space:]]\+\)\?\(\*+[[:space:]]\+\)*[[:alnum:]_]\+[[:space:]]*(/p' "$export_definitions" | tee -a "$err_log" "$export_blacklist"

#Aspectator bug. typedefs problem. This check should be removed as soon as bug will be fixed.
grep -v -e '^[[:space:]]*\(\(static\|inline\|extern\|const\|enum\|struct\|union\|unsigned\|float\|double\|long\|int\|char\|short\|void\)\*\?[[:space:]]\+\)' "$export_definitions" | tee -a "$err_log" "$export_blacklist"
echo >> "$err_log"

#Aspectator bug. This check should be removed as soon as bug will be fixed.
echo "Macros problems:" | tee -a "$err_log"
sed -n -e '/^[[:space:]]*[[:alnum:]_]\+([[:space:]]*)/p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist"
#Aspectator bug. Variadic macros not supported
sed -n -e '/\.\.\./p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist"

set +x

#TODO: detect from which list to exclude. Or just use comm
while read macro
do
   sed -i -e "/^[[:space:]]*$macro[[:space:]]*$/d" "$macros_names"
done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' ./macros.blacklist.static )

#TODO: detect from which list to exclude. Or just use comm
while read func
do
   sed -i -e "/^[[:space:]]*$func[[:space:]]*$/d" "$inline_names"
   sed -i -e "/^[[:space:]]*$func[[:space:]]*$/d" "$export_names"
done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' ./functions.blacklist.static )

for i in "$inline_blacklist" "$export_blacklist" "$macros_blacklist"
do
   sort -u -o "$i" "$i" &
done
wait

tmp="$(mktemp)"
comm -23 "$inline_definitions" "$inline_blacklist" > "$tmp" && cp -f "$tmp" "$inline_definitions"
comm -23 "$export_definitions" "$export_blacklist" > "$tmp" && cp -f "$tmp" "$export_definitions"
comm -23 "$macros_definitions" "$macros_blacklist" > "$tmp" && cp -f "$tmp" "$macros_definitions"
rm -f "$tmp"
unset tmp

set -x

[[ ! -r "$graph" ]] && ./call.rb "$dir" "$rule_cache" "$lev"

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

