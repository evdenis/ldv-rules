#!/bin/bash

# $1 - linux kernel sources directory
# $2 - macros definitions file
# $3 - macros names file

ldir="$( cd "$( dirname "$0" )" && pwd )"

rm -f "$2" "$3"

declare -A lock

extracted="$(mktemp)"

declare -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
declare -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
[[ $threads_num -eq 0 ]] && threads_num=1

#init
lock_def="$(seq 1 $threads_num | xargs -I % sh -c "{ touch '${extracted}.%.'{lock,file}; echo -n '[\"${extracted}.%.lock\"]=\"${extracted}.%.file\" '; }")"
eval lock=($lock_def)


grep --include="*.h"             \
   --exclude-dir='Documentation' \
   --exclude-dir='samples'       \
   --exclude-dir='scripts'       \
   --exclude-dir='tools'         \
   --null -F -lre 'define' "$1" |
      xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % bash -c \
      "{                                                             \
         declare -A lock=($lock_def);                                \
         for i in \${!lock[@]};                                      \
         do                                                          \
            (                                                        \
               flock --exclusive --nonblock 9 || exit 1;             \
               \"${ldir}/extract_macros.pl\" < '%' >> \${lock[\$i]}; \
               if [[ \$? -eq 0 ]]; then exit 0; else exit 2; fi;     \
            ) 9>>\$i;                                                \
            if [[ \$? -eq 0 ]]; then break; fi;                      \
         done;                                                       \
      }"

cat "${lock[@]}" | tee >(sed -ne 'p;n' >> "$3") >(sed -ne 'g;n;p' >> "$2") > /dev/null

#exit
rm -f "${lock[@]}" "${!lock[@]}"
unset $( sed -e 's/[^ ]\+/lock[&]/g' <<< "${!lock[@]}" )
rm -f "$extracted"

sed -i -e 's/[[:space:]]\+//g' "$2"

