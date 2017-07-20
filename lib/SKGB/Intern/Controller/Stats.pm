package SKGB::Intern::Controller::Stats;
use Mojo::Base 'Mojolicious::Controller';

use SKGB::Intern::Verbandsmeldung;


sub dosb {
	my ($self) = @_;
	
	return $self->reply->forbidden unless $self->skgb->may;
	
	my $stats = SKGB::Intern::Verbandsmeldung->new( app => $self->app, verbose => 1 )->query;
	
	return $self->render(stats => $stats);
}
	
1;
