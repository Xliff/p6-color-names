use v6.c;

our @color_list = <Cloford Crayola HTML X11 Pantone>;
our @color_lists_found = @color_list;
our $color_support;
our $color_location;

# cw: Really want to run pre EXPORT!
INIT { 
	
}

# cw: Execute every time this is used! BEGIN blocks are compile-time ONLY.
{
	# cw: Check for existence of Color class.
	$color_support = (try require ::('Color')) !~~ Nil;


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

sub EXPORT(+@a) {
	# cw: Implement SELECTIVE loading if necessary.
	#@color_list = @a.elems > 0 ?? 
	#	@color_lists_found.grep(@a.any)
	#	!!
	#	@color_lists_found;

	if $color_support {
		require Test;
	}
	#for @color_list -> $cl {
	#	say "L: $cl";
	#	require ::("Color::Names::{$cl}");
	#}

	# cw: What we always export.
	#
	#     Is there any way to get EXPORT::DEFAULT from the module block?
	{
		'&lists_available'	=> ::('&Color::Names::lists_available'),
		'&lists_loaded'		=> ::('&Color::Names::lists_loaded'),
		'&location'			=> ::('&Color::Names::location'),
	  	'&color' 			=> ::('&Color::Names::color'),
	  	'&hex'				=> ::('&Color::Names::hex'),
	  	'&rgb'				=> ::('&Color::Names::rgb'),
	}
}

module Color::Names {

	our sub lists_available {
		( @color_lists_found.flat );
	}

	our sub lists_loaded {
		( @color_list.flat )
	}

	our sub location {
		$color_location;
	}

	our sub color(Str $n, :$obj) {
		my $retVal;

		for (@color_list) -> $cl {
			my $c;
			$c = ::("\%Color::Names::{$cl}::Colors"){$n}
				if ::("\%Color::Names::{$cl}::Colors"){$n}:exists;

			if $c.defined {
				$retVal.push: $cl => $obj.defined ??
					::('Color').new(:hex($c<hex>))
					!!
					$c
			}
		}

		# cw: Simplify return value if only one match.
		$retVal.defined ??
			($retVal.elems == 1 ?? $retVal[0].value !! $retVal)
			!!
			Nil;
	}

	our sub hex(Str $n) {
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

	our sub rgb(Str $n, :$hash) {
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
