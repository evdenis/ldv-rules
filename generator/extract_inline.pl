#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;
use feature qw(say);

undef $/;

while ( <> ) {
   while (
   /
      ^
      [ \t]*
      (?<fdecl>
         static
         \s+
         inline
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
      $decl =~ s/(?<br>\((?:(?>[^\(\)]+)|(?&br))+\))\s*$/(..)/;
      say $decl;
   }
}
