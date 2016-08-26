use v6.c;

use Inline::Perl5;
use Mojo::DOM:from<Perl5>;

my $p5 = Inline::Perl5.new;
my $m;

#$p5.run('
#	use Mojo::DOM;
#
#	sub mojo_new($c) {
#		$m = Mojo::DOM->new($c)
#	}
#');

my $fh = "cloford-colors.html".IO.open(:r, enc => 'latin1')
or
die "Can't open Cloford color file";

my $c = $fh.slurp-rest;
$fh.close;

#$p5.call('mojo_new', $c);
$m = Mojo::DOM.new($c);
my @l;
my $cnt = 0;
my %collider;
for @($m.find('table.webcol tr td:first-child font').to_array) -> $e {
	next if $cnt++ == 0;

	my $n = $e.all_text;
	my $a;
	if $n ~~ s/ \s+ '(' (.+?) ')'$// {
		$a = $/[0].Str;
	}
	if $n ~~ s/ \s* '/' \s* (.+)$// {
		$a = $/[0].Str;
	}
	$n ~~ s/\W//;
	$a ~~ s/\W// if $a.defined;

	# cw: For Cloford colors, we have to handle aliasing (names in paren)
	#     and those should go BEFORE the name encountered.
	my $h = $e.attr('color').substr(1);
	my ($r, $g, $b) = $h.comb(2).map({ "0x$_".fmt('%3d') });

	sub t($x) {
		when $x.chars < 6  	{ "\t\t\t" }
		when $x.chars < 14 	{ "\t\t"   } 
		default			 	{ "\t"     }
	}

	if $a.defined && !(%collider{$a}:exists) {
		@l.push: "\t'{$a}'{t($a)}=> \{ hex => '#$h', red => $r, green => $g, blue => $b \}";
		%collider{$a} = 1;
	}
	
	unless %collider{$n}:exists {
		@l.push: "\t'{$n}'{t($n)}=> \{ hex => '#$h', red => $r, green => $g, blue => $b \}";
		%collider{$n} = 1;
	}	

}

my $oh = open('../lib/Color/Names/Cloford.pm', :w)
or
die "Cannot open output file X11.pm";

$oh.print(qq:to<EOF>);
use v6.c;

unit class Color::Names::Cloford;

my \%Colors = (
{ @l.join(",\n") }
);
EOF

$oh.close;
