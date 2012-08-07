#!/bin/bash

# $1 - linux kernel sources directory
# $2 - pattern for filenames
# $3 - pattern for file contents
# $4 - exact extractor
# $5 - definitions file
# $6 - names file 

ldir="$( cd "$( dirname "$0" )" && pwd )"

kdir="$1"
filenames="$2"
looking_for="$3"
extractor="$4"
definitions="$5"
names="$6"

rm -f "$definitions" "$names"

declare -A lock

extracted="$(mktemp)"

declare -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
declare -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
[[ $threads_num -eq 0 ]] && threads_num=1

#init
lock_def="$(seq 1 $threads_num | xargs -I % sh -c "{ touch '${extracted}.%.'{lock,file}; echo -n '[\"${extracted}.%.lock\"]=\"${extracted}.%.file\" '; }")"
eval lock=($lock_def)

grep --include="$filenames"      \
   --exclude-dir='Documentation' \
   --exclude-dir='samples'       \
   --exclude-dir='scripts'       \
   --exclude-dir='tools'         \
   --null -F -lre "$looking_for" "$kdir" |
      xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % bash -c \
      "{                                                             \
         declare -A lock=($lock_def);                                \
         for i in \${!lock[@]};                                      \
         do                                                          \
            (                                                        \
               flock --exclusive --nonblock 9 || exit 1;             \
               \"${extractor}\" < '%' >> \${lock[\$i]};      \
               if [[ \$? -eq 0 ]]; then exit 0; else exit 2; fi;     \
            ) 9>>\$i;                                                \
            if [[ \$? -eq 0 ]]; then break; fi;                      \
         done;                                                       \
      }"

cat "${lock[@]}" | tee >(sed -ne 'p;n' >> "$names") >(sed -ne 'g;n;p' >> "$definitions") > /dev/null

#exit
rm -f "${lock[@]}" "${!lock[@]}"
unset $( sed -e 's/[^ ]\+/lock[&]/g' <<< "${!lock[@]}" )
rm -f "$extracted"

