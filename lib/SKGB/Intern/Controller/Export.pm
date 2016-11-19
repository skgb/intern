package SKGB::Intern::Controller::Export;
use Mojo::Base 'Mojolicious::Controller';

use utf8;
use REST::Neo4p;
use SKGB::Intern::Model::Person;


my $Q = {
#   export => REST::Neo4p::Query->new(<<QUERY),
# OPTIONAL MATCH (p:Person), (p)-[r]-(s:Role)--(:Role{role:'member'})
# WHERE s.role <> 'guest-member'
# RETURN p, s, r
# ORDER BY p.gsvereinId
# QUERY
  sepa => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)--(:Mandate)
 RETURN DISTINCT p
 ORDER BY p.gsvereinId, p.born, p.debitorSerial, p.name
 UNION
 MATCH (p:Person)-[m]-(:Role)--(:Role{role:'member'})
 WHERE NOT ((p)--(:Mandate))
 RETURN p
 ORDER BY p.gsvereinId, p.debitorSerial, p.name
//WHERE has(p.gsvereinId)
QUERY
  listen => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[r]-(s:Role)-[m]-(:Role{role:'member'})
 WHERE s.role <> 'guest-member'
 RETURN p, s, r, m
 ORDER BY p.gsvereinId
QUERY
};


sub intern1 {
	my ($self) = @_;
	
	if ( ! $self->skgb->may ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user, export => $self->_intern1());
}


sub listen {
	my ($self) = @_;
	
	if ( ! $self->skgb->may ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user, listen => $self->_listen());
}


