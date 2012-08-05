#!/bin/bash -x

kver="$1"

kfile="linux-${kver}.tar.bz2"

rules="${@:2}"

if [[ ! -r "$kfile" ]]
then
   exit 1
fi

for i in arch block fs mm security virt crypto net sound
do
   LDV_DEBUG=100 ldv-manager "envs=${kfile}" kernel_driver=1 "drivers=${i}/" "rule_models=${rules}" | tee "log-${i}.txt"
   rm -fr ./work/
done

for i in $(find ./inst/current/envs/linux-${kver}/linux-${kver}/drivers/ -maxdepth 1 -type d | cut -d '/' -f 7- | tail -n +2)
do
   LDV_DEBUG=100 ldv-manager "envs=${kfile}" kernel_driver=1 "drivers=${i}/" "rule_models=${rules}" | tee "log-${i}.txt"
   rm -fr ./work/
done

