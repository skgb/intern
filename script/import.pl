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

our $VERSION = 0.00;



# parse CLI parameters
my $verbose = 0;
my %options = (
	man => undef,
#	test => undef,
	dev => undef,
	mandate_file => undef,
#	cypher_file => 'out.cypher.txt',
	infra_file => 'conf/infrastructure.cypher',
	roles_file => 'conf/roles.cypher',
	roles_dev_file => 'conf/roles.development.cypher',
	intern_dir => 'conf',
);
GetOptions(
	'verbose|v+' => \$verbose,
	'man' => \$options{man},
	'mandates|m' => \$options{mandate_file},
#	'cypher|c=s' => \$options{cypher_file},
	'infrastructure|f=s' => \$options{infra_file},
	'roles|r=s' => \$options{roles_file},
	'roles-dev-file=s' => \$options{roles_dev_file},
	'intern|i=s' => \$options{intern_dir},
#	'test|t' => \$options{test},
	'dev|d' => \$options{dev},
) or pod2usage(2);
pod2usage(-exitstatus => 0, -verbose => 2) if $options{man};

# make sure we have everything we need
if (1 > scalar @ARGV) {
	pod2usage(-exitstatus => 3, -verbose => 0, -message => 'Missing required input file name.');
}
my $alles_file = $ARGV[0];
# if (! $options{mandate_file} && ! $options{cypher_file}) {
# 	pod2usage(-exitstatus => 4, -verbose => 0, -message => 'Missing required output file name.');
# }
# if ($options{cypher_file} && ! $options{intern_dir}) {
# 	pod2usage(-exitstatus => 5, -verbose => 0, -message => 'Cannot create Cypher code without SKGB-intern legacy ("red") DB directory.');
# }



# Step 1: Build a full data table in memory
# (we don't have that many members, so it's fine)

my @members = ();
my @keys;

open(my $fh, '< :crlf :encoding(windows1252)', $alles_file) or die "Could not open file '$alles_file' $!";
while (my $row = <$fh>) {
	chomp $row;
	$row =~ s/c´/ć/g;  # windows1252_ingo
	my @row = split m/\t/, $row;
	
	if (! @keys) {
		@keys = @row;
		next;
	}
	
	my $member = {};
	for (my $i = 0; $i < scalar @keys; $i++) {
		$member->{ $keys[$i] } = defined $row[$i] ? $row[$i] : '';
	}
	push @members, $member;
}
close $fh;
#	print Encode::encode 'UTF-8', "'$row'\n";



# Step 2: Build the stand-alone Mandate Collection file for SKGB-offline

