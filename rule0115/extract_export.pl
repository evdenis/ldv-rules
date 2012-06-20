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
	(?<fdecl>
		[^\(\)\{\}\[\];,\/]+ # declarations before function name
		(?<fname>\w+)        # function name
		\s*                  # spaces between name and arguments
		\([\w\s,\*]*?\)      # arguments
	)
	\s*                  # spaces between arguments and function body
	(                    # function body group
		\{                # begin of function body
		(                 # recursive pattern
			[^\{\}]
			|
			(?-2)
		)*
		\}                # end of function body
	)
	\s*                  # spaces between function body and EXPORT_SYMBOL_GPL
	EXPORT_SYMBOL_GPL
	\(\s*\g{fname}\s*\)      # function name within () brackets
	[ \t]*;                  # spaces between () and ;
	/gmx
	) {
	#	$1 =~ tr/\n//;
		say $+{fname};
		my $decl = $+{fdecl};
		$decl =~ s/\n//;
		say $decl;
		print "\n";
#		print "$2\n";
	}
}

