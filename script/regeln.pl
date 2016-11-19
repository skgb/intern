#! /usr/bin/env perl
# $Id: regeln.pl 2015-11-13 aj3 $

use strict;
use warnings;

our $VERSION = 0.80;

use lib 'lib';

#use File::Spec;
#use File::Basename;
use Getopt::Long 2.33 qw( :config posix_default gnu_getopt auto_version auto_help );
use Pod::Usage;
#use Data::Dumper;

use SKGB::Regeln;


# parse CLI parameters
#my $verbose = 0;
my $baseVersion = '';
my $showChanges = 'none';  # all | none | <date>
my $outputFormat = 'xml';  # xml | html | odf | txt | rep
my %options = (
	man => undef,
	list_mode => undef,
);
GetOptions(
#	'verbose|v+' => \$verbose,
	'man' => \$options{man},
	'changes|c=s' => \$showChanges,
	'base-version|b=s' => \$baseVersion,
	'format|f=s' => \$outputFormat,
	'list-versions|l' => \$options{list_mode},
) or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};
#push @ARGV, 'Satzung/Satzung 2015.xml';  # DEBUG

# make sure we have everything we need
if (1 > scalar @ARGV) {
	pod2usage(-exitstatus => 3, -verbose => 0, -message => 'Missing required input file name.');
}


my $regeln = SKGB::Regeln->load( $ARGV[0] );


if ($options{list_mode}) {
	my @versionList = $regeln->version_list;
	print "base\n";
	foreach my $date (@versionList) {
		print "$date\n";
	}
	exit 0;
}


#pre1: remove changes newer than the given base version
if (! $baseVersion) {
	if ($showChanges eq 'none' || $showChanges eq 'all') {
		$baseVersion = 'head';
	}
	else {
#		foreach my $version (@versionList) {
#			if ($version eq $showChanges) {
				$baseVersion = $showChanges;
#				last;
#			}
#		}
	}
}
$regeln->show_base($baseVersion);


#pre2
if ($showChanges eq 'none') {
	$regeln->hide_changes();
}
elsif ($showChanges ne 'all') {
	$regeln->show_changes( $showChanges );
}


if ($outputFormat eq 'html') {
	print $regeln->as_html;
}
elsif ($outputFormat eq 'odf') {
	print $regeln->as_odf;
}
elsif ($outputFormat eq 'txt') {
	print $regeln->as_txt;
}
elsif ($outputFormat eq 'rep') {
	print $regeln->as_report;
}
else {
	print $regeln->as_xml;
}




# ./regeln.pl FinO.xml -l > FinO.list ; while read f ; do ./regeln.pl -c "$f" -f html FinO.xml > "FinO.$f.d.xhtml" ; done < FinO.list


exit 0;

__END__

=pod

=head1 NAME

regeln.pl - handle SKGB-Regeln files

=head1 SYNOPSIS

 regeln.pl -f odf Satzung.xml  > Satzung.2015.fodt
 regeln.pl -b base Satzung.xml  > Satzung.2000.xml
 regeln.pl -c all -f html Satzung.xml  > Satzung.2000-2015.xhtml
 regeln.pl -l Satzung.xml
 regeln.pl -c 2015-05-30 Satzung.xml  > Satzung.2006-2015.xml
 regeln.pl --help|--version|--man

=head1 DESCRIPTION

Reads an SKGB-Regeln file and transforms it into the specified revision and
format.

=head1 OPTIONS

=over

=item B<--base-version, -b>

<head>, <base> or a specific version. If omitted, the default is dependant upon
the value of the --show-changes option as follows:

-c none (or omitted): The base version default is <head> (the latest version).

-c all: The base version default is <head> as well (the latest version).

-c <specific version>: The base version default is same version, such that
exactly one revision step is shown in the output.

=item B<--format, -f>

Chose an output format. Default is <xml>. See FORMATS below.

=item B<--help, -?>

Display a help message and exit.

=item B<--list-versions, -l>

List all revisions mentioned in the file specified and exit (i. e., not
including the base version).

=item B<--man>

Print the manual page and exit.

=item B<--show-changes, -c>

This option causes the document's history to be highlighted. May not be
supported by all output formats. Possible values:

<all>, <none>, or a <specific version> (usually in ISO 8601 date format) to
highlight just the changes made in the specified version since the previous
version. Default is <none>.

=item B<--verbose, -v>

Verbose mode. Produces more output about what the program does. Giving this
option multiple times may produce more and more output.

=item B<--version>

Display version information and exit.

=back

=head1 FORMATS

=over

=item B<XML <xml>>

SKGB-Regeln format.

=item B<HTML <html>>

XHTML 5 output with a stylesheet showing all changes and with a user-selectable
alternative to hide the changes.

=item B<Open Document <odf>>

The Open Document template used does not implement viewing changes at this
time. Results for --show-changes values other than 'none' are undefined.

=item B<Plain Text <txt>>

Plain text removes ALL formatting and meta-data, but displays ALL character
data. Therefore it is only well-defined for --show-changes=none.

The plain text output format is not stable. It may change to e. g. markdown in
the future. Currently it's pretty much unreadable, but its completeness may
still prove useful for tracking changes.

=item B<Report <rep>>

"Artikelgesetz"

not implemented

=back

=head1 AUTHOR

Arne Johannessen, L<mailto:arne@thaw.de>

=head1 COPYRIGHT

Copyright (c) 2015 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
