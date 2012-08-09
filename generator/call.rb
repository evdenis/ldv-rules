#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

#ARGV[0] - linux kernel sources directory
#ARGV[1] - root function
#ARGV[2] - results store directory
#ARGV[3] - graph level

require 'rubygems'
require 'rgl/adjacency'
require 'rgl/dot'
require 'parallel'
require 'thread'

class Node
   attr_reader :id

   def initialize(name)
      @id=name
      @color="black"
#      @file_name=%x[cscope ]
#      @line_no=''
   end

   def ==(node)
      @id == node.id
   end

   def mark
      @color="white"
   end

   def unmark
      @color="black"
   end

   def check
      @color == "white"
   end

   def to_s
      @id
   end

end

graph = RGL::DirectedAdjacencyGraph.new
root = Node.new(ARGV[1])
graph.add_vertex(root)
%x[pushd #{ARGV[0]} > /dev/null; cscope -d -L -3#{root.id} | cut -d ' ' -f 2 | sort -u | grep -v -e '^panic$' -e '^BUG$' -e '^BUG_ON$'; popd > /dev/null;].split( ' ' ).each { |v|
   graph.add_edge(root, Node.new(v))
}
root.mark

vrarray = Array.new
semaphore = Mutex.new

i = 1

STDOUT.sync = true
loop do

   dotfile = File.new("#{ARGV[2]}/graph.dot#{i-1}", "w")
   graph.print_dotted_on( {}, dotfile )
   dotfile.close
   
   if i == ARGV[3].to_i + 1
      break
   end
   
   print "Step: #{i}\n"
   
   graph.each_vertex { |v|
      if not v.check
                vrarray.push(v)
      end
   }
   
   if vrarray.empty?
      break
   end
   
   j = 0
   counter = 0
   
   Parallel.map(vrarray, :in_threads => Parallel.processor_count ) { |lroot|
      lgraph = RGL::DirectedAdjacencyGraph.new
      varray = Array.new
      lgraph.add_vertex(lroot)
      %x[pushd #{ARGV[0]} > /dev/null; cscope -d -L -3#{lroot.id} | cut -d ' ' -f 2 | sort -u | grep -v -e '^panic$' -e '^BUG$' -e '^BUG_ON$'; popd > /dev/null;].split( ' ' ).each { |v|
         varray.push(Node.new(v))
      }
      semaphore.synchronize {
         varray.each { |v| graph.add_edge(lroot,v) }
         j = j + 1
         if j > vrarray.size/10*counter
            if counter == 10
               print "#{counter}\n"
            else
               print "#{counter} "
            end
            counter = counter + 1
         end
      }
      lroot.mark
   }
   
   vrarray.clear
   i = i + 1
end
STDOUT.sync = false

