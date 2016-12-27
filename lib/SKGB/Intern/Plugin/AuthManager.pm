package SKGB::Intern::Plugin::AuthManager;
use Mojo::Base 'Mojolicious::Plugin';

use utf8;

use REST::Neo4p;
#use List::Util;
#use POSIX qw();
use Data::Dumper;

use SKGB::Intern::AccessCode;

#use Mojolicious::Plugin::Authorization;


my $Q = {
  access => REST::Neo4p::Query->new(<<END),
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[a:ROLE|GUEST|ACCESS*..3]->(r:Resource)
 WHERE c.code = {code}
 AND any(y IN r.urls WHERE {url} =~ y)
 AND coalesce(last(a).level, 1) >= toInt({level})
 AND type(last(a)) = 'ACCESS' AND single(x IN a WHERE type(x) = 'ACCESS')
 RETURN p, c, r, last(a)
 ORDER BY last(a).level DESC
 LIMIT 1
END
#   may => <<END,
# MATCH (c:AccessCode)-[:IDENTIFIES]->(:Person)-[:IS_A|IS_A_GUEST*..2]->(:Role)-[:MAY]->(s:Right)
#  WHERE c.code = {code}
#  RETURN s.right
# END
  may => <<_,
MATCH (c:AccessCode)-[:IDENTIFIES]->(:Person)-[:ROLE|GUEST*..3]->(r:Role)-[:MAY]->(s:Right)
WHERE c.code = {code} AND NOT( (c)-[:NOT]->(r) )
RETURN s.right
UNION
MATCH (c:AccessCode)-[:ROLE*..3]->(r:Role)-[:MAY]->(s:Right)
WHERE c.code = {code}
RETURN s.right
_
  role => <<_,
MATCH (c:AccessCode)-[:IDENTIFIES]->(:Person)-[:ROLE|GUEST*..3]->(r:Role)
WHERE c.code = {code} AND r.role = {role} AND NOT( (c)-[:NOT]->(r) )
RETURN true AS has_role
UNION
MATCH (c:AccessCode)-[:ROLE*..3]->(r:Role)
WHERE c.code = {code} AND r.role = {role}
RETURN true AS has_role
_
};


sub register {
	my ($self, $app, $args) = @_;
	$args ||= {};
	
	$app->sessions->default_expiration( $app->config->{ttl}->{cookie} );
#	$app->sessions->cookie_name('skgb-intern');
#	$app->sessions->secure(1);  # HTTPS only
	
	my @helpers = qw( link_auth_to has_access );
	$app->helper($_ => __PACKAGE__->can("_$_")) for @helpers;
	
	my @skgb_helpers = qw( session may role );
	$app->helper("skgb.$_" => __PACKAGE__->can("_$_")) for @skgb_helpers;
	
}


# Get the AccessCode object AKA 'session hash'. A key parameter may be given to
# use that specific key in lieu of the current session; this is required when
# logging in.
# Also sets/refreshes the session cookie. To be called on every access.
sub _session {
	my ($c, $key) = @_;
	$key ||= $c->session('key');
	
	my $session = $c->stash('session');
	if (! $session) {
		$session = SKGB::Intern::AccessCode->new( code => $key, app => $c );
		if ($session->user) {
			$session->update;
			$c->session( key => $key );
		}
		$c->stash(session => $session);
	}
	
	return $session;
}


sub _may {
	my ($c, $right, $key) = @_;
	$key ||= $c->session('key');
	return undef if ! $key;
	$right ||= "mojo:" . $c->current_route;
	
	my $rights = $c->stash('rights');
	if (! $rights) {
		my @rights = $c->neo4j->session->run($Q->{may}, code => $key);
		my %rights = map { $_->get => 1 } @rights;
		$rights = \%rights;
		$c->stash(rights => $rights);
		
#		say "$key:";
#		say Data::Dumper::Dumper $rights;
	}
	
	return $rights->{$right};
}


# this may be a dirty hack (initially only used to 'simplify' a provisional check in the Stegdienstliste app)
sub _role {
	my ($c, $role, $key) = @_;
	$key ||= $c->session('key');
	return undef if ! $key;
	
	my $result = $c->neo4j->session->run($Q->{role}, code => $key, role => $role);
	return $result->size;
}


# sub _if_may {
# 	my ($c, $right, $then) = @_;
# 	
# 	if (ref $then) {
# 		# not implemented
# 		die;
# 	}
# 	
# 	return $c->skgb->may($right) ? $then : "🔒";
# }


sub _link_auth_to {
	my ($c, $content) = (shift, shift);
	my @url = ($content);
	
	# Content/Captures logic lifted straight from _link_to helper in Mojo 6.37
	
	# Content
	unless (ref $_[-1] eq 'CODE') {
		@url = (shift);
		push @_, $content;
	}
	
	# Captures
	push @url, shift if ref $_[0] eq 'HASH';
	
	# check auth
	my $url = $c->url_for(@url);
	my $target = $url[0];
	my $access = $c->skgb->may("mojo:$target");
	if (! $access) {
		my $routes = $c->app->routes;
		my $route = $routes->lookup($target);
		$access = $route->parent == $routes if $route;  # top level route => no login requirement => public access
#		$access ||= $c->has_access($url) unless $target && $target eq "_";  # old URL-based scheme
	}
	return $c->tag('a', class => 'no-access', @_) if ! $access;
	
	return $c->tag('a', href => $url, @_);
}


1;
