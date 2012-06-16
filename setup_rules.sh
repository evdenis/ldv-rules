#!/bin/bash -x

LDV_DIR=${LDV_DIR:-"/opt/ldv/"}

for i in $(find . -maxdepth 1 -type d -name 'rule*')
do
	sudo cp -rv "$i" "${LDV_DIR}/kernel-rules/"
done

sudo ruby - << END
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
	doc.root << doc.import(node)
}

doc.save(filename, :indent => true, :encoding => XML::Encoding::UTF_8)
END
