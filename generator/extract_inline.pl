#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;
use feature qw(say);

undef $/;

my $file = <>;

$file =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//([^\\]|[^\n][\n]?)*?\n|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $3 ? $3 : ""#gse;

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      define
      |
      elif
      |
      ifn?(?:def)?
   )
   [ \t]+
   (?<mbody>
      .*(?=\\\n)
      \\\n
      (?&mbody)?
   )?
   .+
   $
//gmx;


while ( $file =~
   m/
      (?<fdecl>
         static
         \s+
         (:?__(:?always_)?)?inline(:?__)?
         \s+
         (?:
            \w*
               (
                  \s*
                  (?<margs>
                     \(
                     (?:
                        (?>[^\(\)]+)
                        |
                        (?&margs)
                     )*
                     \)
                  )
               )?
            |
            \**
            |
            \s*
         )+
         \s+
         \**
         (?>
            (?<fname>\w+)
            \s*
            (?<fargs>
               \(
               (?:
                  (?>[^\(\)]+)
                  |
                  (?&fargs)
               )+
               \)
            )
         )
      )
      \s*
      (?:
         (?:
            (?:__(?:acquires|releases|attribute__)\s*(?<m2args>\((?:(?>[^\(\)]+)|(?&m2args))+\)))
            |
            __attribute_const__
            |
            CONSTF
            |
            \\
         )\s*
      )*
      (
         (?:\{|\#|\/\/|\/\*)
         |
         (?:;|\()(*SKIP)(*FAIL)
      )
   /gmx
   ) {
   say $+{fname};
   
   my $decl = $+{fdecl};
   
   $decl =~ s/\n/ /g;
   $decl =~ s/^[ \t]*$//g;
   $decl =~ s/^[ \t]*//g;
   $decl =~ s/\s{2,}/ /g;
   $decl =~ s/\*\s+/*/g;
   $decl =~ s/\b\*/ */g;
   $decl =~ s/\*\s+\*/**/g;
   $decl =~ s/(\w+)\s+\(/$1(/g;
   
   $decl =~ s/\s__(:?always_)?inline(:?__)?\s/ inline /;
   $decl =~ s/(?<br>\((?:(?>[^\(\)]+)|(?&br))+\))\s*$/(..)/;
   
   say $decl;
}

