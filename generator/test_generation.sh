#!/bin/bash -x 

git_dir="$1"

pushd "$git_dir" > /dev/null
   for i in $(git tag | grep -v 'rc\|tree' | sort -r )
   do
      git checkout -f "$i"
      popd > /dev/null
         ./generate.sh 2 "$git_dir"
      pushd "$git_dir" > /dev/null
   done
popd > /dev/null

