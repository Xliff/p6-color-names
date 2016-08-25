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

my $fh = "crayola-wikipedia.html".IO.open(:r)
or
die "Can't open Crayola color file";

my $c = $fh.slurp-rest;
$fh.close;

#$p5.call('mojo_new', $c);
$m = Mojo::DOM.new($c);
my @l;
my %collider;
my $tables = $m.find('table.wikitable').to_array[0, 1, 11];

for @($tables) -> $e {

	my $cnt = 0;
	for @($e.at('tbody').children('tr').to_array) -> $tr {
		#next if $cnt++ == 0;

		my $td = $tr.children.first;
		$td = $td.next if $e eqv $tables[2];
		$td.attr('style') ~~ / 'background:' ' '? ('#' . ** 6) ';' /;
		my $h = $/[0].Str.substr(1);
		my $n = $td.all_text.subst("'", "\\'").trim;
		next if %collider{$n}:exists;
		%collider{$n} = 1;

		my ($r, $g, $b) = $h.comb(2).map({ "0x$_".fmt('%3d') });
		my $et = do given $n {
			when .chars < 6  	{ "\t\t\t" }
			when .chars < 14 	{ "\t\t"   } 
			default			 	{ "\t"     }
		}

		@l.push: "\t'{$n}'{$et}=> \{ hex => '#$h', red => $r, green => $g, blue => $b \}";
	}
}

my $oh = open('../lib/Color/Names/Crayola.pm', :w)
or
die "Cannot open output file X11.pm";

$oh.print(qq:to<EOF>);
use v6.c;

unit class Color::Names::Crayola;

my \%Colors = (
{ @l.join(",\n") }
);
EOF

$oh.close;
