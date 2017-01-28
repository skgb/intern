package SKGB::Intern::Command::cron;
use Mojo::Base 'Mojolicious::Command';

use Getopt::Long 2.33 qw(GetOptionsFromArray :config posix_default gnu_getopt no_auto_abbrev no_ignore_case);
use Data::Dumper;

use SKGB::Intern::AccessCode;

has description => 'Run Scheduled Services';
has usage => sub { shift->extract_usage };


sub run {
	my ($self, @args) = @_;
	GetOptionsFromArray \@args;
	
	say "SKGB-intern cron ", SKGB::Intern::AccessCode::new_time;
	
	$self->app->skgb->reset_login_fails;
}


1;

__END__

=pod

=head1 NAME

cron - Run Scheduled Services

=head1 SYNOPSIS

Put something like this into the crontab of the system running SKGB-intern:

 */6 * * * * root cd /srv/intern && /opt/perlbrew/bin/perlbrew --root /opt/perlbrew exec script/skgb_intern.pl cron -m production > /dev/null

=head1 DESCRIPTION

This command should be run at scheduled intervals by the system cron daemon
in order to execute regular maintenance and other services for SKGB-intern.
Instead of routing stdout to /dev/null it can also be routed to a log file.
Errors will be printed to stderr and will normally be reported to root by the
cron daemon.

=head1 OPTIONS

=over

=item B<--help>

Display a help message and exit.

=back

=head1 AUTHOR

Copyright (c) 2017 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
