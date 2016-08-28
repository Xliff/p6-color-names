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

INIT {
	# cw: Really want a SELECTIVE way to load these, instead of doing
	#     them all at compile time.

	# cw: -XXX- breaks rakudo. Won't compile!
	#require ::("Color::Names::$_") for @color_lists;

	# cw: Testing ONLY.
	require ::("Color::Names::Cloford");
}

sub color(Str $n) is export {
	my $retVal;

	for (@color_lists) -> $cl {
		$retVal.push: $_ => ::("Color::Names::{$cl}::%Colors"){$n}
			if ::("Color::Names::{$cl}::%Colors"){$n}:exists;
	}

	# cw: Simplify return value if only one match.
	$retVal.elems == 1 ??
		$retVal[0].value !! $retVal;
}

sub hex(Str $n) is export {
	given color($n) {
		when Hash {
			$_<hex>;
		}

		when Array {
			$_.map: { $_.value<hex> }
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
	}
}