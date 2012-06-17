#!/usr/bin/env bash

rdir="$(readlink -f $(dirname $0))"
ldir="${rdir}/scripts/lib/"

util="${ldir}/util.sh"

source "$util"  || { echo "Can't read util.sh file." 2>&1; exit 1; }

loadlibrary io out sudo

LDV_DIR=${LDV_DIR:-"/opt/ldv/"}
kr_dir="${LDV_DIR}/kernel-rules/"

check_dir kr_dir || { error "Please set up LDV_DIR variable."; exit 1; }

for i in $(find . -maxdepth 1 -type d -name 'rule*')
do
	act "Making copy of \"$i\" into kernel-rules dir" run_su cp -rv "'$i'" "'$kr_dir'" || exit 2
done

act 'Kernel-rules model-db.xml update' run_su ruby - << END
#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

require 'rubygems'
require 'xml'

filename = '${LDV_DIR}/kernel-rules/model-db.xml'

doc = XML::Parser.file(filename).parse

XML::Parser.file('./model-db.xml').parse.find('/model-db/model').each { |node|
	node.find_first('description').content = IO.readlines( 'rule' + node.find_first('rule').content + '/DESCRIPTION', 'r').to_s
	node.find('files/*').each { |file|
		file.content = './files/' + file.content
	}
	doc.find("/model-db/model[@id='" + node['id'] + "']").each { |r| r.remove! }
	doc.root << doc.import(node)
}

doc.save(filename, :indent => true, :encoding => XML::Encoding::UTF_8)
END

