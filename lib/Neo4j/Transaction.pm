package Neo4j::Transaction;

use 5.016;
use utf8;

#use Devel::StackTrace qw();
use Data::Dumper qw();
use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Session Neo4j::Driver);
use Try::Tiny;

use URI;
use JSON::PP qw();
use JSON::MaybeXS;

use Neo4j::StatementResult;


our $TRANSACTION_ENDPOINT = '/db/data/transaction';
our $COMMIT_ENDPOINT = '/db/data/transaction/commit';


sub new {
	my ($class, $session) = @_;
	
	my $transaction = {
#		session => $session,
		client => $session->{client},
		transaction => URI->new( $TRANSACTION_ENDPOINT ),
		commit => URI->new( $COMMIT_ENDPOINT ),
		die_on_error => $session->{die_on_error},
		return_graph => $session->{return_graph},
	};
	
	return bless $transaction, $class;
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	my @statements;
	if (ref $query eq 'ARRAY') {
		foreach my $args (@$query) {
			push @statements, $self->_prepare(@$args);
		}
	}
	elsif ($query) {
		@statements = ( $self->_prepare($query, @parameters) );
	}
	else {
		@statements = ();
	}
	return $self->_post(@statements);
}


sub _prepare {
	my ($self, $query, @parameters) = @_;
	
	my $json = {
#		includeStats => \1,
		statement => $query,
	};
	$json->{resultDataContents} = [ "row", "graph" ] if $self->{return_graph};
	
	if (ref $query eq 'REST::Neo4p::Query') {
		$json->{statement} = $query->query;
	}
	
	if (ref $parameters[0] eq 'HASH') {
		$json->{parameters} = $parameters[0];
	}
	elsif (scalar @parameters && scalar @parameters % 2 == 0) {
		$json->{parameters} = {@parameters};
	}
	
	return $json;
}


sub _post {
	my ($self, @statements) = @_;
	
	my $request = { statements => \@statements };
	
	# TIMTOWTDI: REST::Neo4p::Query uses Tie::IxHash and JSON::XS, which may be faster than sorting
	my $coder = JSON::PP->new->utf8;
	$coder = $coder->pretty->sort_by(sub {
		return -1 if $JSON::PP::a eq 'statements';
		return 1 if $JSON::PP::b eq 'statements';
		return 0;  # $JSON::PP::a cmp $JSON::PP::b;
	});
	
	$self->{client}->POST( "$self->{transaction}", $coder->encode($request) );
	say 'Status: ', $self->{client}->responseCode() unless $self->{client}->responseCode() =~ m/^200|[^2]\d\d$/;
	
	my $response;
	my @errors = ();
	if ($self->{client}->responseCode() =~ m/^[^2]\d\d$/) {
		push @errors, 'Error: ' . $self->{client}->responseCode();
	}
	try {
		$response = decode_json $self->{client}->responseContent();
	}
	catch {
		push @errors, $_;
	};
	foreach my $error (@{$response->{errors}}) {
		push @errors, "$error->{code}:\n$error->{message}";
	}
	if (@errors) {
		my $errors = join "\n", @errors;
		$self->{die_on_error} and croak $errors or carp $errors;
	}
	
	my $location = $self->{client}->responseHeader('Location');
	$self->{transaction} = new URI($location)->path_query if $location;
	$self->{commit} = new URI($response->{commit})->path_query if $response->{commit};
	
	if (scalar @statements eq 1) {
		my $statement_result = Neo4j::StatementResult->new( $response->{results}->[0] );
		return wantarray ? $statement_result->list : $statement_result;
	}
	warn "Multiple statements in single Neo4j request untested";
	my @statement_results = map { Neo4j::StatementResult->new( $_ ) } @{$response->{results}};
	return wantarray ? @statement_results : \@statement_results;
}


sub _commit {
	my ($self, $query, @parameters) = @_;
	
	$self->{transaction} = $self->{commit};
	return $self->run($query, @parameters);
}


sub commit {
	my ($self) = @_;
	
	return $self->_commit();
}


sub rollback {
	my ($self) = @_;
	
	$self->{client}->DELETE( "$self->{transaction}" );
}


sub close {
}



1;

__END__

http://stackoverflow.com/questions/37381833/neo4j-driver-confirm-transaction-success


sub new {
	my ($class, $url, $user, $pass) = @_;
#	print Data::Dumper::Dumper($url, $user, $pass);
	
	$url =~ m{^(\w+)://(.*)$} or croak;
	my $client = REST::Client->new( host => "$1://$user:$pass\@$2", timeout => 60, follow => 1 );
	$client->addHeader('Accept', $CONTENT_TYPE);
	$client->addHeader('Content-Type', $CONTENT_TYPE);
	$client->addHeader('X-Stream', 'true');
#	my $l = 'http://127.0.0.1:7474/db/data/';
#	$client->GET( URI->new($l)->path_query );
#	say 'Status: ', $client->responseCode();
#	say $client->responseContent();
	
	return bless { client => $client }, $class;
}


sub client {
	my ($self) = @_;
	return $self->{client};
}


sub query {
	my ($self, $query) = @_;
	my $json = {
		statements => [
			{
				statement => $query,
				includeStats => \1,
				resultDataContents =>  [ "row", "graph" ],
			},
		],
#		query => $query,
	};
#	my $endpoint = "/db/data/cypher";
	my $endpoint = "$TRANSACTION_ENDPOINT/commit";
	$self->client->POST( $endpoint, encode_json($json) );
	say 'Status: ', $self->client->responseCode();
#	say $self->client->responseContent();
	say Data::Dumper::Dumper decode_json $self->client->responseContent();
}
