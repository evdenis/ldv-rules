#!/bin/bash -x

lev="$1"
dir="$(readlink -e -n $2)"

rdir="$( cd "$( dirname "$0" )" && pwd )"


export PR_COEFF=1


#cscope workarounds
generate_cscope ()
{
   local -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
   local -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
   [[ $threads_num -eq 0 ]] && threads_num=1
   local git_usage=no
   local extension=''
   local dir="$1"
   local -i err=0
   
   if [[ ! ( -r "$dir/cscope.files" && -r "$dir/cscope.out" && -r "$dir/cscope.out.in" && -r "$dir/cscope.out.po" ) ]]
   then
      pushd "$dir" > /dev/null      
         if [[ -d .git/ ]]
         then
            git_usage=yes
            git stash save | grep -q -F 'No local changes to save'
            git_save=$?
         else
            extension=".orig_$$"
         fi
         
         find "$dir" -type f -name '*.[ch]' -print0 |
            xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % \
               perl -i${extension} -n -e \
                  's/(__acquire|__release)s\(\s*(?!x\s*\))[\w->&.]+\s*\)//g;
                   s/__printf\(\s*\d+\s*,\s*\d+\s*\)//g;
                   s/__scanf\(\s*\d+\s*,\s*\d+\s*\)//g;
                   s/__aligned\(\s*\d+\s*\)//g;
                   print;' \
               '%'
         
         make ALLSOURCE_ARCHS=all cscope || err=1
         
         if [[ $git_usage == 'yes' ]]
         then
            git checkout . > /dev/null
            [[ $git_save -ne 0 ]] && git stash pop > /dev/null 2>&1
         else
            find "$dir" -type f -name "*${extension}" -print0 |
               xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I : \
                  bash -c 'mv ":" $(sed -e "s/^\(.*\)'"${extension}"'$/\1/" <<< ":")'
         fi
      popd > /dev/null
   fi
   return $err
}

source <(head -n 4 "${dir}/Makefile" | tr -d ' ' | sed -e 's/^/KERNEL_/')
rule_cache="./rule_cache-${KERNEL_VERSION:-0}.${KERNEL_PATCHLEVEL:-0}.${KERNEL_SUBLEVEL:-0}${KERNEL_EXTRAVERSION:-}/"

if [[ ! -d "$rule_cache" ]]
then
   rm -f "${dir}"/cscope.*
   mkdir -p "$rule_cache"
fi

generate_cscope "$dir" || exit 1

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
warn_log="${rule_cache}/warn.log"
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
touch "$inline_blacklist" "$macros_blacklist" "$export_blacklist"

set -x

echo "Inline problems:" | tee "$err_log" "$warn_log"
   #Self-detection of filtering bugs. Please, don't remove this check.
   sed -n -e '/^[[:space:]]*static[[:space:]]\+inline[[:space:]]\+[[:alnum:]_]\+[[:space:]]*(/p' "$inline_definitions" |
      tee -a "$err_log" "$inline_blacklist"
   
   #Removal of __init && __exit functions.
   sed -n -e '/[^[:alnum:]_]\(__init\|__exit\)\([^[:alnum:]_]\|$\)/p' "$inline_definitions" | tee -a "$warn_log" "$inline_blacklist"
   # IRQ handlers. Not sure about excluding them.
   sed -n -e '/\(^\|[^[:alnum:]_]\)irqreturn_t\([^[:alnum:]_]\|$\)/p' "$inline_definitions" | tee -a "$warn_log"
echo | tee -a "$err_log" "$warn_log"

echo "Export problems:" | tee -a "$err_log" "$warn_log"
   #Self-detection of filtering bugs. Please, don't remove this check.
   sed -n -e '/^[[:space:]]*\(static[[:space:]]\+\)\?\(inline[[:space:]]\+\)\?\(\(const\|enum\|struct\)[[:space:]]\+\)\?\(\*+[[:space:]]\+\)*[[:alnum:]_]\+[[:space:]]*(/p' "$export_definitions" | tee -a "$err_log" "$export_blacklist"
   
   #Removal of __init && __exit functions.
   sed -n -e '/[^[:alnum:]_]\(__init\|__exit\)\([^[:alnum:]_]\|$\)/p' "$export_definitions" | tee -a "$warn_log" "$export_blacklist"
   # IRQ handlers. Not sure about excluding them.
   sed -n -e '/\(^\|[^[:alnum:]_]\)irqreturn_t\([^[:alnum:]_]\|$\)/p' "$export_definitions" | tee -a "$warn_log"
