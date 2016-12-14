package SKGB::Intern::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use POSIX qw();
use REST::Neo4p;

use Data::Dumper;

my $TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ';

my $Q = {
  codelist => <<END,
MATCH (c:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)
 RETURN c, p
 UNION
 MATCH (c:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)<-[:IDENTIFIES]-(a:AccessCode)
 RETURN a AS c, p
 ORDER BY c.creation DESC
END
  codelist_all_debug => <<END,
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 RETURN c, p
 ORDER BY c.creation DESC
END
  code => <<END,
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 WHERE c.code = {code}
 RETURN c,p
END
};


# sub list {
# 	my ($self) = @_;
# 	
# 	my @codes = ();
# 	my @rows = $self->neo4j->execute_memory($Q->{codelist}, 1000, (code => $self->session('key')));
# 	foreach my $row (@rows) {
# 		push @codes, $self->_code( $row->[0] );
# 	}
# 	@codes = sort {$b->{creation} cmp $a->{creation}} @codes;
# 	
# 	my $user = $self->skgb->session->user;
# 	return $self->render(template => 'key_manager/codelist', logged_in => $user, codes => \@codes);
# }
# 
# 
# sub tree {
# 	my ($self) = @_;
# 	
# 	my $row = $self->neo4j->execute_memory($Q->{code}, 1000, (code => $self->stash('code')));
# 	my @codes = ( $self->_code( $row->[0] ) );
# 	$row->[1]->id eq $self->skgb->session->user->node_id or die 'not authorized';
# 	
# 	my $user = $self->skgb->session->user;
# 	return $self->render(template => 'key_manager/authtree', logged_in => $user, codes => \@codes);
# }


