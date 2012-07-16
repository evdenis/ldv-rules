#!/bin/bash

#declare -A desc

#LDV_TASK_DESCRIPTION=
#LDV_TASK_ID=

upload ()
{
   local file="$1"
   local upload=no
   
   if [[ -r "$file" ]]
   then
      if expr match "$file" '*.pax'
      then
         if grep -q -F -e 'UNSAFE' "$file"
         then
            upload=yes
         elif grep -q -F -e 'SAFE' "$file"
         then
            upload=no
         fi
         ldv-upload "$file" > /dev/null
      else
         return 2
      fi
   else
      echo "Error: $file is not readable."
      return 1
   fi
   return 0
}


inotifywait --quiet --recursive --monitor -e modify -e create --format '%w/%f' . | xargs --max-lines=1 --max-procs=1 --no-run-if-empty upload

