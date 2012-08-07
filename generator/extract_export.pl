#!/usr/bin/perl

use strict;
use warnings;
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
         (?>[^"\\\n]+)
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
            (?>[^\(\)\n\{\;\}]+)
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

my @exported = $file =~ m/EXPORT_SYMBOL(?:_GPL(?:_FUTURE)?)?\s*\(\s*(\w+)\s*\)\s*;/gm;

my $name;
foreach $name ( @exported ) {
   if ( $file =~
      m/
      (?<fdecl>
         #[^\(\)\{\}\[\];,\/\\\'\"#><\.]+ # declarations before function name
         (?<decl>
            #(?<!
            #\#endif
            #)
            #(?<!
            #\#else
            #)
            #(?<!
            #\#ifdef  #Variable-lenght lookbehid is not supported
            #)
            #(?<!
            #   \#define #Variable-lenght lookbehind is not supported
            #)
            #(?<!
            #\#elif   #Variable-lenght lookbehind is not supported
            #)
            #[\w \s\\\*]
            #\#?[\w \s\\\*\(\)] #Workaround for look-behind
            [\w \t\s\\\*\(\)\,]+
         )
         (?>
            \b$name        # function name
            \s*                  # spaces between name and arguments
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
      \s*                  # spaces between arguments and function body
      (?:
         (?:
            (?:__(?:acquires|releases|attribute__)\s*(?<margs>\((?:(?>[^\(\)]+)|(?&margs))+\)))
            |
            __attribute_const__
            |
            CONSTF
            |
            \\
         )\s*
      )*
      (?>
         (?<fbody>                    # function body group
            \{                # begin of function body
            (?:               # recursive pattern
               (?>[^\{\}]+)
               |
               (?&fbody)
            )*
            \}                # end of function body
         )
      )
      /gmx
   ) {
      
      my $decl = $+{fdecl};
      
      #Dirty workaround for look-behind. Comments not supported. Multiline defines not supported.
      #$decl =~ s/^[ \t]*\#ifdef[ \t]+\w+[ \t]*$//gm;
      #$decl =~ s/^[ \t]*\#ifndef[ \t]+\w+[ \t]*$//gm;
      #$decl =~ s/^[ \t]*\#if[ \t]+[\w!\(\)<>=|&\+\-\*\/,]+[ \t]*$//gm;
      #$decl =~ s/^[ \t]*\#define[ \t]+[\w!\(\)<>=|&\+\-\*\/,]+[ \t]*$//gm;
      #$decl =~ s/^[ \t]*\#undef[ \t]+[\w!\(\)<>=|&\+\-\*\/,]+[ \t]*$//gm;
      
      $decl =~ s/\n/ /g;
      $decl =~ s/^[ \t]*$//g;
      $decl =~ s/^[ \t]*//g;
      $decl =~ s/\s{2,}/ /g;
      $decl =~ s/\*\s+/*/g;
      $decl =~ s/\b\*/ */g;
      $decl =~ s/\*\s+\*/**/g;
      $decl =~ s/(\w+)\s+\(/$1(/g;
      
      $decl =~ s/(?<args>(?<br>\((?:(?>[^\(\)]+)|(?&br))+\)))\s*$/(..)/;
      my $args = $+{args};
      $args =~ s/^\s*\(//;
      $args =~ s/\)\s*$//;
      $args =~ m/^\s*(?<arg>[^,]+)/;
      my $first_arg = $+{arg};
      if ( $decl =~ m/\(\s*\Q$first_arg\E\s*[,)]/p ) {
         #my $expr;
         #foreach $expr (1..$#-) {
         #   print "Match at position ($-[$expr],$+[$expr])\n";
         #}
         my $first_func = ${^PREMATCH};
         $first_func =~ s/\(\s*$//g;
         $decl =~ s/\Q$first_func\E\s*(?<br>\((?:(?>[^\(\)]+)|(?&br))+\))\s*//;
         
         $first_func =~ m/(?<first_func_name>\w+)\s*$/p;
         
         # return argumenst equality check
         if ( substr(${^PREMATCH}, 0, $-[0]) eq substr($decl, 0, $-[0])) {
            say $+{first_func_name};
            $first_func =~ s/\s*$/(..)/;
            
            say $first_func;
         }
      }
      
      say $name;
      say $decl;
#   } else {
#      say STDERR $name;
   }
   pos($file) = 0;
}

