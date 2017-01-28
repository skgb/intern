package SKGB::Intern::Command::forcereset;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long 2.33 qw(GetOptionsFromArray :config posix_default gnu_getopt no_auto_abbrev no_ignore_case);
use Data::Dumper;

has description => 'Force Login Fail Counter Reset';
has usage => sub { shift->extract_usage };


sub run {
	my ($self, @args) = @_;
	GetOptionsFromArray \@args;
	
	$self->app->skgb->reset_login_fails(force => 1);
}


1;

__END__

=pod

=head1 NAME

forcereset - Force Login Fail Counter Reset

=head1 SYNOPSIS

 script/skgb_intern.pl forcereset -m production

=head1 DESCRIPTION

When the system is locked out for login after too many failures, this command
will force an immediate reset of the login failure counters. The cron command
should automatically reset these counters after a certain period, but at times
it may be expedient to expedite that process; that's what this command is for.

=head1 OPTIONS

=over

=item B<--help>

Display a help message and exit.

=back

=head1 AUTHOR

Copyright (c) 2017 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
