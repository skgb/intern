package SKGB::Intern::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use POSIX qw();
use REST::Neo4p;

my $TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ';

my $Q = {
  codelist => REST::Neo4p::Query->new(<<QUERY),
MATCH (c:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)
 RETURN c, p
 UNION
 MATCH (c:AccessCode {code:{code}})-[:IDENTIFIES]->(p:Person)<-[:IDENTIFIES]-(a:AccessCode)
 RETURN a AS c, p
 ORDER BY c.creation DESC
QUERY
  codelist_all_debug => REST::Neo4p::Query->new(<<QUERY),
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 RETURN c, p
 ORDER BY c.creation DESC
QUERY
  code => REST::Neo4p::Query->new(<<QUERY),
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
 WHERE c.code = {code}
 RETURN c,p
QUERY
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
	
	my $query = $self->stash('code') ? $Q->{code} : $Q->{codelist};
	my $param = $self->stash('code') ? $self->stash('code') : $self->session('key');
	my $template = $self->stash('code') ? 'key_manager/authtree' : 'key_manager/codelist';
	$query = $Q->{codelist_all_debug} if defined $self->param('all');  # debug
	
	my $user = $self->skgb->session->user;
	if ( ! $user ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my @codes = ();
	my @rows = $self->neo4j->execute_memory($query, 1000, (code => $param));
	foreach my $row (@rows) {
#		push @codes, $self->_code( $row->[0], $user );
#		$row->[1]->id eq $user->node_id or die 'not authorized';  # assertion
		push @codes, $self->_code( $row->[0], SKGB::Intern::Model::Person->new($row->[1]) );  # debug
	}
	@codes = sort {$b->{creation} cmp $a->{creation}} @codes;
	
	return $self->render(template => $template, logged_in => $user, codes => \@codes);
}


sub _code {
	my ($self, $node, $for) = @_;
	my $code = $node->as_simple;
	$code->{this_session} = 1 if $code->{code} eq $self->session('key');
	$code->{expiration} = POSIX::strftime($TIME_FORMAT, gmtime( DateTime::Format::ISO8601->parse_datetime($code->{creation})->epoch() + $self->config->{ttl}->{key} ));
	$code->{this_expired} = POSIX::strftime($TIME_FORMAT, gmtime( time )) gt $code->{expiration};
	$code->{for} = $for if $for;
#	$code->{this_expired} = $self->skgb->session->key_expired($node);
	return $code;
}


1;
