package SKGB::Intern::Plugin::AuthManager;
use Mojo::Base 'Mojolicious::Plugin';

use REST::Neo4p;
use String::Random;
use List::Util;
use POSIX qw();
use DateTime::Format::ISO8601;
use Data::Dumper;

use SKGB::Intern::Model::Person;

use Mojolicious::Plugin::Authorization;


my $Q = {
  access => REST::Neo4p::Query->new(<<QUERY),
MATCH (c:AccessCode)-[:IDENTIFIES]->(p:Person)-[a:IS_A|IS_A_GUEST|ACCESS*..3]->(r:Resource)
 WHERE c.code = {code}
 AND any(y IN r.urls WHERE {url} =~ y)
 AND coalesce(last(a).level, 1) >= toInt({level})
 AND type(last(a)) = 'ACCESS' AND single(x IN a WHERE type(x) = 'ACCESS')
 RETURN p, c, r, last(a)
 ORDER BY last(a).level DESC
 LIMIT 1
QUERY
};


sub register {
	my ($self, $app, $args) = @_;
	$args ||= {};
	
	my @helpers = qw( link_auth_to has_access );
	$app->helper($_ => __PACKAGE__->can("_$_")) for @helpers;
	
	
}


# TODO: unit testing
sub _has_access {
	my ($c, $url, $access_level, $key) = @_;
	$url ||= $c->url_for;  # TODO: This is the canonical URL, not the actual URL. Is this secure enough?
	$access_level ||= 1;
	$key ||= $c->session('key');
	my $url_path = ref $url ? "" . $url->path : $url;
	
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
	
	# Content/Captures logic lifted directly from _link_to helper in Mojo 6.37
	
	# Content
	unless (ref $_[-1] eq 'CODE') {
		@url = (shift);
		push @_, $content;
	}
	
	# Captures
	push @url, shift if ref $_[0] eq 'HASH';
	
	my $url = $c->url_for(@url);
	return $c->tag('a', class => 'no-access', @_) if ! $c->has_access($url);
	return $c->tag('a', href => $url, @_);
}


1;
