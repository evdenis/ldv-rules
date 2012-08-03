#!/bin/bash -x

tdir="$1"

rule="0$2"
rule_dir="rule${rule}"

test_name="test${rule}.tar.bz2"

kver="$3"

./setup_rules.sh

pushd "$rule_dir" > /dev/null
   
   if [[ "$rule" -eq "0115" ]]
   then
      if [[ -d "rule_cache-$kver" ]]
      then
         ./rselect.sh "$kver"
      else
         echo "TODO: generate."
      fi
   fi
   
   tar cjf "$test_name" ./test/
   mv "$test_name" "$tdir"
   
   pushd "$tdir" > /dev/null
      LDV_DEBUG=100 LDV_VIEW=y ldv-manager "envs=linux-3.2.23.tar.bz2" "drivers=${test_name}" "rule_models=${2}" | tee "log-${rule}.txt"
   popd > /dev/null
   
popd > /dev/null

