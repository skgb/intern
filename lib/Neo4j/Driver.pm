package Neo4j::Driver;

use 5.016;
use utf8;

our $VERSION = 0.01;

#use Devel::StackTrace qw();
#use Data::Dumper qw();
use Carp qw(croak);

use URI;
use REST::Client;
use Neo4j::Session;


=pod

=head1 NAME

Neo4j::Driver - Perl implementation of a Neo4j REST driver.

=head1 SYNOPSIS

 my $d = Neo4j::Driver->new("localhost")->basic_auth("neo4j", "pass");
 my $s = $d->session;
 my $t = $s->begin_transaction;
 my $r = $t->run("MATCH p:Person WHERE p.name = {n} RETURN a", {n => "Arne Johannessen"});
 #my $l = $t->list;
 foreach my $p (@$r) {
 #    print $p->{name}, " ", $p->{born};
     print $p->get('name'), " ", $p->get('born');
 }
 $t->commit;
 #$t->rollback;
 $s->close;
 $d->close;

=head1 DESCRIPTION

...

=cut


our $CONTENT_TYPE = 'application/json; charset=UTF-8';


sub new {
	my ($class, $uri) = @_;
	
	if ($uri) {
		$uri =~ s|^|http://| if $uri !~ m{:|/};
		$uri = URI->new($uri);
#		croak "Only the REST interface is supported [$uri]" if $uri->scheme eq 'bolt';
		croak "Only the 'http' URI scheme is supported [$uri]" if $uri->scheme ne 'http';
		croak "Hostname is required [$uri]" if ! $uri->host;
		$uri->port(7474) if ! $uri->port;
	}
	else {
		$uri = URI->new("http://localhost:7474");
	}
	
	return bless { uri => $uri, die_on_error => 1 }, $class;
}


sub basic_auth {
	my ($self, $username, $password) = @_;
	
	$self->{auth} = {
		scheme => 'basic',
		principal => $username,
		credentials => $password,
	};
	$self->{client} = undef;  # ensure the next call to _client picks up the new credentials
	
	return $self;
}


sub _client {
	my ($self) = @_;
	
	# lazy initialisation
	if ( ! $self->{client} ) {
		my $uri = $self->{uri};
		if ($self->{auth}) {
			croak "Only HTTP Basic Authentication is supported" if $self->{auth}->{scheme} ne 'basic';
			$uri = $uri->clone;
			$uri->userinfo( $self->{auth}->{principal} . ':' . $self->{auth}->{credentials} );
		}
		
		$self->{client} = REST::Client->new({
			host => "$uri",
			timeout => 60,
			follow => 1,
		});
		$self->{client}->addHeader('Accept', $CONTENT_TYPE);
		$self->{client}->addHeader('Content-Type', $CONTENT_TYPE);
		$self->{client}->addHeader('X-Stream', 'true');
	}
	
	return $self->{client};
}


sub session {
	my ($self) = @_;
	
	return Neo4j::Session->new($self);
}


sub run {
	my ($self, $query, @parameters) = @_;
	
	return $self->session->run($query, @parameters);
}


sub close {
}



1;

__END__

http://neo4j.com/docs/developer-manual/3.0/http-api/#http-api-transactional

https://neo4j.com/docs/rest-docs/current/#rest-api-service-root


***********************
http://neo4j.com/docs/developer-manual/3.0/drivers/#driver-use-the-driver


https://metacpan.org/pod/REST::Client
https://metacpan.org/pod/JSON::MaybeXS
http://stackoverflow.com/questions/14591444/which-perl-module-would-you-recommend-for-json-manipulation
http://perlmaven.com/comparing-the-speed-of-json-decoders






=pod

=head1 ENVIRONMENT

It is unknown whether this class works with Neo4j 1.x or 3.x.
It has only been tested with Neo4j 2.3.

=head1 DIAGNOSTICS

=over

=item B<msg>

info

=back

=head1 BUGS

Please report all bugs at
L<http://software.thaw.de/bugs/set_project.php?project_id=11&ref=bug_report_advanced_page.php>.

=head1 AUTHOR

Arne Johannessen, L<mailto:arne@thaw.de>

=head1 COPYRIGHT

Copyright (c) 2016 Arne Johannessen
All rights reserved.

=cut
