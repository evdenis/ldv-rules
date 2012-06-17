#!/bin/bash -x

lev=1

# cd desire_kernel_dir

make cscope
./gen_inline.sh > inline.txt
./gen_define.sh > define.txt
./gen_export.sh > export.txt

./call.rb

./intersect.sh graph.dot$lev inline.txt > i_inline.txt
./intersect.sh graph.dot$lev define.txt > i_define.txt
./intersect.sh graph.dot$lev export.txt > i_export.txt

cp -f model0115_1a-blast.aspect.in model0115_1a-blast.aspect

for i in i_inline.txt i_export.txt
do
	echo -e "after: call( (..) )\n{\n\tldv_asssert(LDV_IN_INTERRUPR==1);\n}\n" >> model0115_1a-blast.aspect
done

for i in i_define.txt
do
	echo -e "around: define(  )\n{\n\tldv_assert(LDV_IN_INTERRUPT==1);\n}\n" >> model0115_1a-blast.aspect
done

