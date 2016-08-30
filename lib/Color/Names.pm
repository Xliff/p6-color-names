use v6.c;

my @color_lists_found;
my @color_list;
my $color-support;

sub EXPORT(*@a) {
	# cw: Limit the lists.
	@color_list = @a.elems > 0 ?? 
		@color_lists_found.grep({ $_ eq @a.any })
		!!
		@color_lists_found;

	# cw: Implement SELECTIVE loading.
	for @color_list -> $cl {
		require ::("Color::Names::{$cl}");
	}

	# cw: What we always export.
	{
	 	'&color' 	=> &Color::Names::color,
	 	'&hex'		=> &Color::Names::hex,
	 	'&rgb'		=> &Color::Names::rgb
	}
}

# cw: $*REPO.repo-chain list of CompUnit::Repository::Installation objects
#     that contain path info.
BEGIN {
	$color-support = (try require ::("Color")) !~~ Nil;

	for @($*REPO.repo-chain).grep({
		$_ ~~ CompUnit::Repository::FileSystem
		||
		$_ ~~ CompUnit::Repository::Installation
	}) -> $c {
		my $p = $c.path-spec.subst(/^ .+ '#'/, '');
		if "{$p}/Color/Names".IO.d {
			for dir("{$p}/Color/Names") -> $f { 
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

unit module Color::Names;

our sub color(Str $n, :$obj) is export {
	my $retVal;

	for (@color_list) -> $cl {
		my $c;
		$c = ::("Color::Names::{$cl}::%Colors"){$n}
			if ::("Color::Names::{$cl}::%Colors"){$n}:exists;

		if $c.defined {
			$retVal.push: $_ => $obj.defined ??
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

our sub hex(Str $n) is export {
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

our sub rgb(Str $n, :$hash) is export {
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