sub _intern1 {
	my ($self) = @_;
	
	my @header = qw(Name Vorname Mitnum Zu2 Abteilung Gbetrag Zu7 Zahlfremd Zahlart Ktonr);
	my @export = ();
	
	my (undef, undef, undef, $targetDay, $targetMonth, $targetYear, undef, undef, undef) = localtime;
	my $targetDate = sprintf("%04d-%02d-%02d", $targetYear + 1900, $targetMonth + 1, $targetDay);
	
#	my %years = ();
	$Q->{sepa}->execute();
	ROW: while ( my $result = $Q->{sepa}->fetch ) {
		my ($p) = @$result;
		$p = SKGB::Intern::Model::Person->new($p);
		my @rels_o = $p->{_node}->get_outgoing_relationships();
		my @rels_i = $p->{_node}->get_incoming_relationships();
		my @row = ();
		
		# name
#		print Encode::encode('UTF-8', $p->name_part(1)), "\t";
#		print Encode::encode('UTF-8', $p->name_part(0)), "\t";
		my $nachname = $p->name_part(1);
		$nachname =~ s/ć/c´/;
		push @row, "$nachname";
		push @row, $p->name_part(0);
		push @row, $p->gs_verein_id || "";
		
#		next unless ! $p->gs_verein_id || $p->gs_verein_id eq '509';
		
		# email
#		my @emails = $p->primary_emails;  # falls back to non-primary if no primaries are found, but we want ONLY primaries here!
		my @emails = ();
		foreach my $rel (@rels_i) {
			next if $rel->type ne 'FOR';
			next if ! $rel->get_property('primary');
			my $start_node = $rel->start_node;
			next if $start_node->get_property('type') ne 'email';
			my $email = $start_node->get_property('address');
			push @emails, $email if $email;
		}
		my $email = join ',',  @emails;
		push @row, $email;
		
		# get mandate
		my %mandate = ();
		my $Zahlfremd = 1;
		foreach my $rel (@rels_i) {
			$Zahlfremd = undef if $rel->type eq 'HOLDER';
			next if $rel->type ne 'DEBITOR' && $rel->type ne 'HOLDER';
			my $start_node = $rel->start_node;
			my $umr = $start_node->get_property('umr');
			next if $mandate{umr} && $mandate{umr} ge $umr;
#			die "person with two different mandates not implemented" if $mandate{umr};
			$mandate{umr} = $umr;
			$mandate{iban} = $start_node->get_property('iban');
		}
		$Zahlfremd = 1 if $p->gs_verein_id() && $p->gs_verein_id() eq '001' && $mandate{umr} && $mandate{umr} eq '20021';
		
		my $Gbetrag = sprintf "%.2f", $p->_property('debitBase') || 0;
		$Gbetrag =~ s/\./,/;
		
		# Abteilung
		my $status;
		my $isGuest;
		my $Abteilung;
		foreach my $t (@rels_o) {
			$status = $t->end_node->get_property('role');
			next if ! $status;
			$isGuest ||= 1 if $t->type eq 'IS_A_GUEST';
			if ($t->get_property('leaves') && $t->get_property('leaves') lt $targetDate || $t->get_property('joined') && $t->get_property('joined') gt $targetDate) {
				$Abteilung = 'Nichtmitglied';
				# these members would exist in a simple GS-Verein export, but we
				# want to emulate the GS-Verein "Ausgetretene ausblenden" option here
				next ROW;
			}
			elsif ($status eq 'active-member') {
				$Abteilung = 'Aktiv';
			}
			elsif ($status eq 'passive-member') {
				$Abteilung = 'Passiv';
			}
			elsif ($status eq 'youth-member') {
				$Abteilung = 'Jugend';
			}
			elsif ($status eq 'honorary-member') {
				if ($t->get_property('regularContributor')) {
					$Abteilung = 'Aktiv, Ehrenmitglied';
				}
				else {
					$Abteilung = 'Passiv, Ehrenmitglied';
				}
			}
			else {
				$isGuest ||= 1 if $status eq 'guest-member';
				$status = undef;
				next;
			}
			last;
		}
		if (! $status) {
			if ($mandate{umr} && $Gbetrag eq "0,00") {
				$Abteilung = "Nichtmitglied, Kontoinhaber";
			}
			else {
				$Abteilung = "Nichtmitglied";
				# Aus GS-Verein-Perspektive sollten diese Personen enthalten
				# sein (Beispiel: Angler). Aus Neo4j-Perspektive jedoch nicht,
				# denn hier existieren Nichtmitglieder weiter, wenn es Grund
				# dazu gibt, sie nicht zu löschen (z. B. nicht zurückgegebener
				# Vereinsschlüssel). Die sollten dann aber nicht nach intern1
				# exportiert werden, sonst bekommen sie wieder E-Mails! Also
				# müssen Fälle wie die Angler baw. anders implementiert werden.
				# (Zu berücksichtigen wäre dabei, dass die Angler in den SEPA-
				# Diensten von 1.3 als Mitglieder gezählt würden.)
				# Derzeit gibt es solche Fälle aber zum Glück nicht.
				next ROW;
			}
		}
		$Abteilung .= ", Gastmitglied" if $isGuest;
		push @row, "$Abteilung";
		push @row, "$Gbetrag";
		
		push @row, %mandate ? $mandate{umr} : "";
		push @row, $Zahlfremd || ! $status ? "Wahr" : "Falsch";
		push @row, %mandate && $status ? "Bankeinzug" : ($Gbetrag eq "0,00" ? "" : "Überweisung");
		push @row, %mandate ? $mandate{iban} : "";
		
		if (! $status && $mandate{umr}) {
			# check if mandates with multiple holders exist and merge those
			# (they are not supported by intern1)
			foreach my $other (@export) {
				next if ! $other->[6] || $other->[6] ne $mandate{umr};
				next if $other->[4] ne 'Nichtmitglied, Kontoinhaber';
				if ($email && $other->[3] && $other->[3] ne $email) {
#					$other->[3] .= ",$email";  # may not be supported by intern1
					warn "unterschiedliche E-Mail-Adressen für Kontoinhaber";
				}
				$other->[0] .= " und " . $p->name;
				$other->[2] = '';  # no longer unambiguous
				next ROW;
			}
		}
		
		push @export, \@row;
	}
	$Q->{sepa}->finish;
	
	@export = sort {($a->[2] || 'last') cmp ($b->[2] || 'last') || $a->[6] cmp $b->[6]} @export;
	unshift @export, \@header;
	
	# empty or non-numeric ids are not currently supported by intern1, so let's fake some numeric ones
#	my $fakeid = 0;
	foreach my $row (@export) {
		next if $row->[2];
#		$row->[2] = '999' . ++$fakeid;
		$row->[2] = '9' . substr $row->[6], 1, 3;
	}
	
	return \@export;
}


