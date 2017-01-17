#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use 5.016;  # enable the full feature package of Perl 5.22 incl. full unicode

use lib 'lib';

use Getopt::Long 2.33 qw( :config posix_default gnu_getopt auto_version auto_help );
use Pod::Usage;
use Business::IBAN;
use Text::Trim;
use Data::Dumper;
use Carp;

use Try::Tiny;
use REST::Neo4p;
use SKGB::Intern::Person::Neo4p;

our $VERSION = 0.00;



# parse CLI parameters
my $verbose = 0;
my %options = (
	man => undef,
	out_file => 'LISTEN.TXT',
);
GetOptions(
	'verbose|v+' => \$verbose,
	'man' => \$options{man},
	'output|o' => \$options{out_file},
) or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};



my $Q = {
  export => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[r]-(s:Role)--(:Role{role:'member'})
WHERE s.role <> 'guest-member'
RETURN p, s, r
ORDER BY p.gsvereinId
QUERY
#   sepa => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)--(:Mandate)
# WHERE has(p.gsvereinId)
# RETURN DISTINCT p
# ORDER BY p.gsvereinId, p.born, p.debitorSerial, p.name
# UNION
# MATCH (p:Person)--(:Role)--(:Role{role:'member'})
# WHERE NOT ((p)--(:Mandate))
# RETURN p
# ORDER BY p.gsvereinId, p.debitorSerial, p.name
# QUERY
};

# initiate DB connection
try {
	REST::Neo4p->connect('http://127.0.0.1:7474', 'neo4j', 'pass');
} catch {
	ref $_ ? $_->can('rethrow') && $_->rethrow || die $_->message : die $_;
};



my (undef, undef, undef, $targetDay, $targetMonth, $targetYear, undef, undef, undef) = localtime;
my $targetDate = sprintf("%04d-%02d-%02d", $targetYear + 1900, $targetMonth + 1, $targetDay);

my $out_file = $options{out_file};
open(my $fh, '> :encoding(UTF-8)', $out_file) or die "Could not open file '$out_file' $!";

#print $fh "Name\tVorname\tMitnum\tZu2\tAbteilung\tGbetrag\tZu7\tZahlfremd\tZahlart\tKtonr\n";
print $fh "Mitnum\tName\tTitel\tVorname\tAbteilung\tZu16\tZu15\tZu2\tTelefon\tTelefon2\tOrt\tZu12\tMitseit\tAustritt\tZahlart\tSatz\tGbetrag\tAktiv\tZu11\tZu1\tTelefax\tZu3\n";
#Mitnum	Name	Titel	Vorname	Abteilung	Zu16	Zu15	Zu2	Telefon	Telefon2	Ort	Zu12	Mitseit	Austritt	Zahlart	Satz	Gbetrag	Aktiv	Zu11	Zu1	Telefax	Zu3


#my %years = ();
$Q->{export}->execute();
while ( my $row = $Q->{export}->fetch ) {
	my ($p, $s, $r) = @$row;
	if ($r->get_property('leaves') && $r->get_property('leaves') lt $targetDate || $r->get_property('joined') && $r->get_property('joined') gt $targetDate) {
		next;
	}
	$p = SKGB::Intern::Person::Neo4p->new($p);
	
	# Abteilung
	my @rels;
	my $status;
	if ($s->get_property('role') eq 'active-member') {
		$status = 'Aktiv';
	}
	elsif ($s->get_property('role') eq 'passive-member') {
		$status = 'Passiv';
	}
	elsif ($s->get_property('role') eq 'youth-member') {
		$status = 'Jugend';
	}
	elsif ($s->get_property('role') eq 'honorary-member') {
		if ($r->get_property('regularContributor')) {
			$status = 'Aktiv, Ehrenmitglied';
		}
		else {
			$status = 'Passiv, Ehrenmitglied';
		}
	}
	else {
		$status = "Nichtmitglied";
#		print $fh $mandate{umr} && $Gbetrag eq "0,00" ? "Nichtmitglied, Kontoinhaber" : "Nichtmitglied" if ! $status;
	}
	@rels = $p->{_node}->get_outgoing_relationships();
	foreach my $t (@rels) {
		my $role = $t->end_node->get_property('role');
		if ($role && $role eq 'guest-member') {
			$status .= ", Gastmitglied";
			last;
		}
	}
#	print $fh "\t";
#	print $fh "$Gbetrag\t";
	
	print $fh ($p->gs_verein_id || ""), "\t";
#	print Encode::encode('UTF-8', $p->name_part(1)), "\t";
#	print Encode::encode('UTF-8', $p->name_part(0)), "\t";
	my $nachname = $p->name_part(1);
	$nachname =~ s/ć/c´/;
	print $fh "$nachname\t";
	
	print $fh $p->{_node}->get_property('prefix') || "", "\t";  # Titel
	
	print $fh $p->name_part(0), "\t";
	print $fh "$status\t";
	
	print $fh "\t";  # Zu16
	print $fh "\t";  # Zu15
	
	my @emails = $p->primary_emails;
	print $fh $emails[0] if @emails;
	print $fh "\t";
	
	print $fh "\t";  # Telefon
	print $fh "\t";  # Telefon2
	print $fh "\t";  # Ort
	print $fh "\t";  # Zu12
	
	print $fh $r->get_property('joined') || "", "\t";
	print $fh $r->get_property('leaves') || "", "\t";
	
	print $fh "\t";  # Zahlart
	print $fh "\t";  # Satz
	
	print $fh $p->{_node}->get_property('debitBase'), ",00", "\t";
	print $fh $r->get_property('regularContributor') ? "Wahr" : "Falsch", "\t";
	
	print $fh "\t";  # Zu11
	print $fh "\t";  # Zu1
	print $fh "\t";  # Telefax
	print $fh "\t";  # Zu3
	
# 	#get mandate
# 	my %mandate = ();
# 	my $Zahlfremd = 1;
# 	@rels = $p->{node}->get_incoming_relationships();
# 	foreach my $rel (@rels) {
# 		$Zahlfremd = undef if $rel->type eq 'HOLDER';
# 		next if $rel->type ne 'DEBITOR' && $rel->type ne 'HOLDER';
# #		next if ! $rel->get_property('primary');
# 		my $start_node = $rel->start_node;
# #		next if $start_node->get_property('type') ne 'email';
# 		my $umr = $start_node->get_property('umr');
# 		next if $mandate{umr} && $mandate{umr} eq $umr;
# 		die "person with two different mandates not implemented" if $mandate{umr};
# 		$mandate{umr} = $umr;
# 		$mandate{iban} = $start_node->get_property('iban');
# 	}
# 	$Zahlfremd = 1 if $p->gs_verein_id() eq '001' && $mandate{umr} eq '20021';
# 	
# 	my $Gbetrag = sprintf "%.2f", $p->{node}->get_property('debitBase') || 0;
# 	$Gbetrag =~ s/\./,/;
# 	
# 	print $fh %mandate ? $mandate{umr} : "";
# 	print $fh "\t";
# 	print $fh $Zahlfremd || ! $status ? "Wahr" : "Falsch";
# 	print $fh "\t";
# 	print $fh %mandate && $status ? "Bankeinzug" : ($Gbetrag eq "0,00" ? "" : "Überweisung");
# 	print $fh "\t";
# 	print $fh %mandate ? $mandate{iban} : "";
	
	print $fh "\n";
}
$Q->{export}->finish;
close $fh;


# #say Data::Dumper::Dumper(\%bins);


exit 0;

__END__
