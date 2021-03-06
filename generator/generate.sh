#!/bin/bash -x

# Level of callgraph
[[ ! "$1" =~ ^[0-9]+$ ]] && exit 1
lev="$1"
# Kernel directory
kdir="$(readlink -m -q -n "$2")"
[[ ! -r "${kdir}/Kbuild" ]] && exit 1
# Optional. Possible values: full, shorten. Default - shorten.
# Meaning: full - all aspects; shorten - aspects only for export functions.
generation="${3:-shorten}"
[[ ( "$generation" != 'full' ) && ( "$generation" != 'shorten' ) ]] && exit 1

ldir="$( cd "$( dirname "$0" )" && pwd )"
rdir="$( cd "$( readlink -e -n "$0" | xargs dirname )" && pwd )"

if [[ "$ldir" == "$rdir" ]]
then
   exit 2
fi

root_function="$(basename "$0" | sed -e 's/generate-//')"
[[ "$root_function" == 'all' ]] && generation='full'

export PR_COEFF=1

lock="${rdir}/generate.lock"

exec 8>"$lock"
flock -x 8

#cscope workarounds
generate_cscope ()
{
   local -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
   local -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
   [[ $threads_num -eq 0 ]] && threads_num=1
   local git_usage=no
   local extension=''
   local dir="$1"
   local remove=''
   local -i err=0
   
   all_sources ()
   {
      set +x
      local ignore="( -name SCCS -o -name BitKeeper -o -name .svn -o \
                      -name CVS  -o -name .pc       -o -name .hg  -o \
                      -name .git -o -name .tmp_versions )            \
                      -prune -o"
      
      # Don't know whether order matters or not.
      local x86_includes="$(find ./arch/x86/ -type d -name 'include')"
      find $x86_includes $ignore -type f -name '*.[ch]' -print
      find ./include/ $ignore -path ./include/generated -prune -o -type f -name '*.[ch]' -print
      
      # Every other arch include
      local other_includes="$(find ./arch/ -path ./arch/x86 -prune -o -type d -name 'include' -print | sort)"
      find $other_includes $ignore -type f -name '*.[ch]' -print
      
      # Other sources
      local filter='( '
      for i in $x86_includes $other_includes
      do
         filter="$filter -path $i -o"
      done
      filter="$(echo "$filter" | head -c -3) ) -prune -o"
      local dirs="$(find . -maxdepth 1 \( -path ./Documentation -o -path ./firmware -o -path ./samples -o -path ./scripts  \
                    -o -path ./tools -o -path ./include -o -path ./.git -o -path ./.tmp_versions \) -prune -o -type d -print | grep -v -e '^\.$')"
      find $dirs $filter $ignore -type f -name '*.[ch]' -print
      set -x
   }
   
   if [[ ! ( -r "${dir}/cscope.files" && -r "${dir}/cscope.out" && -r "${dir}/cscope.out.in" && -r "${dir}/cscope.out.po" ) ]]
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
         
         grep --include='*.[ch]' --null -lre '__\(\(acquire\|release\)s\|printf\|scanf\|aligned\|attribute__\)\|defined' "$dir" |
            xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % \
               perl -i${extension} -n -e \
                  's/(__acquire|__release)s\(\s*(?!x\s*\))[\w->&.]+\s*\)//g;
                   s/__printf\(\s*\d+\s*,\s*\d+\s*\)//g;
                   s/__scanf\(\s*\d+\s*,\s*\d+\s*\)//g;
                   s/__aligned\(\s*\d+\s*\)//g;
                   s/defined\s*\([^)]+\)/defined/g;
                   s/__attribute__[ \t]*\((?<b>\((?:[^\(\)]|(?&b))*\))\)[ \t]*//g;
                   print;' \
               '%'
         
         (echo \-k; echo \-q; all_sources) > cscope.files
         cscope -b -f cscope.out || err=1
         
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

source <(head -n 4 "${kdir}/Makefile" | tr -d ' ' | sed -e 's/^/KERNEL_/')
rule_cache="${rdir}/rule_cache-${KERNEL_VERSION:-0}.${KERNEL_PATCHLEVEL:-0}.${KERNEL_SUBLEVEL:-0}${KERNEL_EXTRAVERSION:-}/"
lrule_cache="./rule_cache-${KERNEL_VERSION:-0}.${KERNEL_PATCHLEVEL:-0}.${KERNEL_SUBLEVEL:-0}${KERNEL_EXTRAVERSION:-}/"

if [[ ! -d "$rule_cache" ]]
then
   rm -f "${kdir}"/cscope.*
   mkdir -p "$rule_cache"
