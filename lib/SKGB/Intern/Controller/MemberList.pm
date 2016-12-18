package SKGB::Intern::Controller::MemberList;
use Mojo::Base 'Mojolicious::Controller';
use 5.016;

use Regexp::Common qw /number/;


my $Q = {
  memberships_fast => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[r:ROLE|GUEST]->(m:Role)-->(:Role {role:'member'})
 RETURN p,r,m
QUERY
  memberships_path => REST::Neo4p::Query->new(<<QUERY),
MATCH a=(:Person)-[:ROLE|GUEST*..2]->(:Role {role:'member'})
 RETURN a
QUERY
  allmembers => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[:ROLE|GUEST*..2]->(:Role {role:'member'})
 RETURN p
QUERY
  member => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 RETURN p
QUERY
  related_indirect => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 MATCH (p)-[r1]-(r)-[r2]-(o:Person)
 WHERE NOT r:Role AND NOT r:Person AND p <> o
 RETURN o,collect(DISTINCT r)
// RETURN o,collect([r,r1,r2]) -- BUG: unsupported by Neo4p!!
QUERY
  related => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 MATCH (p)-[r]-(o:Person)
 RETURN o,r
QUERY
  addresses => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 MATCH (p)<-[r]-(a:Address)
 RETURN a,r
 ORDER BY a.type DESC, r.primary, r.kind, a.address
QUERY
  boats => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 MATCH (p)-[:OWNS]->(b:Boat)
 OPTIONAL MATCH (b)-->(c:Berth)
 RETURN b, c.ref
 ORDER BY b.mark
// TODO: c.ref doesn't exist for all berths, but it's okay for the Preview
QUERY
  clubkeys => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)
 WHERE id(p) = {node}
 MATCH (p)-[r:OWNS]->(k:ClubKey)
 RETURN r,k.nr
QUERY
  mandates => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[:HOLDER]-(s:Mandate)
 WHERE id(p) = {node}
 RETURN s
 ORDER BY s.umr
QUERY
  list_postal => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)<--(a:Address {type:'street'})
 WHERE (p)<-[:FOR {primary:'text'}]-(a)
  OR (p)<-[:FOR {primary:true}]-(a)
 RETURN p, a
QUERY
  list_postal_all => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)<--(a:Address {type:'street'})
 WHERE (p)<-[:FOR]-(a)
 RETURN p, a
QUERY
  all_persons => <<END,
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:ROLE|GUEST]->(m:Role)-[:ROLE]->(:Role {role:'member'})
RETURN p AS person, type(r) = 'GUEST' AS guest, m.role AS status
LIMIT 1
END
};



