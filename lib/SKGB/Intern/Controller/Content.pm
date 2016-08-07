package SKGB::Intern::Controller::Content;
use Mojo::Base 'Mojolicious::Controller';


sub index {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
#	return $self->render(template => 'content/index', logged_in => $user);
	return $self->render(logged_in => $user);
}


sub content {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user);
}


sub wetter {
	my ($self) = @_;
	
	my $user = $self->skgb->session->user;
	return $self->render(logged_in => $user);
}
	
1;
