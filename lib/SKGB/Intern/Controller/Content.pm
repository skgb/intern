package SKGB::Intern::Controller::Content;
use Mojo::Base 'Mojolicious::Controller';
use strict;


sub index {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user);
}


sub content {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user);
}


sub wetter {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user);
}


sub stegdienstliste {
	my ($self) = @_;
	
	my @records = $self->neo4j->get_persons(<<END, column => 'p');
MATCH (p:Person)-[r:ROLE|GUEST]->(Role{role:'active-member'})
WHERE NOT(exists(r.leaves))
OPTIONAL MATCH (p)<-[:FOR]-(a:Address{type:'street'})
OPTIONAL MATCH (p)-[:ROLE|GUEST*..3]->(v:Role{role:'board-member'})
RETURN [p, r] as p, a.place AS place, v AS board, r.noService as exempt
END
	# multiple street addresses for persons may cause duplicate entries
	my @unique_records = do { my %seen; grep { ! $seen{$_->get('p')->handle}++ } @records };
	
	return $self->render(records => \@unique_records, board_member => $self->skgb->may('board-member'));
}

1;
