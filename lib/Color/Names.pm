use v6.c;

unit package Color::Names;

# cw: $*REPO.repo-chain list of CompUnit::Repository::Installation objects
#     that contain path info.

my @color_lists;

BEGIN {
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
				push @color_lists: $b;
			}

			last;
		}
	}
}

sub EXPORT {
	# cw: Really want a SELECTIVE way to load these, instead of doing
	#     them all at compile time.

	#require ::("Color::Names::$_") for @color_lists;

	{
		'&color' 	=> &color,
		'&hex'		=> &hex,
		'&rgb'		=> &rgb
	}
	
}

sub color(Str $n, :$obj) is export {
	my $retVal;

	if $obj.defined && !(try require Color).WHAT.perl.defined {
		die "Color module cannot be found.";
	}


	for (@color_lists) -> $cl {
		my $c;
		$c = ::("Color::Names::{$cl}::%Colors"){$n}
			if ::("Color::Names::{$cl}::%Colors"){$n}:exists;

		if $c.defined {
			$retVal.push: $_ => $obj.defined ??
				::("Color").new($c<hex>)
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

sub hex(Str $n) is export {
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

sub rgb(Str $n, :$hash) is export {
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