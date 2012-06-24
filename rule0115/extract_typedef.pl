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
	typedef
	\s+
	\w+
	(?:
#		(?<tmp1>
#			\w+
#			|
#			\s+
#			|
#			\*
#			|
#			\{
#			(?:
#				[^\{\}]
#				|
#				(?&tmp1)
#			)*
#			\}
#		)*?
#		(?<tname>\w+)
#		|
		(?<tmp2>
			\(
			(?:
				\*
				|
				[ \t]+
				|
				(?<tname>\w+)
			)+
			\)
			\s*
			\(
				[^)]+
			\)
		)
	)
	\s*
	;
	/gmx
	) {
		say $+{tname};
	}
}