sub auth {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	if ( ! $user ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	return $self->_tree($user) if $self->stash('code');
	
	my $template = 'key_manager/codelist';
	my $param = $self->session('key');
	my $query = $Q->{codelist};
	$query = $Q->{codelist_all_debug} if defined $self->param('all');  # debug
	
	my @codes = ();
# 	my @rows = $self->neo4j->execute_memory($query, 1000, (code => $param));
# 	foreach my $row (@rows) {
# #		push @codes, $self->_code( $row->[0], $user );
# #		$row->[1]->id eq $user->node_id or die 'not authorized';  # assertion
# 		push @codes, $self->_code( $row->[0], SKGB::Intern::Model::Person->new($row->[1]) );  # debug
# 	}
# 	@codes = sort {$b->{creation} cmp $a->{creation}} @codes;
	my @rows = $self->neo4j->session->run($query, code => $param);
	say Data::Dumper::Dumper \@rows;
	foreach my $row (@rows) {
		push @codes, $self->_code( $row, SKGB::Intern::Model::Person->new($row->get(1)) );
#		$row->[1]->id eq $user->node_id or die 'not authorized';  # assertion
#		push @codes, $self->_code( $row->[0], SKGB::Intern::Model::Person->new($row->[1]) );  # debug
	}
	@codes = sort {$b->{creation} cmp $a->{creation}} @codes;
	
	return $self->render(template => $template, logged_in => $user, codes => \@codes);
}


sub _code {
	my ($self, $node, $for) = @_;
	my $code = $node->get('c');
	$code->{this_session} = 1 if $code->{code} eq $self->session('key');
	$code->{expiration} = POSIX::strftime($TIME_FORMAT, gmtime( DateTime::Format::ISO8601->parse_datetime($code->{creation})->epoch() + $self->config->{ttl}->{key} ));
	$code->{this_expired} = POSIX::strftime($TIME_FORMAT, gmtime( time )) gt $code->{expiration};
	$code->{for} = $for if $for;
#	$code->{this_expired} = $self->skgb->session->key_expired($node);
	return $code;
}


sub _tree {
	my ($self, $user) = @_;
	
	my $param = $self->stash('code');
	
	my $code = $self->neo4j->session->run($Q->{code}, code => $param)->single;
#	say Data::Dumper::Dumper $code;
	$code or die;
	my @codes = ($self->_code( $code, SKGB::Intern::Model::Person->new($code->get(1)) ));
	
	my @roles;
# 	my @roles = $self->neo4j->session->run(<<_, code => $param);
# MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[:IS_A|IS_A_GUEST|:ROLE*..2]->(r:Role)
# WHERE c.code = {code}
# RETURN r, not((p)--(r)) AS indirect, false AS special, false AS negated
# ORDER BY r.name, r.role
# UNION
# MATCH (c:AccessCode)-[:ROLE*..2]->(r:Role)
# WHERE c.code = {code}
# RETURN r, not((c)--(r)) AS indirect, true AS special, false AS negated
# ORDER BY r.name, r.role
# _
# 	foreach my $negation ( $self->neo4j->session->run(<<_, code => $param) ) {
# MATCH (c:AccessCode)-[a:IS_A|IS_A_GUEST|:ROLE*..2]->(r:Role)
# WHERE c.code = {code} AND type(head(a)) = 'NOT'
# RETURN r.role
# _
# 		foreach my $role (@roles) {
# 			$role->get('negated')
# 		}
# 	}
# 	my @negations = $self->neo4j->session->run(<<_, code => $param);
# MATCH (c:AccessCode)-[a:IS_A|IS_A_GUEST|:ROLE*..2]->(r:Role)
# WHERE c.code = {code} AND type(head(a)) = 'NOT'
# RETURN r.role
# _
	my %role_negation = map { $_->get => 1 } $self->neo4j->session->run(<<_, code => $param);
MATCH (c:AccessCode)-[a:GUEST|ROLE|NOT*..3]->(r:Role)
WHERE c.code = {code} AND type(head(a)) = 'NOT'
RETURN r.role
_
	foreach my $role ( $self->neo4j->session->run(<<_, code => $param) ) {
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[:GUEST|ROLE*..3]->(r:Role)
WHERE c.code = {code}
RETURN r, not((p)--(r)) AS indirect, false AS special
ORDER BY r.name, r.role
UNION
MATCH (c:AccessCode)-[:ROLE*..3]->(r:Role)
WHERE c.code = {code}
RETURN r, not((c)--(r)) AS indirect, true AS special
ORDER BY r.name, r.role
_
		push @roles, {
			role => $role->get(0),
			indirect => $role->get('indirect'),
			special => $role->get('special'),
			negated => $role_negation{$role->get(0)->{role}},
		};
	}
#	say Data::Dumper::Dumper \@roles;
#	say Data::Dumper::Dumper \%role_negation;
	
	my @privs;
	my %priv_negation = map { $_->get => 1 } $self->neo4j->session->run(<<_, code => $param);
MATCH (c:AccessCode)-[a:GUEST|ROLE|NOT|MAY|ACCESS*..4]->(s:Right)
WHERE c.code = {code} AND type(head(a)) = 'NOT'
RETURN s.right
_
	foreach my $priv ( $self->neo4j->session->run(<<_, code => $param) ) {
MATCH (c:AccessCode)-[:IDENTIFIES]->(:Person)-[:GUEST|ROLE*..3]->(r:Role)
WHERE c.code = {code}
MATCH (r)-[:MAY|ACCESS]->(s)
WHERE (s:Right) OR (s:Resource)
RETURN s, false AS special, (s:Right) AS new
ORDER BY s.name, s.right
UNION
MATCH (c:AccessCode)-[:GUEST|ROLE*..3]->(r:Role)
WHERE c.code = {code}
MATCH (r)-[:MAY]->(s)
WHERE (s:Right)
RETURN s, true AS special, true AS new
ORDER BY s.name, s.right
_
		push @privs, {
			priv => $priv->get(0),
			special => $priv->get('special'),
			new => $priv->get('new'),
			negated => $priv->get(0)->{right} ? $priv_negation{$priv->get(0)->{right}} : undef,
		};
	}
#	say Data::Dumper::Dumper \@privs;
#	say Data::Dumper::Dumper \%priv_negation;
	
#	my @p = ($self->skgb->may('adsd'),$self->skgb->may('member-profile'));
#	say Data::Dumper::Dumper \@p;
	
	return $self->render(template => 'key_manager/authtree', logged_in => $user, codes => \@codes, roles => \@roles, privs => \@privs);
}



1;


__END__

Grundsatz:
- Per E-Mail verschickte AccessCodes gelten als unsicher dürfen nur sehr kurz gelten, denn E-Mail-Accounts der Nutzer sind unsicher.
- Sichere Sessions (für Vorstand) erfordern mindestens, dass der Session Key niemals unsicher übertragen wurde.

Geltungsdauer:
- vor erstem Login: ausreichend lange, um Greylisting abzudecken (Key-Gültigkeit, gilt NEU nur noch für ungenutzte Keys)
- nach erstem Login: nur noch Timeout seit letzter Aktivität; ausreichend lange, um leute nicht zu verärgern, die zwischendurch kaffe trinken gehen oder so
- Power User können die Gültigkeit des eigenen Timeouts in gewissen Grenzen verändern (nicht so kurz, dass die Software absolut unbedienbar wird, und nicht so exzessiv lang, dass sie total unsicher wird), deshalb default-wert eher zu kurz als zu lang(?)
- länger gültige Keys und längere Timeouts nur für Keys, die niemals per E-Mail verschickt worden sind; Vorgehen: sicheren Key für sich selbst erzeugen lassen im Auth-Manager, den dann z. B. ins Login-Feld pasten und dann liegt er im sicheren Cookie;
- letzteres Konzept sollte sich automatisieren lassen und wäre dann theoretisch auch schon mit inem einzelnen Klick möglich auf einen Knopf "sichere Session erzeugen"; jeder User sollte immer nur eine einzige sichere Session gleichzeitig haben, eine neue ersetzt die alte und mit einem einzelnen (unsicheren) Key kann immer nur höchstens eine sichere Session erzeugt werden (sichere Keys erlauben es nicht, sichere Sessions zu erzeugen)
- Gültigkeit lange (Monate/Jahre), jedoch falls bekannt nicht länger als bis nach den nächsten ordentlichen Vorstandswahlen(?)
- Power User können die Gültigkeit verkürzen(?) oder das Erzeugen neuer sicherer Sessions für sich selbst verbieten (nur sinnvoll, wenn der Session Key z.B. im Password Safe notiert wird)
- (Alternative für sichere Sessions wäre, dass diese nur manuell erzeugt/freigeschaltet werden können. Wäre noch sicherer, aber hohen Support-Aufwand, was schlecht für alle wäre. Diskutieren!)
- (evtl. sichere Session für Datenbank nur manuell, aber "speichern" des Logins per einfachem Klick möglich)
