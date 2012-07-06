#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use 5.10.0;
use feature qw(say);

undef $/;

while ( <> ) {
	while (
	/
      ^
      [ \t]*
      \#define
      [ \t]+
      (?<mdecl>
         (?<mname>\w+)
  	      \([\w\s,\*\.]*\)      # arguments. non-argument macros is possible
      )
	/gmx
	) {
		say $+{mname};
		
		my $decl = $+{mdecl};
		
		$decl =~ s/\n/ /g;
		$decl =~ s/^[ \t]*$//g;
		$decl =~ s/^[ \t]*//g;
		$decl =~ s/\s{2,}/ /g;
		say $decl;
	}
}

