#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.016;  # enable the full feature package of Perl 5.22 incl. full unicode

use lib 'lib';

use Getopt::Long 2.33 qw( :config posix_default gnu_getopt auto_version auto_help );
use Pod::Usage;
#use Data::Dumper;

use Try::Tiny;
use REST::Neo4p;
use SKGB::Intern::Controller::Export;
#use SKGB::Intern::Person::Neo4p;

our $VERSION = 0.10;



# parse CLI parameters
my $verbose = 0;
my %options = (
	man => undef,
	out_file => 'EXPORT.TXT',
);
GetOptions(
	'verbose|v+' => \$verbose,
	'man' => \$options{man},
	'output|o' => \$options{out_file},
) or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};



my $out_file = $options{out_file};
open(my $fh, '> :crlf :encoding(windows1252)', $out_file) or die "Could not open file '$out_file' $!";


# initiate DB connection
# TODO: how do we get the db connection without this?
# perhaps like <http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Adding-commands-to-Mojolicious>
try {
	REST::Neo4p->connect('http://127.0.0.1:7474', 'neo4j', 'pass');
} catch {
	ref $_ ? $_->can('rethrow') && $_->rethrow || die $_->message : die $_;
};


my $export = SKGB::Intern::Controller::Export->_intern1;


foreach my $row (@$export) {
	no warnings 'uninitialized';
	print $fh join("\t", @$row), "\n";
}
close $fh;


exit 0;

__END__
