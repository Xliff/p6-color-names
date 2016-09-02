use v6.c;

my @color_lists_found;
my @color_list;
my $color-support;
my $color_location;

sub EXPORT(+@a) {
	# cw: Implement SELECTIVE loading if necessary.
	@color_list = @a.elems > 0 ?? 
		@color_lists_found.grep(@a.any)
		!!
		@color_lists_found;

	for @color_list -> $cl {
		require ::("Color::Names::{$cl}");
	}

	# cw: What we always export.
	#
	#     Is there any way to get EXPORT::DEFAULT from the module block?
	{
		'&lists'	=> ::('&Color::Names::lists'),
		'&location' => ::('&Color::Names::location'),
	  	'&color' 	=> ::('&Color::Names::color'),
	  	'&hex'		=> ::('&Color::Names::hex'),
	  	'&rgb'		=> ::('&Color::Names::rgb'),
	}
}

BEGIN {
	# cw: Check for existence of Color class.
	$color-support = (try require ::("Color")) !~~ Nil;

	# cw: $*REPO.repo-chain list of CompUnit::Repository::Installation 
	#	  objects that contain path info.
	#	  So now we can check what color lists exist, but first we need
	#     to find where they are stored.
	for @($*REPO.repo-chain).grep({
		$_ ~~ CompUnit::Repository::FileSystem
		||
		$_ ~~ CompUnit::Repository::Installation
	}) -> $c {
		my $p = $c.path-spec.subst(/^ .+ '#'/, '');
		$color_location = "{$p}/Color/Names";
		if $color_location.IO.d {
			for dir($color_location) -> $f { 
				my $b = $f.basename;
				$b ~~ s/ '.' pm6?//;
				push @color_lists_found: $b;
			}

			last;
		}
	}
}

INIT { 
	if $color-support {
		require Color;
	}
}

module Color::Names {

	our sub lists {
		( @color_lists_found.flat );
	}

	our sub location {
		$color_location;
	}

	our sub color(Str $n, :$obj) {
		my $retVal;

		for (@color_list) -> $cl {
			my $c;
			$c = ::("Color::Names::{$cl}::%Colors"){$n}
				if ::("Color::Names::{$cl}::%Colors"){$n}:exists;

			if $c.defined {
				$retVal.push: $cl => $obj.defined ??
					::("Color").new(:hex($c<hex>))
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