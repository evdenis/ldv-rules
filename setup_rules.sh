#!/bin/bash -x

for i in $(find . -maxdepth 1 -type d -name 'rule*')
do
	sudo cp -v "$i" "${LDVDIR}/kernel-rules/"
done

sudo ruby - << END
require 'rubygems'
require 'xml'

doc = XML::Parser.file("${LDVDIR}/kernel-rules/model_db.xml").parse

XML::Parser.file(./model_db.xml).parse.find('/model').each { |node|
	print node
	doc.model_db << node
	node['description'] = IO.readlines(node['rule']/DESCRIPTION,'r').to_s
	node['files'].each { |file|
		file = "./files" + file
	}
}
doc.save(filename, :indent => true, :encoding => XML::Encoding::UTF_8)
END
