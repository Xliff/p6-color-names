use v6.c;

our $color_support;
#our $color_location;
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

	has %!catalogs;
	has Boolean $!use_color_obj;
	has Boolean $!use_exeptions;
	has Lookup $.lookup

	# cw: Maybe add Color::Names::Color so that Lookup can use that object and
	#     the helper methods hex() and rgb() can be added to a Role?

	my class Color::Names::Lookup {

		method FALLBACK($name, |C) {
			my $new_meth = method (:$obj) {
				$color($name, :$obj);
			}
			self.^add_method($name, $new_meth);
			self.^compose;
			$new_meth(:obj( C<obj> ));
    }

	}

	method new(@catalogs, :$obj) {
		self.bless(:@catalogs, :$obj, :$exceptions);
	}

	submethod BUILD (
		:@catalogs,
		:$obj,
		:$exceptions
	) {
		$!use_color_obj =  $obj.defined ?? $obj !! False;
		$!use_exceptions = $exeptions.defined ?? $exceptions !! False;
		$.lookup = Color::Names::Lookup.new;
		load_catalogs(@catalogs);
	}

	method always_use_obj {
		$!use_color_obj = True;
		self;
	}

	method never_use_obj {
		$!use_color_obj = False;
		self;
	}

	#method lists_available {
	#	( @color_lists_found.flat );
	#}

	method lists_loaded {
		( %!catalogs.keys.flat )
	}

	method load_catalogs(@Pcats) {
		# cw: Stop problematic duplicates from the get-go.
		my @cats = @Pcats.unique;

		unless (all(@cats) ~~ Str) {
			if $!exceptions {
			} else {
				warn "Illegal parameter found in call to load_catalog\n";
				return;
			}
		}
		for (@cats) -> $nc {
			next unless $nc ~~ Str;
			if $nc == any(%!catalogs.keys) {
				# cW: For now, we do not worry about packages altered or created during run time.
				#     This is something that can be worked into the next version.
				#
				# cw: Again, throw the proper exception if exception handling is requested.
				#     Otherwise fail with the appropriate method.
				if $!exceptions {
				} else {
					say "Catalog '$n' already loaded!";
					next;
				}
			}
			# cw: Load catalog.
			(try require ::("Color::Names::{$nc}") === Nil and {
				# cw: TODO - Throw the proper exception if catalog does not exist, if
				#            exception handling has been requested. Otherwise silently
				#					   fail with proper message.
				say "Color catalog '$nc' does not exist";
				next;
			}
			# cw: Bind instead of assign to optimize memory usage.
			%!catalogs{$nc} := ::("\%Color::Names::{$nc}::Colors");
		}

		# TODO -- cw: Once a new catalog is loaded, all of the methods in Lookup that
		#         match Lookups.noColor should be removed.
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
			# TODO -- cw: Consider trying to cache data using the bind operator,
			#         then checking that structure, FIRST. Note, key would need
			#         to include both color name and catalog.
			$c := do {
				%!catalogs{$cl}.defined && %!catalogs{$cl}{$n}.defined
					??
					%!catalogs{$cl}{$n}
					!!
					Nil
			}

			# TODO == cw: If Color object is requested, check if $color_support
			#             is defined. If not, then throw the proper exception.
			#
			if $c.defined {
				my $mc;
				if $obj // $!use_color_obj {
					$mc = ::('Color').new(:hex($c<hex>))
				} else {
					$mc := $c;
				}
				$retVal.push: [ $mc, $cl ];
			}
		}

		# cw: Simplify return value if only one match.
		$retVal.defined ??
			($retVal.elems == 1 ?? $retVal[0] !! $retVal)
			!!
			Nil;
	}

	method hex(Str $n) {
		given color($n) {
			# cw: Handle Color object, too.
			#
			#
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
			# cw: Handle Color object, too.
			#
			#
			when Hash {
				$hash.defined ??
					(
						red   => $_<red>,
						green => $_<green>,
						blue  => $_<blue>
					)
					!!
					( $_<red>, $_<green>, $_<blue> );
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
