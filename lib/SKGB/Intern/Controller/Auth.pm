package SKGB::Intern::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use POSIX qw();
use REST::Neo4p;

use SKGB::Intern::AccessCode;

use Data::Dumper;

my $TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ';

my $Q = {
  codelist => <<END,
MATCH (c:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)
 RETURN c, p, id(c) as id
 UNION
 MATCH (:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)<-[:IDENTIFIES]-(a:AccessCode)
 RETURN a AS c, p, id(a) as id
 ORDER BY c.creation DESC
END
  codelist_all_debug => <<END,
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 RETURN c, p, id(c) as id
 ORDER BY c.creation DESC
END
  code => <<END,
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 WHERE id(c) = {code}
 RETURN c,p
END
};


sub auth {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	if ( ! $user ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	return $self->_tree if $self->param('node');
	
	my $template = 'key_manager/codelist';
	my $param = $self->session('key');
	my $query = $Q->{codelist};
	$query = $Q->{codelist_all_debug} if defined $self->param('all');  # debug
	
	my @codes = ();
	my @rows = $self->neo4j->get_persons($query, code => $param);
#	say Data::Dumper::Dumper \@rows;
	foreach my $row (@rows) {
		my $code = SKGB::Intern::AccessCode->new(
			code => $row->get('c'),
			user => $row->get('person'),
			app => $self->app,
		);
		$code->{id} = $row->get('id');
		push @codes, $code;
#		$row->[1]->id eq $user->node_id or die 'not authorized';  # assertion
	}
	@codes = sort {$b->creation cmp $a->creation} @codes;
	
	return $self->render(template => $template, logged_in => $user, codes => \@codes);
}


sub _may_modify_role {
	my ($self, $code) = @_;
	# despite the name this condition is currently only valid for deletion, not for addition!
	return $code && ! $code->session_expired && ($code->user->equals($self->skgb->session->user) || $self->skgb->may('sudo'));
}


sub _modify_roles {
	my ($self, $code) = @_;
	
	if (! $self->_may_modify_role($code)) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	foreach my $role ( @{$self->req->params->names} ) {
		if ($role =~ m/^delete=(.+)$/) {
			$self->neo4j->session->run(<<_, code => "$code", role => $1);
MATCH (c:AccessCode), (r:Role)
WHERE c.code = {code} AND r.role = {role}
CREATE (c)-[:NOT]->(r)
_
		}
		elsif ($role =~ m/^sudo=reset$/) {
			my $t = $self->neo4j->session->run(<<_, code => "$code");
MATCH (c:AccessCode)-[d:NOT|ROLE]->()
WHERE c.code = {code}
DELETE d
_
		}
		elsif ($role =~ m/^sudo=all-roles$/) {
			my $t = $self->neo4j->session->begin_transaction;
			$t->run(<<_, code => "$code");
MATCH (c:AccessCode)-[d:NOT|ROLE]->()
WHERE c.code = {code}
DELETE d
_
			$t->run(<<_, code => "$code");
MATCH (a:AccessCode), (r:Role)
WHERE a.code = {code}
CREATE (a)-[:ROLE]->(r)
_
			$t->commit;
		}
	}
	$self->redirect_to( $self->url_for('auth')->query(node => $code->{id}) );
}


sub _tree {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	my $param = 0 + $self->param('node');
	
	my ($code, @codes) = $self->neo4j->get_persons($Q->{code}, code => $param);
#	say Data::Dumper::Dumper $code;
	$code and not @codes or die;
	@codes = ( SKGB::Intern::AccessCode->new(
		code => $code->get('c'),
		user => $code->get('person'),
		app => $self->app,
	));
	$codes[0]->{id} = $param;
	
	return $self->_modify_roles($codes[0]) if $self->param('action') && $self->param('action') eq 'modify-roles';
	
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
WHERE id(c) = {code} AND type(head(a)) = 'NOT'
RETURN r.role
_
	foreach my $role ( $self->neo4j->session->run(<<_, code => $param) ) {
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[:GUEST|ROLE*..3]->(r:Role)
WHERE id(c) = {code}
RETURN r, not((p)--(r)) AS indirect, false AS special
ORDER BY r.name, r.role
UNION
MATCH (c:AccessCode)-[:ROLE*..3]->(r:Role)
WHERE id(c) = {code}
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
WHERE id(c) = {code} AND type(head(a)) = 'NOT'
RETURN s.right
_
	foreach my $priv ( $self->neo4j->session->run(<<_, code => $param) ) {
MATCH (c:AccessCode)-[:IDENTIFIES]->(:Person)-[:GUEST|ROLE*..3]->(r:Role)
WHERE id(c) = {code}
MATCH (r)-[:MAY|ACCESS]->(s)
WHERE (s:Right) OR (s:Resource)
RETURN s, false AS special, (s:Right) AS new
ORDER BY s.name, s.right
UNION
MATCH (c:AccessCode)-[:GUEST|ROLE*..3]->(r:Role)
WHERE id(c) = {code}
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
