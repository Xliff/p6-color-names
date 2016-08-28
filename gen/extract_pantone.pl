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

my $fh = "pantone_coated_table.html".IO.open(:r)
or
die "Can't open Pantone color file";

my $c = $fh.slurp-rest;
$fh.close;

#$p5.call('mojo_new', $c);
$m = Mojo::DOM.new($c);
my @l;
my $cnt = 0;
for @($m.find('table tr td:first-child').to_array) -> $e {
	next if $cnt++ == 0;

	my $n = $e.all_text;
	my $h = $e.next.all_text;
	my ($r, $g, $b) = $h.comb(2).map({ "0x$_".fmt('%3d') });
	my $et = do given $n {
		when .chars < 6  	{ "\t\t\t" }
		when .chars < 14 	{ "\t\t"   } 
		default			 	{ "\t"     }
	}

	@l.push: "\t'{$n}'{$et}=> \{ hex => '#$h', red => $r, green => $g, blue => $b \}";
}

my $oh = open('../lib/Color/Names/Pantone.pm', :w)
or
die "Cannot open output file X11.pm";

$oh.print(qq:to<EOF>);
use v6.c;

unit package Color::Names::Pantone;

my \%Colors = (
{ @l.join(",\n") }
);
EOF

$oh.close;
