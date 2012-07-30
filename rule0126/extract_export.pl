#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use 5.10.0;
use feature qw(say);

undef $/;

my $file = <>;

$file =~ s#/\*[^*]*\*+([^/*][^*]*\*+)*/|//([^\\]|[^\n][\n]?)*?\n|("(\\.|[^"\\])*"|'(\\.|[^'\\])*'|.[^/"'\\]*)#defined $3 ? $3 : ""#gse;

#define
#elseif
#ifdef
#ifndef
#if
#
#line
#endif
#else
#include
#undef
#
#^[ \t]*sdfasdfsad()[ \t]*$
#
#error
#warning

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:error|warning)
   [ \t]*
   \"
      (
         [^"\\\n]
         |
         \\"
         |
         \\\n
      )*
   \"
   [ \t]*$
//gmx;

$file =~ s/
   ^
   [ \t]*
   (?!if|for|return|while)
   \w+
   [ \t]*
   (?<margs>
      \(
         (?:
            [^\(\)\n\{\;\}]
            |
            (?&margs)
         )+
      \)
      [ \t]*
      \n
   )(?!\s*[\{\\;])
//gmx;

$file =~ s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      e(?:lse|ndif)
      |
      line
      |
      include
      |
      undef
   )
   .*
   $
//gmx;

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

my @exported = $file =~ m/EXPORT_SYMBOL(?:_GPL(?:_FUTURE)?)?\(\s*(\w+)\s*\)[ \t]*;/gm;

my $status;
$status = 1;

my $name;
foreach $name ( @exported ) {
   if ( $file =~
      m/
      (?<fdecl>
         (?<decl>
            [\w \t\s\\\*\(\)\,]*
            (?:inline|static)
            [\w \t\s\\\*\(\)\,]+
         )
         (?>
            \b$name        # function name
            \s*                  # spaces between name and arguments
            (?<fargs>
               \(
                (?:
                   [^\(\)]
                   |
                   (?&fargs)
                )+
               \)
            )
         )
      )
      (?:\s*__(?:acquires|releases|attribute__)\s*(?<margs>\((?:[^\(\)]|(?&margs))+\)))*
      \s*                  # spaces between arguments and function body
      (?>
         (?<fbody>                    # function body group
            \{                # begin of function body
            (?:               # recursive pattern
               [^\{\}]
               |
               (?&fbody)
            )*
            \}                # end of function body
         )
      )
      /gmx
   ) {
      $status = 0;
      
      my $decl = $+{fdecl};
      
      $decl =~ s/\n/ /g;
      $decl =~ s/^[ \t]*$//g;
      $decl =~ s/^[ \t]*//g;
      $decl =~ s/\s{2,}/ /g;
      $decl =~ s/\*\s+/*/g;
      $decl =~ s/\b\*/ */g;
      say $decl;
#   } else {
#      say STDERR $name;
   }
   pos($file) = 0;
}

exit $status

