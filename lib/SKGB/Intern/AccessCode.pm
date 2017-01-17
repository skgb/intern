package SKGB::Intern::AccessCode;

use 5.012;
use utf8;
use Carp qw( croak );
use List::Util qw();
use REST::Neo4p;
use POSIX qw();
use DateTime::Format::ISO8601;
use Data::Dumper;

use overload '""' => \&code;

#use SKGB::Intern::Person::Neo4p;


my $TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ';


# Creates a new AccessCode object (formerly 'session hash') based on the key
# passed in. If no key is passed in or the key is not known in the database, an
# empty AccessCode object is created (i. e. a real object that accepts method
# calls, but they're all effectively no-ops). If the key expired, then the key
# itself and its meta-data may be retrievable through the API, but there will
# not be a person object associated with it, thus disabling login.
sub new {
	my ($class, @params) = @_;
	my $self = bless {@params}, $class;
	
	$self->{app} or croak "required param 'app' missing";
	$self->{app}->isa('Mojolicious::Controller') and $self->{app} = $self->{app}->app;
	$self->app->isa('Mojolicious') or croak "required param 'app' [" . ref($self->app) . "] not a Mojolicious app; SKGB::Intern instance required";
	$self->app->neo4j && $self->app->neo4j->session->isa('Neo4j::Session') or croak "SKGB::Intern instance required at param 'app' [" . ref($self->app) . "]; possible problem establishing database connection";
	
	if (ref $self->{user} && ref $self->{code}) {
		return $self;
	}
	
	if (defined $self->{code}) {
		my ($row, @rows) = $self->app->neo4j->get_persons(<<_, code => $self->{code});
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)
WHERE c.code = {code} AND (p)-[:ROLE|GUEST*..3]->(:Role)-[:MAY]->(:Right {right:'login'})
RETURN p, c
_
		@rows and die "multiple results for AccessCode query -- database corrupt?";
		if ($row) {
			$self->{code} = $row->get('c');
			if ( ! $self->expired ) {
				$self->{user} = $row->get('person');
			}
		}
		else {
			delete $self->{code};
		}
	}
	
	defined $self->{code} or $self->invalidate;
# 	{
# 		delete local $self->{app};
# 		say Data::Dumper::Dumper $self;
# 	}
	return $self;
}


sub invalidate {
	my ($self) = @_;
	delete $self->{_node};
	delete $self->{code};
	delete $self->{user};
}


sub _code_node {
	my ($self) = @_;
	if (! $self->{_node} && $self->{code}) {
		my @rows = $self->app->neo4j->execute_memory(<<_, 1, ( code => $self->{code}->{code} ));
MATCH (c:AccessCode)
WHERE c.code = {code}
RETURN c
_
		if ($rows[0]) {
			$self->{_node} = $rows[0]->[0];
		}
	}
	return $self->{_node};
}


sub code {
	my ($self) = @_;
	return $self->{code} && $self->{code}->{code} // '';
}


sub user {
	my ($self) = @_;
	return $self->{user};
}


sub creation {
	my ($self) = @_;
	return $self->{code} && $self->{code}->{creation} || '';
}


sub first_use {
	my ($self) = @_;
	return $self->{code} && $self->{code}->{first_use} || '';
}


sub access {
	my ($self) = @_;
	return $self->{code} && $self->{code}->{access} || '';
}


sub expiration {
	my ($self) = @_;
	return $self->creation && POSIX::strftime($TIME_FORMAT, gmtime( DateTime::Format::ISO8601->parse_datetime($self->creation)->epoch() + $self->app->config->{ttl}->{key} )) || '';
}


sub app {
	my ($self) = @_;
	return $self->{app};
}


sub new_time {
	return POSIX::strftime($TIME_FORMAT, gmtime( time() ));
}


# Verify that neither the key nor the session is expired.
# Expects either a 'session hash' or the key node.
# Returns a TRUE value iff the session hash should be treated as expired,
# specifically one of:
#   -1: The session hash didn't contain a key.
#   a unix epoch: The date on which the session did expire.
sub expired {
	my ($self) = @_;
	return -1 if ! $self->{code};  # -1 is a true value
	my @expired = ( $self->key_expired );
	if ( my $access = $self->{code}->{access} ) {
		my $sessionExpire = DateTime::Format::ISO8601->parse_datetime($access)->epoch() + $self->app->config->{ttl}->{session};
		# Todo: verify that comparison won't fail when time zones are in use
		if ( $sessionExpire < time ) {
			push @expired, $sessionExpire;
			say "adding $sessionExpire";
		}
	}
#	say Data::Dumper::Dumper List::Util::min(@expired);
	return List::Util::min(@expired);
}


# Verify that the key TTL would allow logging in.
# Expects either a 'session hash' or the key node.
# Returns a TRUE value iff the key should be treated as expired,
# specifically one of:
#   -1: The session hash didn't contain a key.
#   a unix epoch: The date on which the key did expire.
sub key_expired {
	my ($self) = @_;
	return (-1) if ! $self->{code};  # -1 is a true value
	my $keyCreation = $self->{code}->{creation};
	my $keyExpire = DateTime::Format::ISO8601->parse_datetime($keyCreation)->epoch() + $self->app->config->{ttl}->{key};
	# Todo: verify that comparison won't fail when time zones are in use
	return () if $keyExpire >= time;  # key is not expired
	say "key expiration $keyExpire";
	return ($keyExpire);
}


# Updates the AccessCode node in the database with the current access time.
sub update {
	my ($self) = @_;
	return if ! $self->_code_node;
	$self->_code_node->set_property({ access => SKGB::Intern::AccessCode::new_time() });
	$self->_code_node->set_property({ first_use => SKGB::Intern::AccessCode::new_time() }) unless $self->_code_node->get_property('first_use');
}



1;
