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

my $fh = "X11_color_names".IO.open(:r)
or
die "Can't open X11 color file";

my $c = $fh.slurp-rest;
$fh.close;

#$p5.call('mojo_new', $c);
$m = Mojo::DOM.new($c);
my @l;
for @($m.find('#mw-content-text tr th span a').to_array) -> $e {
	my $n = $e.all_text;
	my $h = $e.parent.parent.next.all_text;
	my ($r, $g, $b) = $h.substr(1).comb(2).map({ "0x$_".fmt('%3d') });
	my $et = do given $n {
		when .chars < 6  	{ "\t\t\t" }
		when .chars < 14 	{ "\t\t"   } 
		default			 	{ "\t"     }
	}

	@l.push: "\t'{$n}'{$et}=> \{ hex => '$h', red => $r, green => $g, blue => $b \}";
}

my $oh = open('../lib/Color/Names/X11.pm', :w)
or
die "Cannot open output file X11.pm";

$oh.print(qq:to<EOF>);
use v6.c;

unit package Color::Names::X11;

our \%Colors = (
{ @l.join(",\n") }
);
EOF

$oh.close;
