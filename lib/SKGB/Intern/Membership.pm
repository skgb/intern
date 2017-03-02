package SKGB::Intern::Membership;

use 5.012;
use utf8;
#use Carp qw( croak );
use Data::Dumper;


# NB: SKGB::Intern::Membership objects contain information about a membership
# that may have existed, may currently exist, may exist in the future, or may
# never exist at all. The mere existence of a Membership /information/ object
# does not signify existence of a membership!


sub new {
	my ($class, $person) = @_;
	defined $person->{relationships} or die "not implemented";
	my $instance = { status_long => "Nichtmitglied" };
	my $self = bless $instance, $class;
	
	my $date = POSIX::strftime('%Y-%m-%d', localtime);
	my $joined = $person->_property('joined', relationship => 'ROLE|GUEST');
	my $leaves = $person->_property('leaves', relationship => 'ROLE|GUEST');
	$self->{joined} = $joined;
	$self->{leaves} = $leaves;
	return $self if $joined && $joined gt $date || $leaves && $leaves lt $date;
	
	my $regular = $person->_property('regularContributor', relationship => 'ROLE|GUEST');
	my $status = $person->_property('role', node => 'Role');
	if ($status eq 'active-member') {
		$status = "Aktiv"
	}
	elsif ($status eq 'passive-member') {
		$status = "Passiv"
	}
	elsif ($status eq 'youth-member') {
		$status = "Jugend"
	}
	elsif ($status eq 'honorary-member') {
		$status = "Ehrenmitglied"
	}
	else {  # probably not a member
		$status = $person->_property('name', node => 'Role');
	}
	$self->{status} = $status;
	$self->{regular} = $regular;
	$self->{guest} = grep {$_->{type} =~ m/^GUEST$/} @{$person->{relationships}};
	
	if ($person->_property('role', node => undef) eq 'honorary-member') {
		$status = $regular ? "Aktiv, $status" : "Passiv, $status";
	}
	if ($self->{guest}) {
		$status .=  ", Gastmitglied";
	}
	$status and $self->{status_long} = $status;
#	say Dumper $self, $person;
	
	return $self;
}

 
1;