fi

generate_cscope "$kdir" || exit 3

mkdir -p "$lrule_cache"

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

timestamp="$(date +%Y%m%d-%H%M%S)"
err_log="${rule_cache}/err-${timestamp}.log"
selferr_log="${rule_cache}/selferr-${timestamp}.log"
exclusion_log="${lrule_cache}/exclusion-${timestamp}.log"
inline_blacklist="${rule_cache}/inline.blacklist.dynamic.$$"
macros_blacklist="${rule_cache}/macros.blacklist.dynamic.$$"
export_blacklist="${rule_cache}/export.blacklist.dynamic.$$"

if [[ "$root_function" != 'all' ]]
then
   mkdir -p "${rule_cache}/${root_function}/"
   graph="${rule_cache}/${root_function}/graph.dot${lev}"
else
   graph=''
fi

file_define="${rule_cache}/macros_wa"
filter_define_wa="${rule_cache}/macros_wa_filter.$$"
filter_define="${rule_cache}/macros_filter.$$"


[[ ! ( -r "$inline_definitions" && -r "$inline_names" ) ]] && "${rdir}/extract.sh" "$kdir" '*.h' 'inline' "${rdir}/extract_inline.pl" "$inline_definitions" "$inline_names"
[[ ! ( -r "$macros_definitions" && -r "$macros_names" ) ]] && "${rdir}/extract.sh" "$kdir" '*.h' 'define' "${rdir}/extract_macros.pl" "$macros_definitions" "$macros_names"
[[ ! ( -r "$export_definitions" && -r "$export_names" ) ]] && "${rdir}/extract.sh" "$kdir" '*.[ch]' 'EXPORT_SYMBOL' "${rdir}/extract_export.pl" "$export_definitions" "$export_names"


[[ ! -r "$file_define" ]] && "${rdir}/extract_macros_filter.sh" "$kdir" "$file_define"
(
   #TODO: separate presets && blacklists
   cat "${rdir}/filter.preset" > "$filter_define_wa"
   perl -n -e '/^__[a-z][a-z_]*(?<!_t)$/ && print;' "$file_define" >> "$filter_define_wa"
   sort -u -o "$filter_define_wa" "$filter_define_wa"
   
   local_blacklist=''
   [[ -r "${ldir}/filter.blacklist" ]] && local_blacklist="${ldir}/filter.blacklist"
   tmp1="$(mktemp)"
      comm -23 "$filter_define_wa" <( sort -u <( cat "${rdir}/filter.blacklist" $local_blacklist ) ) > "$tmp1" && cp -f "$tmp1" "$filter_define_wa"
   rm -f "$tmp1"
   unset tmp1
) &
(
   #TODO: separate presets && blacklists
   cat "${rdir}/filter.preset" > "$filter_define"
   perl -n -e '/^__[a-z][a-z_]*(?<!_t)$/ && print;' "$macros_names" >> "$filter_define"
   sort -u -o "$filter_define" "$filter_define"
   
   local_blacklist=''
   [[ -r "${ldir}/filter.blacklist" ]] && local_blacklist="${ldir}/filter.blacklist"
   tmp2="$(mktemp)"
      comm -23 "$filter_define" <( sort -u <( cat "${rdir}/filter.blacklist" $local_blacklist ) ) > "$tmp2" && cp -f "$tmp2" "$filter_define"
   rm -f "$tmp2"
   unset tmp2
) &
wait

"${rdir}/filter.sh" "$kdir" "$filter_define_wa" "$filter_define" "$export_definitions" "${export_definitions/%.raw/.filtered}" &
"${rdir}/filter.sh" "$kdir" "$filter_define_wa" "$filter_define" "$inline_definitions" "${inline_definitions/%.raw/.filtered}" &
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

touch "$inline_blacklist" "$macros_blacklist" "$export_blacklist"

[[ -r "${ldir}/filter.sh" ]] && source "${ldir}/filter.sh"


