package SKGB::Intern::Controller::NotFound;
use Mojo::Base 'Mojolicious::Controller';

#use Data::Dumper;


my @REDIRECT_STATUS = (301, 302, 303, 305, 307, 308);

our $redirect_file = 'conf/not_found.conf';
our %error_template = ( '4xx' => 'not_found.production', '5xx' => 'exception.production' );
our %default = ( redirect => 301, error => 410 );


sub redirect {
	my ($c) = @_;
	
	$c->app->plugin('Config' => {file => $redirect_file}) if ! $c->config->{not_found};
	
	# try and find a matching redirect rule
	my ($status, $url) = (undef, $c->req->url->path->canonicalize->to_string);
	my @redirects = @{ $c->config->{not_found}->{redirect} };
	for (my $i = 0; $i < @redirects; $i += 2) {
		my ($from, $to) = @redirects[$i, $i + 1];
		next if $url !~ m/^$from$/;
		($status, $to) = ($1, $2) if $to =~ m/^([0-9]{3})(?::|$)(.*)/;
		
		if ($to eq '') {
			$status //= $default{error};
			my $template = $error_template{ $status =~ m/^4/ ? '4xx' : '5xx' };
			return $c->render(template => $template, status => $status);
		}
		
		# determine new location
		eval "\$url =~ s\%^$from\$\%$to\%";
		my $base = $c->req->url->clone;
		$base->scheme($base->base->scheme);
		$base->host($base->base->host);
		$base->port($base->base->port);
		my $target = Mojo::URL->new($url)->base($base)->query( $c->req->url->query );
		$url = $target->to_abs->to_string;
		
		$c->res->code($status // $default{redirect});
		return $c->redirect_to($url);
	}
	
	$c->reply->not_found;
	
}


1;

__END__

=pod

=head1 NAME

SKGB::Intern::Controller::NotFound - Controller base class

=head1 SYNOPSIS

 # after preparing all other routes
 $app->routes->get('/*path')->to('not_found#redirect');

 # redirect config file
 { not_found => { redirect => [
     '/example/gone' => 410,
     '/example/moved' => '/new/location',
     '/(example/temporary)' => '307://other.server.example/$1',
 ] } }

=head1 DESCRIPTION

This controller provides a single action that can be routed to as a last resort
to provide useful redirections when resources have moved.

Redirect rules are given in a configuration file in regular expression syntax.
As of version 2.0.0-a21, this feature is highly experimental and likely to be
removed in favour of plain strings. NB: This feature is a security risk if the
config file is writeable by other people! Make sure to restrict access as
necessary.

When rules give a specific HTTP status code, it should only be a 3xx redirect
code or a 4xx/5xx error code. The behaviour of redirect rules specifying a
1xx/2xx code is undefined.

=head1 SEE ALSO

L<https://www.w3.org/Provider/Style/URI>

=head1 AUTHOR

Copyright (c) 2017 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
