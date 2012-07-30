#!/bin/bash -x

ver="$1"
rdir="$( cd "$( dirname "$0" )" && pwd )"

rule_cache="./rule_cache-$ver"

if [[ -d "$rule_cache" ]]
then
   model0115="${rule_cache}/model0115.aspect"
   model0122="${rule_cache}/model0122.aspect"
   model0123="${rule_cache}/model0123.aspect"
   model0124="${rule_cache}/model0124.aspect"
   
   for i in "$model0115" "$model0122" "$model0123" "$model0124"
   do
      ln -s -f "$i" "$(basename "$i")"
   done
fi