apply_filter ()
{
   local filter="$1"
   local names="$2"
   local definitions="$3"
   local -i state=0
   
   local tmp=$(type -t $filter)
   
   if echo $tmp | grep -q -e '^function$' || alias | grep -q -F -e "alias ${filter}="
   then
      [[ ( ! -r "$names" ) || ( ! -r "$definitions" ) ]] && return 1
      cp -f "$names" "${names}.orig"
      cp -f "$definitions" "${definitions}.orig"
      
      if alias | grep -q -F -e "alias ${filter}="
      then
         filter=$(alias | grep -e $filter | cut -d '=' -f 2 | sed -e "s/^'//" -e "s/'$//")
      fi
      
      $filter "$names" "$definitions"
      
      diff -q "${names}.orig" "$names" > /dev/null
      local -i names_diff=$?
      if [[ $names_diff -ne 0 ]]
      then
         echo -e " Names diff:\n$( diff "${names}.orig" "$names" | grep -e '^< ' | sed -e 's/^< /  /' )" >> "$exclusion_log"
         [[ -n "$(diff "${names}.orig" "$names" | grep -e '^> ')" ]] && return 2
      fi
      
      diff -q "${definitions}.orig" "$definitions" > /dev/null
      local -i defs_diff=$?
      if [[ "$defs_diff" -ne 0 ]]
      then
         echo -e " Definitions diff:\n$( diff "${definitions}.orig" "$definitions" | grep -e '^< ' | sed -e 's/^< /  /' )" >> "$exclusion_log"
         [[ -n "$(diff "${definitions}.orig" "$definitions" | grep -e '^> ')" ]] && return 2
      fi
      
      rm -f "${names}.orig" "${definitions}.orig"
   fi
   
   return 0
}

echo "Inline problems:" | tee "$err_log" "$selferr_log" "$exclusion_log"
   #Self-detection of filtering bugs. Please, don't remove this check.
   sed -n -e '/^[[:space:]]*static[[:space:]]\+inline[[:space:]]\+[[:alnum:]_]\+[[:space:]]*(/p' "$inline_definitions" |
      tee -a "$selferr_log" "$inline_blacklist"
   
   apply_filter inline_filter "$inline_names" "$inline_definitions" || exit 3
   
echo | tee -a "$err_log" "$selferr_log" "$exclusion_log"

echo "Export problems:" | tee -a "$err_log" "$selferr_log" "$exclusion_log"
   #Self-detection of filtering bugs. Please, don't remove this check.
   sed -n -e '/^[[:space:]]*\(static[[:space:]]\+\)\?\(inline[[:space:]]\+\)\?\(\(const\|enum\|struct\)[[:space:]]\+\)\?\(\*+[[:space:]]\+\)*[[:alnum:]_]\+[[:space:]]*(/p' "$export_definitions" | tee -a "$selferr_log" "$export_blacklist"
   
   apply_filter export_filter "$export_names" "$export_definitions" || exit 3
   
echo | tee -a "$err_log" "$selferr_log" "$exclusion_log"

echo "Macros problems:" | tee -a "$err_log" "$selferr_log" "$exclusion_log"
   #Aspectator bug. This check should be removed as soon as bug will be fixed.
   # sed -n -e '/^[[:space:]]*[[:alnum:]_]\+([[:space:]]*)/p' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist" > /dev/null
   #Aspectator bug. Variadic macros not supported
   perl -n -e '/\((\s*\w+\s*,)+\w+\.{3}\)/ && print' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist" > /dev/null
   #Aspectator bug. Macro parameter with name 'register'
   perl -n -e '/\((\s*\w+\s*,)*?\s*register\s*(,\s*\w+\s*)*\)/ && print' "$macros_definitions" | tee -a "$err_log" "$macros_blacklist" > /dev/null
   
   apply_filter macros_filter "$macros_names" "$macros_definitions" || exit 3


global_static_functions_blacklist='' 
global_static_macros_blacklist=''

if [[ "$root_function" != 'all' ]]
then
   global_static_functions_blacklist="${rdir}/functions.blacklist.static" 
   global_static_macros_blacklist="${rdir}/macros.blacklist.static" 
fi

local_static_functions_blacklist=''
local_static_macros_blacklist=''

[[ -r "${ldir}/functions.blacklist.static" ]] && local_static_functions_blacklist="${ldir}/functions.blacklist.static"
[[ -r "${ldir}/macros.blacklist.static" ]] && local_static_macros_blacklist="${ldir}/macros.blacklist.static"

if [[ -n "$global_static_macros_blacklist" || -n "$local_static_macros_blacklist" ]]
then
   #TODO: Selective filtering from definitions file.
   while read macro
   do
      sed -i -e "/^[[:space:]]*$macro[[:space:]]*$/d" "$macros_names"
   done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' $global_static_macros_blacklist $local_static_macros_blacklist )
fi

if [[ -n "$global_static_functions_blacklist" || -n "$local_static_functions_blacklist" ]]
then
   #TODO: Selective filtering from definitions file.
   while read func
   do
      sed -i -e "/^[[:space:]]*$func[[:space:]]*$/d" "$inline_names"
      sed -i -e "/^[[:space:]]*$func[[:space:]]*$/d" "$export_names"
   done < <( sed -e 's/\#.*$//g' -e '/^[[:space:]]*$/d' $global_static_functions_blacklist $local_static_functions_blacklist )