echo | tee -a "$err_log" "$warn_log"

echo "Macros problems:" | tee -a "$err_log" "$warn_log"
   #Aspectator bug. This check should be removed as soon as bug will be fixed.
#   sed -n -e '/^[[:space:]]*[[:alnum:]_]\+([[:space:]]*)/p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist" > /dev/null
   #Aspectator bug. Variadic macros not supported
#   sed -n -e '/\.\.\./p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist" > /dev/null

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

#Transformation
#Aspectator bug. typedefs problem. This check should be removed as soon as bug will be fixed.
perl -i -n -e '/^\s*((static|inline|extern|const|enum|struct|union|unsigned|float|double|long|int|char|short|void)\*?\s+)/ || s/^\s*/^/; print;' "$export_definitions"

set -x

[[ ! -r "$graph" ]] && ./call.rb "$dir" "$rule_cache" "$lev"

declare -A model
model_def="$(find "$rdir" -maxdepth 1 -type f -name 'model*\.aspect\.in' |
             xargs -I % sh -c "{ echo -n '[\"%\"]=\"${rule_cache}/model\$(basename '%' | sed -e 's/model\([[:digit:]]\{4\}\)\.aspect\.in/\1/').aspect\" '; }")"
eval model=($model_def)

for i in ${!model[@]}
do
   cp -f "$i" "${model[$i]}"
done

set +x

intersect ()
{
   local graph="$1"
   local names="$2"
   
   comm -12 <(grep -e label "$graph" | cut -d '=' -f 2 | cut -b 2- | sort -u) <(sort -u "$names")
}

aspects="$(mktemp)"

#Don't try to implement this codeblock(x3) as functions. It will not work
#because of the bash bug.
(
   echo -n "before:" >> "${aspects}.1"
   for func in $(intersect "$graph" "$export_names")
   do
      while read i
      do
         echo -e "\t|| call( $(echo -n "$i") )" >> "${aspects}.1"
      done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$export_definitions" )
   done
   perl -i -e 'undef $/; my $file=<>; $file =~ s/\t\|\|(?=\s*call\s*\()//m; print $file;' "${aspects}.1"
   echo -e "{\n\tldv_check();\n}\n" >> "${aspects}.1"
)&

(
   echo -n "before:" >> "${aspects}.2"
   for func in $(intersect "$graph" "$inline_names")
   do
      while read i
      do
         echo -e "\t|| execution( $(echo -n "$i") )" >> "${aspects}.2"
      done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$inline_definitions" )
   done
   perl -i -e 'undef $/; my $file=<>; $file =~ s/\t\|\|(?=\s*execution\s*\()//m; print $file;' "${aspects}.2"
   echo -e "{\n\tldv_check();\n}\n" >> "${aspects}.2"
)&

#Latter generation scheme doesn't work for macros.
(
   for macros in $(intersect "$graph" "$macros_names")
   do
      while read i
      do
         echo -e "around: define( $(echo -n "$i") )\n{\n\t({ ldv_check(); 0; })\n}\n" >> "${aspects}.3"
      done < <( grep -e "^$macros[[:space:]]*(" "$macros_definitions" )
   done
)&

wait

cat "${aspects}."{1,2,3} | tee -a "${model[@]}" > /dev/null

for i in "${!model[@]}"
do
   ln -s -f "${model[$i]}" "$(basename "${i%.in}")"
done

rm -f "$export_names" "$export_definitions" \
      "$inline_names" "$inline_definitions" \
      "$macros_names" "$macros_definitions" \
      "${aspects}."{1,2,3}