my $ibanValidator = Business::IBAN->new();
my %mandates = ();
foreach my $member (@members) {
	my $id = $member->{'Mitnum'};
	next if ! $member->{'Zu7'};
	$member->{'Zu7'} =~ m/(\d{5}), (\d{4}-\d\d-\d\d)/;
	my $umr = $1;
	my $signed = $2;
	$member->{'Ktonr'} =~ m/(\S+) (\w\w)([-_0#*A-Za-z0-9]{2})$/;
	my $account = $1;
	my $country = $2;
	my $checkdigits = $3;
	my $sortcode = $member->{'Blz'};
	my $iban = $country . $checkdigits . $sortcode . $account;
	if (! $ibanValidator->valid($iban)) {
		$iban = $ibanValidator->getIBAN({
			ISO => $country,
			BBAN => $sortcode . $account,
		});
		$iban =~ s/^IBAN //;
		$iban =~ s/ /0/;
#		say STDERR "invalid IBAN checksum for UMR $umr @ $id; fixed!";
	}
	$member->{'Bank'} =~ m/^([A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?) ?(.*)/;
	my $bic = $1;
	my $bank = $2 || ' ';  # this space for correct display in OS X QuickLook (?)
	my $holder = $member->{'Ktoinhaber'};
	my $Zahlfremd = $member->{'Zahlfremd'} eq 'Wahr';
	
	$member->{umr} = $umr;
	if ( $mandates{$umr} && $Zahlfremd ) {
		next;  # don't overwrite duplicates unless the new entry is the authoritative one
	}
	$mandates{$umr} = [$signed, $iban, $bic, $holder, $bank];
}

# TODO: match encoding, line breaks and checksum to SKGB-offline format
# (or rather do that in Java)

my $mandate_file = $options{mandate_file};
if ($mandate_file) {
# open(my $fhm, '> :crlf :encoding(windows1252)', $mandate_file) or die "Could not create file '$mandate_file' $!";
	print '"UMR";"Signed";"IBAN";"SWIFT-BIC";"Holder";"updated 2015-07-26 arCwVEd2ZGOAyoMDMvE+2w=="';
	print "\n";
	foreach my $umr (sort keys %mandates) {
		my $row = $mandates{$umr};
		print "\"$umr\"";
		foreach my $col (@$row) {
			print ";\"$col\""
		}
		print "\n";
	}
# close $fhm;
exit 0;
}



# Step 3: Parse pre-existing SKGB-intern user ids and add those to data table

my $intern_ids_file = $options{intern_dir} . '/skgb-ids';

open(my $fhi, '< :encoding(ascii)', $intern_ids_file) or die "Could not open file '$intern_ids_file' $!";
while (my $row = <$fhi>) {
	chomp $row;
	next if $row =~ m/^#/;
	my @row = split m/:/, $row;
	foreach my $member (@members) {
		if ($member->{'Mitnum'} eq $row[1]) {
			$member->{user} = $row[0];
			last;
		}
	}
}
close $fhi;
foreach my $member (@members) {
	if ( ! $member->{user} ) {
#		warn "no user ID found @ " . $member->{'Mitnum'};
	}
}



# Step 4: Parse SEPA status and add that to data table
# skip - SEPA is intern1-only for now
# 
# my $intern_sepa_file = $options{intern_dir} . '/skgb-separun';
# 
# open(my $fhr, '< :encoding(UTF-8)', $intern_sepa_file) or die "Could not open file '$intern_sepa_file' $!";
# while (my $row = <$fhr>) {
# 	chomp $row;
# 	next if $row =~ m/^#/;
# 	my @row = split m/:/, $row;
# 	foreach my $member (@members) {
# 		if ( $row[0] eq $member->{'user'} || $row[0] eq $member->{'Zu2'} || $row[0] eq $member->{'Mitnum'} ) {
# 			$member->{'sepa-next'} = $row[1];
# 			$member->{'sepa-prev'} = $row[2];
# 			last;
# 		}
# 	}
# }
# close $fhr;



# Step 5: Build cypher queries to create the member node
#TODO

#my $cypher_file = $options{cypher_file};

print "BEGIN\n";
print "MATCH (n) DETACH DELETE n;\n";

sub cat_file {
	my $filename = shift;
	open(my $fh, '< :encoding(UTF-8)', $filename) or die "Could not open file '$filename' $!";
	while (my $row = <$fh>) {
		print Encode::encode 'UTF-8', $row unless $row =~ m{^//};
	}
	close $fh;
}

# copy initial role/right configuration
print "\n";
cat_file $options{roles_file};
print "\n";

# 	$mandates{$umr} = [$signed, $iban, $bic, $holder, $bank];
my @mandatesCreate = ();
foreach my $umr (sort keys %mandates) {
	my @mandate = @{$mandates{$umr}};
	my $props = "umr:$umr";
	$props .= ", iban:'" . substr($mandate[1], 0, 4) . "'";
	my $pgp = undef;
	$props .= ", account:'$pgp'" if $pgp;
	push @mandatesCreate, "(mandate$umr:Mandate {$props})";
}
print "CREATE\n", Encode::encode 'UTF-8', shift @mandatesCreate;
while (@mandatesCreate) {
	my $create = shift @mandatesCreate;
	print ",\n", Encode::encode 'UTF-8', $create;
}
print "\n";

sub iso_date {
	my $din_date = shift;
	my $include = shift;
	$include ||= 'ymd';
	$din_date or return $din_date;
	my @q = (undef, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4);
	$din_date =~ m/([0123]?[0-9])\.([01]?[0-9])\.(\d{4})/ or carp 'not a DIN date';
	return sprintf '%04d', $3 if $include eq 'y';
	return sprintf '%04d-Q%1d', $3, $q[0 + "$2"] if $include eq 'yq';
	return sprintf '%04d-%02d', $3, $2 if $include eq 'ym';
	return sprintf '%04d-%02d-%02d', $3, $2, $1;
}

my %addresses = ();
sub new_contact {
	my ($create, $id, $subid, $contact, $type, $kind, $primary, $place) = @_;
	$contact =~ m/^([^\(]+)(?:\s+\((.+)\))?$/ or return undef;
	my $address = $1;
	my $comment = $2;
	my $wrong = $address =~ m/-- falsch/;
	$address =~ s/ ?--? ?falsch($|,)/$1/ig;
	$type ||= $address =~ m/@/ ? 'email' : $address =~ m/^[-+ 0-9]+$/ ? ($address =~ m/Fax/i ? 'fax' : 'phone') : undef;
	my $nodeProps = "address:'$address'";
	$nodeProps .= ", type:'$type'" if $type;
	$nodeProps .= ", comment:'$comment'" if $comment;
	$nodeProps .= ", place:'$place'" if $place && $type && $type eq 'street';
	my $relProps = "";
	$relProps = "kind:'$kind', " if $kind;
	$relProps = "primary:'text', " if $primary && ! $wrong;  # -> label?
	$relProps = "wrong:true, " if $wrong;
	$relProps =~ s/, $//;
	$relProps = " {$relProps}" if $relProps;
	my $key = ($type ? $type : '') . $contact;
	if ($addresses{$address}) {
		my $contactId = $addresses{$address};
		push @$create, "($id)<-[:FOR$relProps]-($contactId)";
		return;
	}
	my $contactId = $id . "_". ++$$subid;
	$addresses{$address} = $contactId;
	push @$create, "($contactId:Address {$nodeProps})-[:FOR$relProps]->($id)";
}

sub length_value {
	my $m = shift;
	$m =~ s/,/./g;
	return $m;
#	return 100 * $m;
}


# copy initial berth configuration
cat_file $options{infra_file};

my %boats = ();
foreach my $member (@members) {
	next if ! $member->{'Zu4'} || $member->{'Zu4'} !~ m/^ja/;
	my $key = $member->{'Zu6'} . ' ' . $member->{'Zu5'} || scalar keys %boats;
	if ($boats{$key}) {
		$member->{boatNode} = $boats{$key}->{node};
		next;
	}
	my $boat = { node => "_" . $member->{'Mitnum'} . "_boat" };
	$member->{boatNode} = $boat->{node};
	$boat->{berth} = $member->{'Zu9'} if $member->{'Zu9'};
	$boat->{berth} = 'Shore' if $boat->{berth} && $boat->{berth} eq 'Jollenwiese';
	
	# Zu5: Name / Unterscheidungszeichen
	my $mark = trim $member->{'Zu5'};
	if ($mark && $mark =~ m|(.*)/(.*)|) {
		my $name = trim $1;
		$boat->{name} = $name if $name ne 'NN' && $name ne '?';
		$mark = trim $2;
	}
	elsif ($mark && $mark !~ m|\d\d| && $mark ne 'NN' && $mark ne '?') {
		$boat->{name} = $mark;
		$mark = undef;
	}
	if ($mark && $mark =~ m|^[A-Z]?\s*\d*$|) {
		$boat->{sailnumber} = $mark;
		$mark = undef;
	}
	if ($mark && $mark =~ m|-|) {
		$boat->{registration} = $mark;
		$mark = undef;
	}
	$boat->{mark} = $mark if $mark && $mark ne 'NN' && $mark ne '?';
	$boat->{mark} = $boat->{name} if $boat->{name};
	$boat->{mark} = $boat->{sailnumber} if ! $boat->{mark} && $boat->{sailnumber};
	$boat->{mark} = $boat->{registration} if ! $boat->{mark} && $boat->{registration};
	$boat->{comment} = $mark if $mark && $boat->{name};
	
	# Zu6: Klasse (BüA/LüA/min-maxTiefe), Kommentar
	my $zu6 = $member->{'Zu6'};
	if ($zu6 && $zu6 =~ m|^([^(),]+)(?: \(([0-9,]+) ?m(?:/([0-9,]+) ?m(?:/(?:([0-9,]+)-)?([0-9,]+) ?m)?)?\))?(?:, ([^()]*))?$|) {
		$boat->{class} = $1 if $1;
		$boat->{width} = length_value $2 if $2;
		$boat->{loa} = length_value $3 if $3;
		$boat->{minDraught} = length_value $4 if $4;
		$boat->{draught} = length_value $5 if $5;
		$boat->{comment} .= ", $6" if $6 && $boat->{comment};
		$boat->{comment} = $6 if $6;
	}
	elsif ($zu6) {
		$boat->{comment} = $zu6;
	}
	
	$boat->{props} = "";
	$boat->{props} .= ", mark:'" . $boat->{mark} . "'" if $boat->{mark};
	$boat->{props} .= ", name:'" . $boat->{name} . "'" if $boat->{name};
	$boat->{props} .= ", sailnumber:'" . $boat->{sailnumber} . "'" if $boat->{sailnumber};
	$boat->{props} .= ", registration:'" . $boat->{registration} . "'" if $boat->{registration};
	$boat->{props} .= ", class:'" . $boat->{class} . "'" if $boat->{class};
	$boat->{props} .= ", width:" . $boat->{width} if $boat->{width};
	$boat->{props} .= ", loa:" . $boat->{loa} if $boat->{loa};
	$boat->{props} .= ", draught:" . $boat->{draught} if $boat->{draught};
	$boat->{props} .= ", minDraught:" . $boat->{minDraught} if $boat->{minDraught};
	$boat->{props} .= ", comment:'" . $boat->{comment} . "'" if $boat->{comment};
	$boat->{props} =~ s/^, //;
	
	$boats{$key} = $boat;
}
my @boatsCreate = ();
foreach my $key (sort {$boats{$a}->{node} cmp $boats{$b}->{node}} keys %boats) {
	my $node = $boats{$key}->{node};
	my $props = $boats{$key}->{props};
	my $berth = $boats{$key}->{berth};
	$berth = 'Shore' if $berth && $berth eq 'Jollenwiese';
	my $berthRel = $berth ? "-[:OCCUPIES]->(berth$berth)" : "";
	push @boatsCreate, "($node:Boat {$props})$berthRel";
}
print "CREATE\n", Encode::encode 'UTF-8', shift @boatsCreate if scalar @boatsCreate;
while (@boatsCreate) {
	my $create = shift @boatsCreate;
	next if ! $create;
	print ",\n", Encode::encode 'UTF-8', $create;
}
print "\n";


foreach my $member (@members) {
	my @create = ();
	my $gsvereinId = $member->{'Mitnum'};
	my $id = "_$gsvereinId";
	my $subid = 0;
	
	# Ausgetretene mit beendeter Geschäftsbeziehung: Sperren!
	next if grep m/^$gsvereinId$/, qw(369 388 376);
	
	# membership data
	my $memberType = $member->{'Abteilung'};
	my $memberLabel = $memberType =~ m/Gastmitglied$/i ? ':GUEST' : ':ROLE';
#	if ($memberType =~ m/Gastmitglied$/i) {
#		push @create, "($id)-[:IS_A]->(guestMember)";
#	}
	my $memberSince = iso_date $member->{'Mitseit'};
	my $memberUntil = iso_date $member->{'Austritt'};
	my $zu15 = $member->{'Zu15'};
	my $regularContributor = $member->{'Aktiv'} && $member->{'Aktiv'} eq 'Wahr';
	my $courses = $member->{'Zu14'};
	my $assemblyFeedback = $member->{'Zu16'};
	my $winterStorage = $member->{'Zu8'} if $member->{'Zu8'} && $member->{'Zu8'} =~ /^ja/;
	my $boat = $member->{boatNode};
	my $memberProps = "";
	$memberProps .= "joined:'$memberSince', " if $memberSince;
	$memberProps .= "leaves:'$memberUntil', " if $memberUntil;
	$memberProps .= "noService:true, " if $zu15 =~ m/kein.* Stegdienst/;
	$memberProps .= "noDuties:true, " if $zu15 =~ m/keine.* Arbeiten/;
	$memberProps .= "noDuties:'$zu15', " if $zu15 =~ m/Arbeiten: Vertretung/;  # TODO: reference
	$memberProps .= "regularContributor:true, " if $regularContributor;
	$courses =~ s/, /','/g if $courses;
	$memberProps .= "courses:['$courses'], " if $courses;
	$memberProps .= "assemblyFeedback:'$assemblyFeedback', " if $assemblyFeedback;  # TODO: reference or not?
	$memberProps .= "winterStorage:'$winterStorage', " if $winterStorage;
	$memberProps =~ s/, $//;
	if ($memberType =~ m/Ehrenmitglied$/i) {
		push @create, "($id)-[$memberLabel {$memberProps}]->(honoraryMember)";
	}
	elsif ($memberType =~ m/^Aktiv/i) {
		push @create, "($id)-[$memberLabel {$memberProps}]->(activeMember)";
	}
	elsif ($memberType =~ m/^Passiv/i) {
		push @create, "($id)-[$memberLabel {$memberProps}]->(passiveMember)";
	}
	elsif ($memberType =~ m/^Jugend/i) {
		push @create, "($id)-[$memberLabel {$memberProps}]->(youthMember)";
	}
	elsif ($memberType !~ m/Nichtmitglied/i) {
		warn "illegal member status type '$memberType'";
		push @create, "($id)-[$memberLabel {$memberProps, memberType:'$memberType'}]->(member)";
	}
	if (my $office = $member->{'Funktion'}) {
		my $node = 'boardMember';
		if ($office eq "Ehrenvorsitzender")   { $node = 'clubHonorary' }
		elsif ($office eq "1. Vorsitzender")  { $node = 'clubPresident' }
		elsif ($office eq "Geschäftsführer")  { $node = 'clubSecretary' }
		elsif ($office eq "Schatzmeister")    { $node = 'clubTreasurer' }
		elsif ($office eq "2. Schatzmeister") { $node = 'clubDeputyTreasurer' }
		elsif ($office eq "Pressewart")       { $node = 'clubPressWarden' }
		elsif ($office eq "1. Steg- & Zeugwart") { $node = 'clubGearWarden' }
		elsif ($office eq "2. Steg- & Zeugwart") { $node = 'clubDeputyGearWarden' }
		elsif ($office eq "1. Sportwart")     { $node = 'clubSportsWarden' }
		elsif ($office eq "2. Sportwart")     { $node = 'clubDeputySportsWarden' }
		elsif ($office eq "1. Jugendwart")    { $node = 'clubYouthWarden' }
		elsif ($office eq "2. Jugendwart")    { $node = 'clubDeputyYouthWarden' }
		push @create, "($id)-[:ROLE]->($node)";
	}
	# TODO: (Austritt), Betreuer, Zu13=Gruppe, {Bemerk}*
	
	# payment data
	$member->{'Debinr'} =~ m/1(\d\d\d)0/ or warn "illegal Debinr";
	my $debitorSerial = "$1";
	$member->{'Gbetrag'} =~ m/^(\d*),(\d*)$/ or warn "illegal Gbetrag";
	my $debitBase = "$1.$2";
	$debitBase =~ s/\.00$//;
	#$debitBase = 0 if $member->{'Zahlart'} ne "Bankeinzug";
	my $debitReason = undef;
	$debitReason = "in Ausbildung" if $member->{'Satz'} =~ m/04|08|09/;
	$debitReason = "Sondervereinbarung" if $member->{'Satz'} =~ m/11/;
	$debitReason = "Eignergemeinschaft" if $member->{'Satz'} =~ m/14/;
	$debitReason = "Aktiv m. Boxen f. 2 Boote (davon 1 Kanu)" if $member->{'Satz'} =~ m/15/;
	my $umr = $member->{umr};
	my $isHolder = index($mandates{$umr}->[3], $member->{'Vorname'}) > -1 && index($mandates{$umr}->[3], $member->{'Name'}) > -1 if $umr;
	$isHolder = 1 if $umr && ($gsvereinId == '045');
	push @create, "($id)<-[:HOLDER]-(mandate$umr)" if $isHolder;
	push @create, "($id)<-[:DEBITOR]-(mandate$umr)" if $umr && $memberType !~ m/Kontoinhaber/i;  # eigentlich müssten wir die Originale checken
	# TODO: Zahlfremd (?)
	
	# personal data
	my $name = $member->{'Vorname'} . ' ' . $member->{'Name'};
	my $degree = $member->{'Titel'};
	my $userid = $member->{user};
	my $gender = $member->{'Geschlecht'};
	my $skills = $member->{'Zu12'};
#	$skills =~ s/!/\\!/;  # database bug in 2.3.2: "[ERROR] Could not expand event" at Olaf Burgmer without this line
	my $personProps = "name:'$name', gsvereinId:'$gsvereinId', gender:'$gender', debitorSerial:'$debitorSerial', debitBase:$debitBase";
#	$personProps .= ", defaultEmail:'all'";
	my $birthday = iso_date($member->{'Geburt'}, ($memberType =~ m/^Jugend/i) ? 'yq' : 'y');
	$personProps .= ", debitReason:'$debitReason'" if $debitReason;
	$personProps .= ", userId:'$userid'" if $userid;
	$personProps .= ", prefix:'$degree'" if $degree;
	$personProps .= ", skills:'$skills'" if $skills;
	$personProps .= ", born:'$birthday'" if $birthday;
	unshift @create, "($id:Person {$personProps})";
	# TODO: (Famstand), (Anrede)
	
	# contact data
	my $email = $member->{'Zu2'};
	new_contact \@create, $id, \$subid, $email, undef, undef, !! $email;
	my $home = $member->{'Strasse'}."\\n".$member->{'Plz'}." ".$member->{'Ort'};
	$home = $member->{'Zusatz'}."\\n".$home if $member->{'Zusatz'};
	new_contact \@create, $id, \$subid, $home, 'street', undef, ! $email, $member->{'Ort'};
	new_contact \@create, $id, \$subid, $member->{'Telefon'}, undef, 'privat';
	new_contact \@create, $id, \$subid, $member->{'Telefon2'}, undef, 'beruflich';
	new_contact \@create, $id, \$subid, $member->{'Zu1'}, undef, 'mobil';
	new_contact \@create, $id, \$subid, $member->{'Telefax'}, 'fax';
	my @zu3 = split m/, ?/, $member->{'Zu3'};
	foreach my $contact (@zu3) {
		new_contact \@create, $id, \$subid, $contact;
	}
	# TODO: (Post), (Branrede)
	
	# belongings
	push @create, "($id)-[:OWNS]->($boat)" if $boat;
	# TODO: Zu11=Schlüssel
	# TODO: Zu9=Box, Zu10=gekauft, Zu4=Boot, Zu5=Name, Zu6=Klasse
	my @keys = ();
	foreach my $zu11 ( split m/ \+ /, $member->{'Zu11'} ) {
		next unless $zu11;
		$zu11 =~ m{^(?:(?:Nr. )?([12])(?:er)?)? ?/ ?(?:([.,0-9]+) ?(DE?M|EUR|Euro))?(?: ?\((.+)\))?$};
		$1 || $2 or warn "illegal Zu11 '$zu11'" and next;
#		my $key = {};
#		$key->{nr} = $1 if $1;
#		$key->{deposit} = $2 if $2;
#		$key->{currency} = $3 if $3;
#		$key->{comment} = $4 if $4;
#		push @keys, $key;
		my $key = "(${id}_" . ++$subid . ":ClubKey" . ( $1 ? " {nr:$1}" : "" ) . ")";
		my @keyProps = ();
		push @keyProps, 'returned:true' if ! $1;
		push @keyProps, "comment:'$4'" if $4;
		if ($2) {
			my ($deposit, $currency) = ($2, $3);
			$deposit =~ s/[.,]00$//;
			$currency =~ s/^DM$/DEM/;
			push @keyProps, "deposit:$deposit", "currency:'$currency'";
		}
		$key .= "<-[:OWNS";
		$key .= " {" . join(", ", @keyProps) . "}" if scalar @keyProps;
		$key .= "]-($id)";
		push @create, $key;
#		$key .= " {deposit:'$2', currency:'$3'" if $2;
#		$key .= ! $2 && ($4 || ! $1) ? " {" : ", ";
#		$key .= "comment:'$3'" if $4;
#		$key .= ($2 || $4) && ! $1 ? ", " : "";
#		$key .= ""
#		print STDERR "$1 $2 $3 $4 '$key'";
	}
#	print STDERR "]";
	
	# software data
#	push @create, "($id)-[:ROLE]->(user)" if $email || $member->{'Zu3'} =~ m/@/;
	push @create, "($id)-[:ROLE]->(admin)" if $member->{'Betreuer'} eq 'IT';
	push @create, "($id)-[:ROLE]->(superUser)" if $member->{'Betreuer'} eq 'IT' && $gsvereinId =~ m/^0/;
	
	print "CREATE\n", Encode::encode 'UTF-8', shift @create;
	while (@create) {
		my $create = shift @create;
		next if ! $create;
		print ",\n", Encode::encode 'UTF-8', $create;
	}
	print "\n";
}


if ($options{dev}) {
	# copy development role/right configuration
	cat_file $options{roles_dev_file};
	print "\n";
}

#print ";\nCOMMIT\n";
print `sed -e '30,54d' -e '1,3d' -e '/^\\/\\//d' -e '/\\[:ROLE.*\\(user\\)/d' "conf/archive/2016-01-01/neuaufnahmen.cypher"`;


# Step 6: Write ALLES.ASC to disc for testing

# if ($options{test}) {
# 	use Try::Tiny;
# 	use REST::Neo4p;
# 	use SKGB::Intern::Model::Person;
# 	
# 	my $test_file0 = 't/J-ALLES0.ASC';
# 	my $test_file1 = 't/J-ALLES1.ASC';
# 	#my $test_format = "> :crlf :encoding(windows1252)";
# 	my $test_format = "> :encoding(UTF-8)";
# 	#my @test_keys = @keys;
# 	my @test_keys = qw( Geburt Mitnum Name Vorname Titel Abteilung Mitseit Austritt Telefon Telefon2 Zu1 Telefax Zu2 Zu3 Plz Ort Strasse Zusatz Debinr Zu9 Zu4 Zu5 Zu6 Zu15 Aktiv Zu14 Zu12 Zu16 Geschlecht Zu8 );
# 	
# 	my $Q = {
# 	  p => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN p LIMIT 1
# QUERY
# 	  Geburt => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN p.born LIMIT 1
# QUERY
# 	  Mitnum => sub { shift->gs_verein_id },
# 	  Name => undef,
# 	  Vorname => undef,
# 	  Titel => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN p.prefix LIMIT 1
# QUERY
# 	  Abteilung => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)--(s:Role)--(m:Role {role:'member'}) WHERE s.role <> 'guest-member' AND s.role <> 'honorary-member' AND p.gsvereinId = {id} RETURN CASE WHEN (p)--(:Role{role:'guest-member'})--(m) THEN s.name+', Gastmitglied' ELSE s.name END AS status
# UNION
# MATCH (p:Person)-[r]-(s:Role {role:'honorary-member'}) WHERE p.gsvereinId = {id} RETURN CASE WHEN r.regularContributor THEN 'Aktiv, '+s.name ELSE 'Passiv, '+s.name END AS status
# UNION
# MATCH (p:Person) WHERE p.gsvereinId = {id} AND NOT (p)--(:Role)--(:Role{role:'member'}) RETURN 'Nichtmitglied' AS status
# QUERY
# 	  Mitseit => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)-[r]-(s:Role)--(:Role {role:'member'}) WHERE s.role <> 'guest-member' AND p.gsvereinId = {id} RETURN r.joined
# QUERY
# 	  Austritt => undef,
# 	  Telefon => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)-[r {type:'privat'}]-(a:Address {type:'phone'}) WHERE p.gsvereinId = {id} RETURN a.address
# QUERY
# 	  Telefon2 => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)-[r {type:'beruflich'}]-(a:Address {type:'phone'}) WHERE p.gsvereinId = {id} RETURN a.address
# QUERY
# 	  Zu1 => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)-[r {type:'mobil'}]-(a:Address {type:'phone'}) WHERE p.gsvereinId = {id} RETURN a.address
# QUERY
# 	  Telefax => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)--(a:Address {type:'fax'}) WHERE p.gsvereinId = {id} RETURN a.address
# QUERY
# 	  Zu2 => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person)-[{primary:true}]-(a:Address {type:'email'}) WHERE p.gsvereinId = {id} RETURN a.address
# QUERY
# 	  Zu3 => undef,
# 	  Plz => undef,
# 	  Ort => undef,
# 	  Strasse => undef,
# 	  Zusatz => undef,
# 	  Debinr => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN '1'+p.debitorSerial+'0' LIMIT 1
# QUERY
# 	  Zu9 => undef,
# 	  Zu4 => undef,
# 	  Zu5 => undef,
# 	  Zu6 => undef,
# 	  Zu15 => undef,
# 	  Aktiv => undef,
# 	  Zu14 => undef,
# 	  Zu12 => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN p.skills LIMIT 1
# QUERY
# 	  Zu16 => undef,
# 	  Geschlecht => REST::Neo4p::Query->new(<<QUERY),
# MATCH (p:Person) WHERE p.gsvereinId = {id} RETURN p.gender LIMIT 1
# QUERY
# 	  Zu8 => undef,
# 	};
# 	
# 	open(my $fht0, $test_format, $test_file0) or die "Could not open file '$test_file0' $!";
# 	print $fht0 join ("\t", @test_keys), "\n";
# 	foreach my $member (@members) {
# 		my @row = ();
# 		foreach my $key (@test_keys) {
# 			if ($key eq 'Mitseit') { push @row, iso_date $member->{$key}; next; }
# 			push @row, $member->{$key} || '';
# 		}
# 		print $fht0 join("\t", @row), "\n";
# 	}
# 	close $fht0;
# 	
# 	# initiate DB connection
# 	try {
# 		REST::Neo4p->connect('http://127.0.0.1:7474', 'neo4j', 'pass');
# 	} catch {
# 		ref $_ ? $_->can('rethrow') && $_->rethrow || die $_->message : die $_;
# 	};
# 	
# 	sub execute {  # execute_memory
# 		my ($query, $limit, @params) = @_;  $limit ||= 1;
# 		$query->execute(@params);
# 		my @rows = ();
# 		while ( $limit-- && (my $row = $query->fetch) ) {
# 			push @rows, $row;
# 		}
# 		$query->finish;
# 		return wantarray ? @rows : $rows[0];
# 	}
# 	
# 	open(my $fht1, $test_format, $test_file1) or die "Could not open file '$test_file1' $!";
# 	print $fht1 join "\t", @test_keys;
# 	print $fht1 "\n";
# 	foreach my $member (@members) {
# 		my @row = ();
# 		foreach my $key (@test_keys) {
# 			my $q = $Q->{$key};
# 			if (! $q) {
# 				push @row, 'undef';
# 			}
# 			elsif (ref $q eq "REST::Neo4p::Query") {
# 				my $r = execute($q , 1, (id => $member->{'Mitnum'}));
# 				# possibly REST/Neo4p/Query.pm:120 must read JSON::XS->new->utf8; to make this work without extra decoding
# 				$r = $r ? $r->[0] || '' : '';
# 				$r = Encode::decode("utf8", $r );
# #				Encode::_utf8_on($r);  # doesn't have any effect
# #				say STDERR utf8::is_utf8($r) . " $key $r" if $r;
# 				push @row, $r;
# 			}
# 			elsif (ref $q eq "CODE") {
# 				my $r = execute($Q->{p}, 1, (id => $member->{'Mitnum'}) );
# 				if ($r) {
# 					my $p = SKGB::Intern::Model::Person->new($r->[0]);
# 					push @row, $q->($p) || '';
# 				}
# 				else {
# 					push @row, '';
# 				}
# 			}
# 			else {
# 				die 'WTF';
# 			}
# 		}
# 		print $fht1 join("\t", @row), "\n";
# 	}
# 	close $fht1;
# }








	#my $email = $member->{'Zu2'};
	#push @create, "(${id}_".++$subid.":Address {type:'email', address:'$email'})-[:FOR {primary:true}]->($id)" if $email;
	#push @create, "(${id}_".++$subid.":Address {type:'street', address:'$home'})-[:FOR {type:'privat'}]->($id)";
	#my $phone1 = $member->{'Telefon'};
	#push @create, "(${id}_".++$subid.":Address {type:'phone', address:'$phone1'})-[:FOR {type:'privat'}]->($id)" if $phone1;
	#my $phone2 = $member->{'Telefon2'};
	#push @create, "(${id}_".++$subid.":Address {type:'phone', address:'$phone2'})-[:FOR {type:'beruflich'}]->($id)" if $phone2;
	#$member->{'Zu1'} =~ m/^(.*)(?: \((.*)\))?$/;
	#my $phone3 = $1;
	#my $phone3Comment = $2 ? ", comment:'$2'" : "";
	#push @create, "(${id}_".++$subid.":Address {type:'phone', address:'$phone3'})-[:FOR {type:'mobil'$phone3Comment}]->($id)" if $phone3;
	#my $fax = $member->{'Telefax'};
	#push @create, "(${id}_".++$subid.":Address {type:'fax', address:'$fax'})-[:FOR]->($id)" if $fax;










#say Data::Dumper::Dumper(\@members);


exit 0;

__END__


// DSV-Queries:

// Jugendliche männlich
MATCH (r:Role{role:'youth-member'})<-[m]-(p:Person) WHERE r.role <> 'guest-member' AND (NOT has(m.leaves) OR m.leaves >= '2016') AND p.gender = 'M' RETURN m

// Erwachsene weiblich
MATCH (:Role{role:'member'})<--(r:Role)<-[m]-(p:Person), (j:Role{role:'youth-member'}) WHERE NOT (j)<--(p) AND r.role <> 'guest-member' AND (NOT has(m.leaves) OR m.leaves >= '2016') AND p.gender = 'W' RETURN m

// Boote ohne Liegeplatz
MATCH (b:Boat)--(p:Person)--(r:Role) WHERE NOT (b)--(:Berth) AND r.role IN ['honorary-member','active-member','passive-member'] RETURN b,p,r

// Aktive mit Stegdienst
MATCH (p:Person)-[r]-(m:Role) WHERE (NOT has(r.noStegdienst) OR NOT r.noStegdienst) AND m.role IN ['active-member'] RETURN p,r ORDER BY p.gsvereinId














exit 0;

1;

__END__

=pod

=head1 NAME

import.pl - convert a GS-Verein 'ALLES' export to Neo4j cypher code

=head1 SYNOPSIS

 import.pl ALLES.ASC > ALLES.cypher
 import.pl -d ALLES.ASC | neo4j-shell
 import.pl -m ALLES.ASC > Mandatssammlung.csv
 import.pl --help|--version|--man

=head1 AUTHOR

Arne Johannessen, L<mailto:arne@thaw.de>

=head1 COPYRIGHT

Copyright (c) 2015-2016 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