fi


if [[ "$root_function" != 'all' ]]
then
   
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
fi

#Transformation
#Aspectator bug. typedefs problem. This check should be removed as soon as bug will be fixed.
perl -i -n -e '/^\s*((static|inline|extern|const|enum|struct|union|unsigned|float|double|long|int|char|short|void)\*?\s+)/ || s/^\s*/^/; print;' "$export_definitions"

set -x

if [[ "$root_function" != 'all' ]]
then
   [[ ! -r "$graph" ]] && "${rdir}/call.rb" "$kdir" "$root_function" "${rule_cache}/${root_function}/" "$lev"
   [[ ! -r "$graph" ]] && exit 3
fi

declare -A model
model_def="$(find "$ldir" -maxdepth 1 -type f -name 'model*\.aspect\.in' |
             xargs -I % sh -c "{ echo -n \"[\"%\"]=\"${lrule_cache}/model\$(basename '%' | perl -n -e '/model(.+?)\.aspect\.in/ && print \$1;').aspect\" \"; }")"
eval model=($model_def)

if [[ ${#model[@]} -eq 0 ]]
then
   exit 4
fi

for i in ${!model[@]}
do
   cp -f "$i" "${model[$i]}"
done

set +x

intersect ()
{
   local graph="$1"
   local names="$2"
   
   if [[ "$root_function" == 'all' ]]
   then
      sort -u "$names"
   else
      comm -12 <(grep -e label "$graph" | cut -d '=' -f 2 | cut -b 2- | sort -u) <(sort -u "$names")
   fi
}

aspects="$(mktemp)"

#Don't try to implement this codeblock(x3) as functions. It will not work
#because of the bash bug.
(
   func_list=$(intersect "$graph" "$export_names")
   if [[ $(echo $func_list | wc -w) -ne 0 ]]
   then
      echo -n "before:" >> "${aspects}.1"
      for func in $func_list
      do
         while read i
         do
            echo -e "\t|| call( $(echo -n "$i") )" >> "${aspects}.1"
         done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$export_definitions" )
      done
      perl -i -e 'undef $/; my $file=<>; $file =~ s/\t\|\|(?=\s*call\s*\()//m; print $file;' "${aspects}.1"
      echo -e "{\n   /* LDV_COMMENT_MODEL_FUNCTION_CALL Call core model function.*/\n   ldv_check();\n}\n" >> "${aspects}.1"
   fi
)&

if [[ "$generation" == 'full' ]]
then
   (
      func_list=$(intersect "$graph" "$inline_names")
      if [[ $(echo $func_list | wc -w) -ne 0 ]]
      then
         echo -n "before:" >> "${aspects}.2"
         for func in $func_list
         do
            while read i
            do
               echo -e "\t|| execution( $(echo -n "$i") )" >> "${aspects}.2"
            done < <( grep -e "[^[:alnum:]_]$func[[:space:]]*(" "$inline_definitions" )
         done
         perl -i -e 'undef $/; my $file=<>; $file =~ s/\t\|\|(?=\s*execution\s*\()//m; print $file;' "${aspects}.2"
         echo -e "{\n   /* LDV_COMMENT_MODEL_FUNCTION_CALL Call core model function.*/\n   ldv_check();\n}\n" >> "${aspects}.2"
      fi
   )&

   #Latter generation scheme doesn't work for macros.
   (
      for macros in $(intersect "$graph" "$macros_names")
      do
         while read i
         do
            echo -e "around: define( $(echo -n "$i") )\n{\n   ({\n      /* LDV_COMMENT_MODEL_FUNCTION_CALL Call core model function.*/\n      ldv_check(); 0;\n   })\n}\n" >> "${aspects}.3"
         done < <( grep -e "^$macros[[:space:]]*(" "$macros_definitions" )
      done
   )&

fi

wait

if [[ -r "${aspects}.1" ]]
then
   cat "${aspects}."[123] | tee -a "${model[@]}" > /dev/null
fi

for i in "${!model[@]}"
do
   ln -s -f "${model[$i]}" "$(basename "${i%.in}")"
done


rm -f "$export_names" "$export_definitions" \
      "$inline_names" "$inline_definitions" \
      "$macros_names" "$macros_definitions" \
      "$inline_blacklist" "$macros_blacklist" "$export_blacklist" \
      "$filter_define" "$filter_define_wa"  \
      "${aspects}."{1,2,3}

exec 8>&-

