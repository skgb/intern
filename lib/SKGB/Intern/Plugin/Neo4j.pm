package SKGB::Intern::Plugin::Neo4j;
use Mojo::Base 'Mojolicious::Plugin';

use REST::Neo4p 0.3012;
use Carp qw();
use Data::Dumper;

our @CARP_NOT = qw(Mojolicious::Renderer);


sub register {
	my ($self, $app, $args) = @_;
	
	# initiate DB connection
	REST::Neo4p->connect( @{$app->config->{neo4j_url_user_pass}} );
	
	
	# Execute a query in memory and return a list of all of the results up to a
	# given limit.
	$app->helper('neo4j.execute_memory' => sub {
		my ($c, $query, $limit, @params) = @_;
		
		SKGB::Intern::Plugin::Neo4j::execute_memory($query, $limit, @params);
	});
	
}


sub execute_memory {
	
	# Execute a query in memory and return a list of all of the results up to a
	# given limit.
	my ($query, $limit, @params) = @_;
#	say Data::Dumper::Dumper \@params if $params[0] eq 'node';
#	say Data::Dumper::Dumper $query->{_query};
	
	$query->execute(@params);
	if ($query->err) {
		Carp::croak ((ref $query->errobj) . ': ' . $query->errstr);
	}
	my @rows = ();
	while ( $limit-- && (my $row = $query->fetch) ) {
		push @rows, $row;
	}
	$query->finish;
	return wantarray ? @rows : $rows[0];
}


1;
