package Neo4j::Session;

use 5.016;
use utf8;

#use Devel::StackTrace qw();
use Data::Dumper qw();
use Carp qw(croak);

use Neo4j::Transaction;


sub new {
	my ($class, $driver) = @_;
	
	# this method might initiate the HTTP connection, but doesn't as of yet
	
	my $session = {
#		driver => $driver,
#		uri => $driver->{uri}->clone,
		client => $driver->_client,
		die_on_error => $driver->{die_on_error},
	};
	
	return bless $session, $class;
}


sub begin_transaction {
	my ($self) = @_;
	
	# this method might initiate the HTTP connection, but doesn't as of yet
	return Neo4j::Transaction->new($self);
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	my $t = $self->begin_transaction();
#	$t->{transaction} = $t->{commit};  # commit (= execute) the statement before even opening a transaction
	return $t->_commit($query, @parameters);
}


sub graph {
	my ($self, $graph) = @_;
	$self->{return_graph} = $graph // 1;
	return $self;
}


sub close {
}



1;

__END__
