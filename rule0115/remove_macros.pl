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

s/
   ^
   [ \t]*
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
   )
   \s+
   (?<s>[^\{])
/$+{s}/gmx;


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
      .+(?=\\\n)
      \\\n
      (?&mbody)?
   )?
   .+
   $
//gmx;

print;