sub _listen {
	my ($self) = @_;
	
#	my @header = qw(Mitnum Name Titel Vorname Abteilung Zu16 Zu15 Zu2 Telefon Telefon2 Ort Zu12 Mitseit Austritt Zahlart Satz Gbetrag Aktiv Zu11 Zu1 Telefax Zu3);
	my @header = qw(Mitnum Name Titel Vorname Abteilung Zu16 Zu15 Zu2 Telefon Telefon2 Ort Zu12);
	my @export = ();
	
	my (undef, undef, undef, $targetDay, $targetMonth, $targetYear, undef, undef, undef) = localtime;
	my $targetDate = sprintf("%04d-%02d-%02d", $targetYear + 1900, $targetMonth + 1, $targetDay);
	
#	my %years = ();
	$Q->{listen}->execute();
	ROW: while ( my $row = $Q->{listen}->fetch ) {
		my ($p, undef, $r, $m) = @$row;
		if ($r->get_property('leaves') && $r->get_property('leaves') lt $targetDate || $r->get_property('joined') && $r->get_property('joined') gt $targetDate) {
			next;
		}
		$p = SKGB::Intern::Model::Person->new($p);
		
		my @rels_o = $p->{_node}->get_outgoing_relationships();
		my @rels_i = $p->{_node}->get_incoming_relationships();
		my @row = ();
		
		# name
		push @row, $p->gs_verein_id || "";
		push @row, $p->name_part(1);
		push @row, $p->_property('prefix');
		push @row, $p->name_part(0);
		
		# Abteilung
		my $status;
		my $isGuest;
		my $Abteilung;
		foreach my $t (@rels_o) {
			$status = $t->end_node->get_property('role');
			next if ! $status;
			$isGuest ||= 1 if $t->type eq 'IS_A_GUEST';
			if ($t->get_property('leaves') && $t->get_property('leaves') lt $targetDate || $t->get_property('joined') && $t->get_property('joined') gt $targetDate) {
				$Abteilung = 'Nichtmitglied';
				# these members would exist in a simple GS-Verein export, but we
				# want to emulate the GS-Verein "Ausgetretene ausblenden" option here
				next ROW;
			}
			elsif ($status eq 'active-member') {
				$Abteilung = 'Aktiv';
			}
			elsif ($status eq 'passive-member') {
				$Abteilung = 'Passiv';
			}
			elsif ($status eq 'youth-member') {
				$Abteilung = 'Jugend';
			}
			elsif ($status eq 'honorary-member') {
				if ($t->get_property('regularContributor')) {
					$Abteilung = 'Aktiv, Ehrenmitglied';
				}
				else {
					$Abteilung = 'Passiv, Ehrenmitglied';
				}
			}
			else {
				$isGuest ||= 1 if $status eq 'guest-member';
				$status = undef;
				next;
			}
			last;
		}
		if (! $status) {
			$Abteilung = "Nichtmitglied";
			next ROW;
		}
		$Abteilung .= ", Gastmitglied" if $isGuest;
		push @row, "$Abteilung";
		
		# Bemerkungen
		push @row, $r->get_property('assemblyFeedback');
		my @noDutiesServices = ();
		push @noDutiesServices, "kein Stegdienst" if $r->get_property('noService') || $m->get_property('noService');
		push @noDutiesServices, "keine Arbeiten" if $r->get_property('noDuties') || $m->get_property('noDuties');
		push @row, join ", ", @noDutiesServices;  # Zu15
		
		# Kontaktdaten
		my @emails = ();
		my @places = ();
		my $Telefon;
		my $Telefon2;
		my $Zu1;
		foreach my $rel (@rels_i) {
			next if $rel->type ne 'FOR';
			my $start_node = $rel->start_node->as_simple;
			next if ! $start_node->{type};  # Campingwagen hat bis jetzt keinen Type
			if ( $start_node->{type} eq 'email' && $rel->get_property('primary') ) {
				my $email = $start_node->{address};
				push @emails, $email if $email;
			}
			elsif ( $start_node->{type} eq 'street' ) {
				my $place = $start_node->{place};
				push @places, $place if $place && ! grep /^$place$/, @places;
			}
			elsif ( $start_node->{type} eq 'phone' && $start_node->{address}) {
				my $kind = $rel->get_property('kind');
				if ($kind && $kind eq 'privat') {
					$Telefon = $start_node->{address};
				}
				elsif ($kind && $kind eq 'beruflich') {
					$Telefon2 = $start_node->{address};
				}
				elsif ($kind && $kind eq 'mobil') {
					$Zu1 = $start_node->{address};
				}
			}
		}
		my $email = join ',',  @emails;
		if ($email && $p->legacy_user) {
			$email = $p->legacy_user . '@skgb.de';
		}
		my $place = join ', ',  @places;
		push @row, $email;
		push @row, $Telefon || $Zu1;
		push @row, $Telefon2;
		push @row, $place;
		
		# Beruf/Branche
		push @row, $p->_property('skills');
		
		push @export, \@row;
	}
	$Q->{listen}->finish;
	
	@export = sort {($a->[0] || 'last') cmp ($b->[0] || 'last') || $a->[1] cmp $b->[1] || $a->[3] cmp $b->[3]} @export;
	unshift @export, \@header;
	
	return \@export;
}


1;