sub list {
	my ($self) = @_;
	
	# todo: darf dieser user die liste überhaupt sehen?
	if ( ! $self->skgb->may ) {
#		$self->res->code(403);
#	return $self->render(members => []);
#	return $self->render(template => 'list', members => []);
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	# todo: move this to is_logged_in or whatever
	# implement exception list in conf
	
	
	
	# Neo4p is sloooow! (uses the old cypher endpoint instead of transactions)
	# making my own RESTful query should speed this up a lot:
	# curl -iH "Content-Type: application/json" -X POST -d '{"statements":[]}' -u neo4j:pass http://localhost:7474/db/data/transaction
	# curl -iH "Content-Type: application/json" -X POST -d '{"statements":[{"statement":"MATCH a=(:Person)-[:IS_A|IS_A_GUEST*..2]->(:Role{role:\"member\"}) RETURN a"}]}' -u neo4j:pass http://localhost:7474/db/data/transaction/1362/commit
	
	my @persons = ();
#	$Q->{memberships}->{ResponseAsObjects} = 0;  # doesn't work for paths
#use Benchmark;
#my $start_time = new Benchmark;
#	my @rows = $self->neo4j->execute_memory($Q->{memberships_path}, 1000, ());
	my @rows = $self->neo4j->execute_memory($Q->{memberships_fast}, 1000, ());
#my $end_time   = new Benchmark;
	foreach my $row (@rows) {
		push @persons, SKGB::Intern::Model::Person->new_membership( $row );
	}
#my $difference = timediff($end_time, $start_time);
#	@persons = sort {fc($a->name_sortable) cmp fc($b->name_sortable)} @persons;
	
	$self->render(members => \@persons);
#print "It took ", timestr($difference), "\n";
	return;
}


sub postal {
	my ($self) = @_;
	
	if ( ! $self->skgb->may ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my $query = defined $self->param('all') ? $Q->{list_postal_all} : $Q->{list_postal};
	my @list = ();
	my @rows = $self->neo4j->execute_memory($query, 1000, ());
	my $max_address_lines = 0;
	foreach my $row (@rows) {
		# BUG: Neo4p doesn't handle UTF-8 encoding when plain text is returned instead of nodes, so we need an extra get_property here
		my @address = split m/\n/, $row->[1]->get_property('address');
		$max_address_lines = scalar @address if scalar @address > $max_address_lines;
		push @list, {
			person => SKGB::Intern::Model::Person->new( $row->[0] ),
			address => \@address,
		};
	}
	@list = sort {fc($a->{person}->name_sortable) cmp fc($b->{person}->name_sortable)} @list;
	
	$self->render(list => \@list, address_cols => $max_address_lines);
	return;
}


sub list_person {
	my ($self) = @_;
	
	if ( ! $self->skgb->may ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
#	my @persons = $self->neo4j->get_persons($Q->{all_persons}, column => 0);
	my @persons = $self->neo4j->get_persons(<<END);
MATCH (p:Person)
OPTIONAL MATCH (p)-[r:ROLE|GUEST]->(m:Role)-[:ROLE]->(:Role {role:'member'})
RETURN [p, r, m]
END
#	use Data::Dumper;
#	say Dumper \@persons;
#	die;
	
#	foreach my $person (@persons) {
#	}
#	my @codes = ($self->_code( $code, SKGB::Intern::Model::Person->new($code->get(1)) ));
	
#	return $self->render(text => "" . $self->stash('person'));
	return $self->render(template => 'member_list/list_person', members => \@persons);
}


sub person {
	my ($self) = @_;
	
	# TODO: The handle may be a semi-permanent opaque ASCII string as defined
	# by the club secretary (usually something like "firstname.lastname") or it
	# may be the transient integer low-level database node id. If the former is
	# supplied, we need to figure out the node id because the node method
	# expects it. This is potentially very expensive when called in a loop!
	my $handle = $self->param('person_placeholder');
	if ($handle !~ m/^$RE{num}{int}{-sign => ''}$/) {
		my $result = $self->neo4j->session->run(<<END, handle => $handle);
MATCH (p:Person)
WHERE p.userId = {handle}
RETURN id(p) AS node_id
END
		$result->size eq 0 and die "person not in database";
		$result->size eq 1 or die "database corrupt: multiple persons with same handle";
		$handle = $result->single->get('node_id');
	}
	return $self->node($handle);
}


sub list_leaving {
	my ($self) = @_;
	
	if ( ! $self->skgb->may ) {
#		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my @records = $self->neo4j->get_persons(<<END, column => 'p');
MATCH (p:Person)-[rm:ROLE|GUEST]->(m:Role)-[:ROLE]->(:Role {role:'member'})
WHERE rm.leaves <> ""
OPTIONAL MATCH (p)-[rk]-(k:ClubKey)
RETURN p, rm, m, rm.leaves AS leaves, count(k) AS keys, rk.returned AS returned
END
	
	return $self->render(template => 'member_list/list_leaving', records => \@records);
}


sub node {
	my ($self, $node) = @_;
	my @rows;
	
	if ( ! $self->skgb->may ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	$node //= $self->param('node');
	my $person;
	if ($node) {
#		say Data::Dumper::Dumper $self->param('node');
		my $row = $self->neo4j->execute_memory($Q->{member}, 1, (node => 0 + $node));
#		say Data::Dumper::Dumper $row;
		$person = SKGB::Intern::Model::Person->new( $row->[0] );
	}
	else {
		$person = $self->skgb->session->user;
	}
	
	my @all_related = ();
	# TODO: add indirect relations (shared phone numbers, debitors etc.)
	@rows = $self->neo4j->execute_memory($Q->{related_indirect}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		my $related = {
			person => SKGB::Intern::Model::Person->new( $row->[0] ),
			indirect => 1,
			related_through => {},
		};
#		next if $person->equals( $related->{person} );  # now in query
		foreach my $hop_node ( @{$row->[1]} ) {
			$related->{related_through}->{ join ' ', $hop_node->get_labels } = 1;
		}
#		say Data::Dumper::Dumper $row, $related;
		push @all_related, $related;
# 		my $i = 0;
# 		for ( ; $i < scalar @all_related; $i++) {
# 			my $a = $all_related[$i]->{person}->node_id;
# 			last if $row->[0]->id == $a;
# 		}
# 		$all_related[$i] ||= {
# 			person => SKGB::Intern::Model::Person->new( $row->[0] ),
# 		};
# 		$all_related[$i]->{relation} = $row->[1];
# 		$all_related[$i]->{forward} = $row->[1]->end_node eq $row->[0];
	}
	
	@rows = $self->neo4j->execute_memory($Q->{related}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		my $i = 0;
		# find any duplicates
		for ( ; $i < scalar @all_related; $i++) {
			my $a = $all_related[$i]->{person}->node_id;
			last if $row->[0]->id == $a;
		}
		$all_related[$i] ||= {
			person => SKGB::Intern::Model::Person->new( $row->[0] ),
		};
		$all_related[$i]->{direct} = 1;
		$all_related[$i]->{relation} = $row->[1];
		$all_related[$i]->{forward} = $row->[1]->end_node eq $row->[0];
#		$all_related[$i]->{connection} = $row->[1];
#		$all_related[$i]->{relations} = [$row->[2], $row->[3]];
	}
#	say Data::Dumper::Dumper \@all_related;
	
	my @addresses = ();
	@rows = $self->neo4j->execute_memory($Q->{addresses}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		 my $address = {
			address => $row->[0]->get_property('address'),
			type => $row->[0]->get_property('type'),
			kind => $row->[1]->get_property('kind'),
			comment => $row->[0]->get_property('comment'),
			primary => $row->[1]->get_property('primary'),
			place => $row->[0]->get_property('place'),
		};
		push @addresses, $address;
	}
	
	my @boats = ();
	@rows = $self->neo4j->execute_memory($Q->{boats}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		my $boat = $row->[0]->as_simple;
		$boat->{_berth} = $row->[1] if $row->[1];
		push @boats, $boat;
	}
	
	my @keys = ();
	@rows = $self->neo4j->execute_memory($Q->{clubkeys}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		my $key = $row->[0]->as_simple;
		$key->{_nr} = $row->[1];
		push @keys, $key;
	}
	
	my @mandates = ();
	@rows = $self->neo4j->execute_memory($Q->{mandates}, 100, (node => $person->node_id));
	foreach my $row (@rows) {
		push @mandates, $row->[0]->get_property('umr');
	}
	
	
	
	return $self->render(
		template => 'member_list/node',
		person => $person,
		all_related => \@all_related,
		addresses => \@addresses,
		boats => \@boats,
		clubkeys => \@keys,
		mandates => \@mandates,
	);
}

1;


__END__

MATCH (p:Person) WHERE p.name =~ 'Arne.*' MATCH (p)-[*]->(a), (p)<--(b), (p)--(r)--(c) WHERE NOT r:Role AND NOT b:AccessCode RETURN p,a,b,c
MATCH (p:Person) WHERE p.name =~ 'Arne.*' MATCH (p)-[*]->(a) RETURN p,a
MATCH (p:Person) WHERE p.name =~ 'Arne.*' MATCH (p)<--(b) WHERE NOT b:AccessCode RETURN p,b
MATCH (p:Person) WHERE p.name =~ 'Arne.*' MATCH (p)--(r)--(c) WHERE NOT r:Role RETURN p,c
