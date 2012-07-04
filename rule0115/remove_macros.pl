#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use 5.10.0;
use feature qw(say);

undef $/;
$_ = <>;

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

s/
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


s/
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
   )(?![ \t]+[\{\\;])
//gmx;


s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      e(?:lse(?!if)|ndif)
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


s/
   ^
   [ \t]*
   \#
   [ \t]*
   (?:
      define
      |
      elseif
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


print;

