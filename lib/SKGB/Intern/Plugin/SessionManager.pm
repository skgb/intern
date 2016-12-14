package SKGB::Intern::Plugin::SessionManager;
use Mojo::Base 'Mojolicious::Plugin';

use REST::Neo4p;
use String::Random;
use List::Util;
use POSIX qw();
use DateTime::Format::ISO8601;
use Data::Dumper;

use SKGB::Intern::Model::Person;

my $TIME_FORMAT = '%Y-%m-%dT%H:%M:%SZ';

my $Q = {
  access => REST::Neo4p::Query->new(<<END),
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[:ROLE|GUEST*..3]->(:Role)-[:ACCESS|MAY]->(r)
WHERE c.code = {code} AND ((r:Resource) AND '/login' IN r.urls OR (r:Right) AND r.right = 'login')
RETURN p, c
END
};

sub register {
	my ($self, $app, $args) = @_;
	$args ||= {};
	
	$app->sessions->default_expiration( $app->config->{ttl}->{cookie} );
#	$app->sessions->cookie_name('skgb-intern');
#	$app->sessions->secure(1);  # HTTPS only
	
	
	# Get the current time, formatted for use in the database's AccessCode nodes.
	$app->helper('skgb.session.new_time' => sub {
		my ($c, @args) = @_;
		return POSIX::strftime($TIME_FORMAT, gmtime( time() ));
	});
	
	
	# Get the 'session hash', consisting of a Person object of the user logged
	# in and the database's AccessCode node. A key parameter may be given to use
	# that specific key in lieu of the current session; this is required when
	# logging in.
	$app->helper('skgb.session.get_session' => sub {
#		say "trace2";
		my ($c, $key) = @_;
		$key ||= $c->session('key');
		
		my $session = {
			user => undef,
			code => undef,
		};
#		say "trace2a '$key'";
		return $session if ! $key;
#		say $key;
		
		my @rows = $c->neo4j->execute_memory($Q->{access}, 2, ( code => $key ));
#		if ($rows[1]) {
#			die "database corrupted: multiple persons related to same key '$key'";
#		}
#		say "trace2b " . scalar @rows;
		if ($rows[0]) {
			$session->{code} = $rows[0]->[1];
			if ( ! $c->skgb->session->expired($session) ) {
				$session->{user} = SKGB::Intern::Model::Person->new( $rows[0]->[0] );
			}
#			say "hello1 " . $session->{code};
#			say Data::Dumper::Dumper($session);
		}
		
#		say "trace3";
		return $session;
	});
	
	
	# Verify that neither the key nor the session is expired.
	# Expects either a 'session hash' or the key node.
	# Returns a TRUE value iff the session hash should be treated as expired,
	# specifically one of:
	#   -1: The session hash didn't contain a key.
	#   a unix epoch: The date on which the session did expire.
	$app->helper('skgb.session.expired' => sub {
		my ($c, $session) = @_;
		my $code = ref $session eq 'HASH' ? $session->{code} : $session;
#		say Data::Dumper::Dumper $code;
		return -1 if ! $code;  # -1 is a true value
		my @expired = ( $c->skgb->session->key_expired($code) );
		if ( my $access = $code->get_property('access') ) {
			my $sessionExpire = DateTime::Format::ISO8601->parse_datetime($access)->epoch() + $app->config->{ttl}->{session};
			# Todo: verify that comparison won't fail when time zones are in use
			if ( $sessionExpire < time ) {
				push @expired, $sessionExpire;
				say "adding $sessionExpire";
			}
		}
#		say Data::Dumper::Dumper List::Util::min(@expired);
		return List::Util::min(@expired);
	});
	
	
	# Verify that the key TTL would allow logging in.
	# Expects either a 'session hash' or the key node.
	# Returns a TRUE value iff the key should be treated as expired,
	# specifically one of:
	#   -1: The session hash didn't contain a key.
	#   a unix epoch: The date on which the key did expire.
	$app->helper('skgb.session.key_expired' => sub {
		my ($c, $session) = @_;
		my $code = ref $session eq 'HASH' ? $session->{code} : $session;
		return (-1) if ! $code;  # -1 is a true value
		my $keyCreation = $code->get_property('creation');
		my $keyExpire = DateTime::Format::ISO8601->parse_datetime($keyCreation)->epoch() + $app->config->{ttl}->{key};
		# Todo: verify that comparison won't fail when time zones are in use
		return () if $keyExpire >= time;  # key is not expired
		say "key expiration $keyExpire";
		return ($keyExpire);
	});
	
	
	# Updates the AccessCode node in the database with the current access time.
	# To be called on every access. Used for session validation.
	$app->helper('skgb.session.update' => sub {
		my ($c, $session) = @_;
		return if ! $session->{code};
		$session->{code}->set_property({ access => $c->skgb->session->new_time() });
		$session->{code}->set_property({ first_use => $c->skgb->session->new_time() }) unless $session->{code}->get_property('first_use');
		$c->session( key => $session->{code}->get_property('code') );
	});
	
	
	# Verify that the user is logged in.
	# Returns a Person object of the user logged in, or undef.
	$app->helper('skgb.session.user' => sub {
		my ($c) = @_;
		my $session = $c->skgb->session->get_session;
		if ($session->{user}) {
			$c->skgb->session->update( $session );
		}
		return $session->{user};
	});
	
}


1;
