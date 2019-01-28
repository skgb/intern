package SKGB::Intern::Plugin::Neo4j;
use Mojo::Base 'Mojolicious::Plugin';

use Carp qw();
our @CARP_NOT = qw(Mojolicious::Renderer);
use Data::Dumper;

use Neo4j::Driver 0.11;
use REST::Neo4p 0.3012;
use SKGB::Intern::Person;


sub register {
	my ($self, $app, $args) = @_;
	
	my $neo4j_config = $app->config->{neo4j};
	my @neo4j_auth = ( $neo4j_config->{username}, $neo4j_config->{password} );
	
	# initialise Neo4p driver
	REST::Neo4p->connect( $neo4j_config->{uri}, @neo4j_auth );
	
	# initialise Neo4j driver
	my $driver = Neo4j::Driver->new($neo4j_config->{uri})->basic_auth(@neo4j_auth);
	$self->{neo4j_driver} = $driver;
	
	
	# Execute a query in memory and return a list of all of the results up to a
	# given limit, using Neo4p.
	$app->helper('neo4j.execute_memory' => sub {
		my ($c, $query, $limit, @params) = @_;
		
		SKGB::Intern::Plugin::Neo4j::execute_memory($query, $limit, @params);
	});
	
	
	# Return a current database session for the Neo4j driver.
	$app->helper('neo4j.session' => sub {
		my ($c) = @_;
		return $self->session;
	});
	
	
	# Runs a Cypher query using the Neo4j driver, returning the result with stats.
	$app->helper('neo4j.run_stats' => sub {
		my ($c, @args) = @_;
		my $t = $self->session->begin_transaction;
		$t->{return_stats} = 1;
		return $t->_autocommit->run(@args);  # the Neo4j::* interfaces aren't finalised
	});
	
	
	# Runs a Cypher query using the Neo4j driver, returning the result with graph.
	$app->helper('neo4j.run_graph' => sub {
		my ($c, @args) = @_;
		my $t = $self->session->begin_transaction;
		$t->{return_graph} = 1;
		return $t->_autocommit->run(@args);  # the Neo4j::* interfaces aren't finalised
	});
	
	
	# Execute a query in memory and return a list of records as the result,
	# using the Neo4j driver. This method automatically converts any :Person
	# nodes returned by the query to blessed Person objects. However, it
	# expects that each record contains at most one :Person node. If the record
	# contains additional nodes (or relationships) directly related to the
	# :Person node, this information is added to the Person object. If a
	# query parameter 'column' is provided, its value is interpreted as the
	# column name or index of the column(s) containing the :Person node, and
	# that column will afterwards contain the blessed Person object; otherwise
	# the blessed Person object will be appended as last column with the name
	# 'person'.
	# As a special case, if there is only one column, a list of Person objects is
	# returned in lieu of a list of records.
	# TODO: is this useful or confusing?
	$app->helper('neo4j.get_persons' => sub {
		my ($c, $query, @params) = @_;
		
		my $params = ref $params[0] eq 'HASH' ? $params[0] : {@params};
		my $result = $c->neo4j->run_graph($query, $params);
		
		my $persons = [];
		my $column_keys = $result->_column_keys;
		my $column_count = $column_keys->count;
		my @persons = ();
		if (! defined $params->{column}) {
			$params->{column} = $column_keys->add('person');
			# BUG: looks like this may corrupt a result that already has a column 'person'
		}
		
		foreach my $record (@{$result->{result}->{data}}) {
			bless $record, 'Neo4j::Driver::Record';
			$record->{column_keys} = $column_keys;
			
			# parse graph by matching the ids
			# there should only be small numbers of nodes, relationships and
			# labels, so these loops ought to be cheap
			my $person;
			my @relationships;
			foreach my $node (@{$record->{graph}->{nodes}}) {
				next unless grep m/^Person$/, @{$node->{labels}};
				$person = $node;
				last;
			}
			foreach my $rel (@{$record->{graph}->{relationships}}) {
				my @rel_nodes = ($rel->{startNode}, $rel->{endNode});
				next unless grep m/^$person->{id}$/, @rel_nodes;
#				$relationships{$rel->{id}} = $rel;
				foreach my $node (@{$record->{graph}->{nodes}}) {
					next if $node == $person;
					next unless grep m/^$node->{id}$/, @rel_nodes;
					$rel->{node} = $node;
					push @relationships, $rel;
#					$relationships{$rel} = $node;
					last;
				}
			}
			
			$person = SKGB::Intern::Person->new($person, \@relationships) if $person;
			if ($column_count eq 1) {
				push @$persons, $person;
			}
			else {
				$record->{row}->[$column_keys->key($params->{column})] = $person;
				delete $record->{graph};
			}
		}
		$persons = $result->{result}->{data} if $column_count ne 1;
		
		return wantarray ? @$persons : $persons;
	});
	
}


sub execute_memory {
	
	# Execute a query in memory and return a list of all of the results up to a
	# given limit.
	my ($query, $limit, @params) = @_;
#	say Data::Dumper::Dumper \@params if $params[0] eq 'node';
#	say Data::Dumper::Dumper $query->{_query};
	
	if (ref $query ne 'REST::Neo4p::Query') {
		$query = REST::Neo4p::Query->new("$query");
	}
	
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


sub session {
	# Return a current database session for the Neo4j driver.
	my ($self) = @_;
	return $self->{neo4j_driver}->session;
}


1;


__END__


