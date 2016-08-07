package SKGB::Intern::Controller::Stats;
use Mojo::Base 'Mojolicious::Controller';

use SKGB::Intern::Verbandsmeldung;


sub dosb {
	my ($self) = @_;
	
	if ( ! $self->has_access ) {
		return $self->render(template => 'key_manager/forbidden', status => 403);
	}
	
	my $stats = SKGB::Intern::Verbandsmeldung->new( app => $self->app, verbose => 1 )->query;
	
	return $self->render(stats => $stats);
}
	
1;
