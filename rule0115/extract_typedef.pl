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
		(?<tmp>
			\w+
			|
			\s+
			|
			\*
			|
			\{
			(?:
				[^\{\}]
				|
				(?&tmp)
			)*
			\}
			|
			\(
			(?:
				[^\(\)]
				|
				(?&tmp)
			)*
			\)
		)*?
		(?<tname>\w+)
		|
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
			.+?
		\)
	)
	\s*
	;
	/gmx
	) {
		say $+{tname};
	}
}

