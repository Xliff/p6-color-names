use v6.c;

our $color_support;
our $color_location;
our @color_list = <Cloford Crayola HTML X11 Pantone>;
our @color_lists_found = @color_list;

# cw: Execute every time this is used! BEGIN blocks are compile-time ONLY.
{
	# cw: Check for existence of Color class.
	$color_support = (try require ::('Color')) !~~ Nil;
	if $color_support {
		require Color;
	}

	#for @color_list -> $cl {
	#	say "L: $cl";
	#	require ::("Color::Names::{$cl}");
	#}

	# cw: Works fine when not installed, but when installed module names get 
	#     converted to files with an SHA1 name. Therefore selective loading
	#     via this method is not possible in Perl6. Would need to do something
	#	  else, maybe with META.info!?!
	#
	#
 	# cw: $*REPO.repo-chain list of CompUnit::Repository::Installation 
 	#	  objects that contain path info.
 	#	  So now we can check what color lists exist, but first we need
 	#     to find where they are stored.
 	#for @($*REPO.repo-chain).grep({
 	#	$_ ~~ CompUnit::Repository::FileSystem
 	#	||
 	#	$_ ~~ CompUnit::Repository::Installation
 	#}) -> $c {
 	#	my $p = $c.path-spec.subst(/^ .+ '#'/, '');
 	#	$color_location = "{$p}/Color/Names";
 	#	if $color_location.IO.d {
 	#		for dir($color_location) -> $f {
 	#			my $b = $f.basename;
 	#			$b ~~ s/ '.' pm6?//;
 	#			push @color_lists_found: $b;
 	#		}
 	#
	#		last;
 	#	}
 	#}
}

#sub EXPORT(+@a) {
	# cw: Implement SELECTIVE loading if necessary.
#	@color_list = @a.elems > 0 ?? 
#		@color_lists_found.grep(@a.any)
#		!!
#		@color_lists_found;

#	for @color_list -> $cl {
	#	say "L: $cl";
#		require ::("Color::Names::{$cl}");
		#
		# Stick dynamic color lists in an object!!!
		# Better yet, convert this to a class which takes the lists as a parameter to new!
#	}

	# cw: What we always export.
	#
	#     Is there any way to get EXPORT::DEFAULT from the module block?
	#{
	#	'&lists_available'	=> ::('&Color::Names::lists_available'),
	#	'&lists_loaded'		=> ::('&Color::Names::lists_loaded'),
	#	'&location'		=> ::('&Color::Names::location'),
	#  	'&color' 		=> ::('&Color::Names::color'),
	#  	'&hex'			=> ::('&Color::Names::hex'),
	#  	'&rgb'			=> ::('&Color::Names::rgb'),
#}
#}

class Color::Names {
	has %!lists;
	has Boolean $!use_color_obj;

	method always_use_obj {
		$!use_color_obj = True;
		self;
	}

	method never_use_obj {
		$!use_color_obj = False;
		self;
	}

	method lists_available {
		( @color_lists_found.flat );
	}

	method lists_loaded {
		( @color_list.flat )
	}

	# cw: There really is no reason for this, now.
	#
	#method location {
	#	$color_location;
	#}

	# The rest of these should be moved to a Role.

	# cw: Now return list of matching colors in pairs: Color, Catalog
	method color(Str $n, :$obj) {
		my $retVal;

		for (@color_list) -> $cl {
			my $c;
			$c = ::("\%Color::Names::{$cl}::Colors"){$n}
				if ::("\%Color::Names::{$cl}::Colors"){$n}:exists;

			if $c.defined {
				my $mc - $cl => $!use_color_obj || $obj.defined ??
					::('Color').new(:hex($c<hex>))
					!!
					$c;
				$retVal.push: [ $mc, $cl ];
			}
		}

		# cw: Simplify return value if only one match.
		$retVal.defined ??
			($retVal.elems == 1 ?? $retVal[0].value !! $retVal)
			!!
			Nil;
	}

	method hex(Str $n) {
		given color($n) {
			when Hash {
				$_<hex>;
			}

			when Array {
				$_.map: { $_.value<hex> }
			}

			default {
				Nil;
			}
		}
	}

	method rgb(Str $n, :$hash) {
		given color($n) {
			when Hash {
				$hash.defined ??
					(
						red   => $_<red>, 
						green => $_<green>, 
						blue  => $_<blue> 
					)
					!!
					( $_<red>, $_<green>, $_<blue>);
			}

			when Array {
				$_.map: { 
					$hash.defined ??
					{
						red   => $_.value<red>, 
						green => $_.value<green>, 
						blue  => $_.value<blue> 
					}
					!!
					[ $_.value<red>, $_.value<gree>, $_.value<blue> ] 
				};
			}

			default {
				Nil;
			}
		}
	}

}
