#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;
use feature qw(say);

undef $/;

my $file = <>;

$file =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//([^\\]|[^\n][\n]?)*?\n|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $3 ? $3 : ""#gse;

while ( $file =~
   m/
      \#[ \t]*define
      [ \t]+
      (?<mdecl>
         (?<mname>\w+)
           \([\w\s,\.]*\)      # arguments. non-argument macros are possible
      )
   /gmx
) {
   say $+{mname};
   
   my $decl = $+{mdecl};
   
   $decl =~ s/\n/ /g;
   $decl =~ s/^[ \t]*$//g;
   $decl =~ s/^[ \t]*//g;
   $decl =~ s/\s+//g;
   say $decl;
}

