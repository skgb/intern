package SKGB::Intern::Command::dosb;
use Mojo::Base 'Mojolicious::Command';

use SKGB::Intern::Verbandsmeldung;

use Getopt::Long 2.33 qw(GetOptionsFromArray :config posix_default gnu_getopt no_auto_abbrev no_ignore_case);

has description => 'Statistik und DOSB-Schnittstelle';
has usage => sub { shift->extract_usage };

sub run {
	my ($self, @args) = @_;
	
	my %options = (
		out_file => undef,
		verbose => 0,
	);
	GetOptionsFromArray \@args,
		'o|output=s' => \$options{out_file},
		'v|verbose+' => \$options{verbose};
	
	$options{app} = $self->app;
	my $stats = SKGB::Intern::Verbandsmeldung->new( %options )->query;
	
	$options{out_file} ||= $stats->dosb_filename;
	open(my $fh, '>', $options{out_file}) or die "Could not open file '$options{out_file}' $!";
	print $fh $stats->dosb;
	close $fh;
	
	say $stats->svnrw;
	say $stats->dsv;
}

1;


__END__

=pod

=head1 NAME

dosb.pl - DOSB-Schnittstelle fuer Landessportbund

=head1 SYNOPSIS

 script/skgb_intern.pl dosb
 script/skgb_intern.pl dosb -v
 script/skgb_intern.pl dosb -o 123456ja.dat

=head1 DESCRIPTION

Der LSB NRW bietet fuer seine Bestandserhebung den Datenimport per
(unvollstaendig implementierter) DOSB-Schnittstelle an. Dieser Befehl
implementiert die DOSB-Schnittstelle (ebenfalls unvollstaendig) fuer
SKGB-intern 2. Es wird eine Ausgabedatei mit dem korrekten Namen erzeugt und
zusaetzlich werden die B-Zahlen fuer LSB/SVNRW sowie die Zahlen fuer die
DSV-Vereinsmeldung nach stdout ausgegeben.

=head1 AUTHOR

Arne Johannessen, L<mailto:arne@thaw.de>

=head1 COPYRIGHT

Copyright (c) 2016 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
