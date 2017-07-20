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
	return $self->reply->forbidden unless $user;
	
	return $self->_tree if $self->stash('entity');
	
	my $template = 'key_manager/codelist';
	my $param = $self->session('key');
	my $query = $Q->{codelist};
	$query = $Q->{codelist_all_debug} if defined $self->param('all');  # debug
	
	my @codes = ();
	my @rows = $self->neo4j->get_persons($query, code => $param);
#	say Data::Dumper::Dumper \@rows;
	foreach my $row (@rows) {
		push @codes, SKGB::Intern::AccessCode->new(
			code => $row->get('c'),
			user => $row->get('person'),
			id => $row->get('id'),
			app => $self->app,
		);
#		$row->[1]->id eq $user->node_id or die 'not authorized';  # assertion
	}
	@codes = sort {$b->creation cmp $a->creation} @codes;
	
	return $self->render(template => $template, logged_in => $user, codes => \@codes);
}


sub _may_modify_role {
	my ($self, $code) = @_;
	# despite the name this condition is currently only valid for deletion, not for addition!
	return $code && ! $code->session_expired && ($code->user->equals($self->skgb->session->user) || $self->skgb->may('super-user'));
}


sub _modify_roles {
	my ($self, $code) = @_;
	
	return $self->reply->forbidden unless $self->_may_modify_role($code);
	
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
	$self->redirect_to( $self->url_for('auth', entity => $code->handle) );
}


sub _get_tree {
	my ($self, $root, $nodes, $relationships) = @_;
	
	if (! $root || ! $nodes || ! $relationships) {
		# retrieve and parse database graph
		($nodes, $relationships) = ({}, {});
		my $param = 0 + $self->stash('entity');
		my $t = $self->neo4j->session->begin_transaction;
		$t->{return_graph} = 1;  # the Neo4j::* interfaces aren't finalised
		my $result = $t->_commit(<<END, id => $param);
MATCH a=(c:AccessCode)-[:ROLE|:GUEST|:IDENTIFIES*]->(r:Role)
WHERE id(c) = {id}
RETURN a
END
		foreach my $record ( $result->list ) {
			foreach my $node ( @{$record->{graph}->{nodes}} ) {
				next if $nodes->{ $node->{id} };
				($node->{rel_out}, $node->{rel_in}) = ([], []);
				$nodes->{ $node->{id} } = $node;
			}
			foreach my $rel ( @{$record->{graph}->{relationships}} ) {
				next if $relationships->{ $rel->{id} };
				$relationships->{ $rel->{id} } = $rel;
				push @{$nodes->{ $rel->{startNode} }->{rel_out}}, $rel->{id};
				push @{$nodes->{ $rel->{endNode} }->{rel_in}}, $rel->{id};
			}
		}
		foreach my $node_id ( keys %$nodes ) {
			if (! @{$nodes->{$node_id}->{rel_in}}) {
				$root and die "multiple roots -- error in query / DB corrupt";
				$root = $nodes->{$node_id};
			}
		}
	}
	
	# build tree
	$root->{children} = [];
	foreach my $rel_id ( @{$root->{rel_out}} ) {
		my $rel = $relationships->{ $rel_id };
		my $node = $nodes->{ $rel->{endNode} };
#		$node->{via} = $rel;  # BUG: multiple rels to single node is possible
		push @{$root->{children}}, $self->_get_tree($node, $nodes, $relationships);
#		next if ! grep m/^Person$/, @{$node->{labels}};
	}
	return $root;
}


sub _tree {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	my $param = 0 + $self->stash('entity');
	
	my ($code, @codes) = $self->neo4j->get_persons($Q->{code}, code => $param);
#	say Data::Dumper::Dumper $code;
	$code and not @codes or die;
	@codes = ( SKGB::Intern::AccessCode->new(
		code => $code->get('c'),
		user => $code->get('person'),
		id => $param,
		app => $self->app,
	));
	
	return $self->_modify_roles($codes[0]) if $self->param('action') && $self->param('action') eq 'modify-roles';
	
	my $tree = $self->_get_tree;
	
	
	my @graphs = ();
	my $t = $self->neo4j->session->begin_transaction;
	$t->{return_graph} = 1;  # the Neo4j::* interfaces aren't finalised
	my $result = $t->_commit(<<END, id => $param);
MATCH a=(c:AccessCode)-[*]->(r:Role)
WHERE id(c) = {id}
RETURN a
END
	foreach my $record ( $result->list ) {
		push @graphs, $record->{graph};
	}
	
	
	
	
	
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
	
	return $self->render(template => 'key_manager/authtree', logged_in => $user, codes => \@codes, roles => \@roles, tree => $tree, graphs => \@graphs);
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
