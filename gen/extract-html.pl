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

my $fh = "html_color_names.asp".IO.open(:r)
or
die "Can't open X11 color file";

my $c = $fh.slurp-rest;
$fh.close;

#$p5.call('mojo_new', $c);
$m = Mojo::DOM.new($c);
my @l;
for @($m.find('table.w3-table-all tr td:first-child').to_array) -> $e {
	my $n = $e.all_text.trim;
	my $h = $e.next.all_text.lc;
	my ($r, $g, $b) = $h.substr(1).comb(2).map({ "0x$_".fmt('%3d') });
	my $et = do given $n {
		when .chars < 6  	{ "\t\t\t" }
		when .chars < 14 	{ "\t\t"   } 
		default			 	{ "\t"     }
	}

	@l.push: "\t'{$n}'{$et}=> \{ hex => '$h', red => $r, green => $g, blue => $b \}";
}

my $oh = open('../lib/Color/Names/HTML.pm', :w)
or
die "Cannot open output file HTML.pm";

$oh.print(qq:to<EOF>);
use v6.c;

unit package Color::Names::HTML;

our \%Colors = (
{ @l.join(",\n") }
);
EOF

$oh.close;
