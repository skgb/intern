package SKGB::Intern::Plugin::AuthManager;
use Mojo::Base 'Mojolicious::Plugin';

use utf8;

use REST::Neo4p;
use String::Random;
use List::Util;
use POSIX qw();
use DateTime::Format::ISO8601;
use Data::Dumper;

use SKGB::Intern::Model::Person;

use Mojolicious::Plugin::Authorization;


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
	
	my @helpers = qw( link_auth_to has_access );
	$app->helper($_ => __PACKAGE__->can("_$_")) for @helpers;
	
	my @skgb_helpers = qw( may role );
	$app->helper("skgb.$_" => __PACKAGE__->can("_$_")) for @skgb_helpers;
	
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


# TODO: unit testing
sub _has_access {
	my ($c, $url, $access_level, $key) = @_;
	$url ||= $c->url_for;  # TODO: This is the canonical URL, not the actual URL. Is this secure enough?
	$access_level ||= 1;
	$key ||= $c->session('key');
	my $url_path = ref $url ? "" . $url->path : $url;
	
	say "called has_access for $url";
#	die if $url eq "/mitgliederliste";
	
	# query cache
	if ($c->stash("user_access.$url_path")) {
		return $c->stash("user_access.$url_path");
	}
	
#	say "_has_access '$url':";
	my $row;
	if ($key) {
		my @parameters = (code => "$key", url => $url_path, level => 0 + $access_level);
		$row = $c->neo4j->execute_memory($Q->{access}, 1, ( @parameters ));
#		say Data::Dumper::Dumper $row, \@parameters;
	}
	if ( ! $key || ! $row || $c->skgb->session->expired($row->[1]) ) {
		if (grep( /^$url_path$/, @{$c->config->{public_access}} )) {
#			say "public";
			my $access = {
				user => undef,
				code => undef,
				resource => $url_path,
				access => undef,
			};
			$c->stash("user_access.$url_path", $access);
			return $access;
		}
		
#		say "no";
		return;  # a false value
	}
	
	my $access = {
		user => SKGB::Intern::Model::Person->new( $row->[0] ),
		code => $row->[1],
		resource => $row->[2],
		access => $row->[3],
	};
	$c->stash("user_access.$url_path", $access);
	return $access;
}


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
