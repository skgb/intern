package SKGB::Intern::AccessCode;

use 5.012;
use utf8;
use Carp qw( croak );
use POSIX qw();
use DateTime::Format::ISO8601;
use Data::Dumper;

use overload '""' => \&code;


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
	delete $self->{code};
	delete $self->{user};
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
	if (! $self->{expiration}) {
		my $ttl = $self->app->config->{ttl}->{key};
		$self->{expiration} = $self->creation && POSIX::strftime($TIME_FORMAT, gmtime( DateTime::Format::ISO8601->parse_datetime($self->creation)->epoch + $ttl )) || '';
	}
	return $self->{expiration};
}


sub app {
	my ($self) = @_;
	return $self->{app};
}


sub new_time {
	return POSIX::strftime($TIME_FORMAT, gmtime( time ));
}


# A valid AccessCode is one that positively identifies a user and is not
# expired in any way. In particular, an AccessCode is not valid if it has
# a key that is not expired but a session that is.
# In other words, this method returns a TRUE value iff a valid user is
# currently logged in and may immediately use the system.
sub valid {
	my ($self) = @_;
	return $self->user && ! $self->session_expired;
}


# Verify that neither the key nor the session is expired.
# Returns a TRUE value iff the session hash should be treated as expired,
# specifically one of:
#   -1: The access code is invalid.
#   a unix epoch: The date on which the session did expire.
sub session_expired {
	my ($self) = @_;
	return $self->expired if $self->expired;
	my $expiration = $self->access && DateTime::Format::ISO8601->parse_datetime($self->access)->epoch + $self->app->config->{ttl}->{session};
	return $expiration if $expiration && time > $expiration;
	return undef;
}


# Verify that the key TTL would allow logging in.
# Returns a TRUE value iff the key should be treated as expired,
# specifically one of:
#   -1: The access code is invalid.
#   a unix epoch: The date on which the key did expire.
sub expired {
	my ($self) = @_;
	return -1 if ! $self->{code} || ! $self->expiration;  # -1 is a true value
	return undef if $self->new_time le $self->expiration;
	return DateTime::Format::ISO8601->parse_datetime($self->expiration)->epoch;
}


# Updates the AccessCode node in the database with the current access time.
sub update {
	my ($self) = @_;
	my $now = $self->new_time;
	return if $self->access && $self->access eq $now;
	my $query = <<_;
MATCH (c:AccessCode {code:{code}})
SET c.access = {now}
_
	$query .= ', c.first_use = {now}' if ! $self->first_use;
	my $result = $self->app->neo4j->run_stats($query, code => $self->code, now => $now);
	$result->stats->{properties_set} or warn 'Updating access time for '.$self->code.' failed';
}



1;


__END__

=pod

=head1 NAME

SKGB::Intern::AccessCode

=head1 SYNOPSIS

 my $key = $c->session('key');
 my $session = SKGB::Intern::AccessCode->new( code => $key, app => $c );

=head1 EXPIRATION TIME MODEL

The "session TTL" protects against the "internet cafe" scenario of a user
forgetting to log out of the system on a shared workstation. For this to work,
the session TTL needs to be rather short. Re-login is possible using the same
access code. However, insecure shared workstations are most likely unusual for
our users, so this feature is not high concern right now.

The "cookie TTL" is the HTTP cookie's expiration time. It should be in the same
ball-park as the session TTL, but slightly longer, so that a session time-out
can be signalled to the user. In practice, this should probably always be a
session cookie for interoperability, except for "high security" keys.

The "key TTL" is the access code's own time-to-live. For regular keys sent via
email, the biggest threat is probably an attack on the email account, which
might happen at any time. To prevent access codes in ancient emails from
working, the codes must expire. For ease of use the validity period should
probably not be too short. A maximum of about a week seems sensible, although
they should be significantly shorter by default, perhaps a little longer than
one day.

=head1 AUTHOR

Copyright (c) 2017 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
