#!/bin/bash -x

for i in block fs mm security virt crypto net sound
do
   LDV_DEBUG=100 ldv-manager "envs=linux-3.2.22.tar.bz2" kernel_driver=1 "drivers=$i/" "rule_models=113_1a" | tee log-$i.txt
   rm -fr ./work/
done

for i in  $(find /home/work/workspace/linux-stable/drivers/ -maxdepth 1 -type d | cut -d '/' -f 6- | tail -n +2 | less)
do
   LDV_DEBUG=100 ldv-manager "envs=linux-3.2.22.tar.bz2" kernel_driver=1 "drivers=$i/" "rule_models=113_1a" | tee log-$i.txt
   rm -fr ./work/
done


