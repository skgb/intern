package SKGB::Intern::Person;

use 5.012;
use utf8;
use Carp qw( croak );
use Data::Dumper;

use SKGB::Intern::Membership;


sub new {
	my ($class, $person, $relationships) = @_;
	my $instance = {
		node => $person,
		relationships => $relationships,
		name => undef,
		name_sortable => undef,
		name_salutation => undef,
		membership => undef,
	};
	if (! $person || ! $person->{id} || ! $person->{labels} || ! $person->{properties}) {
		croak "Neo4j node required (did you request a graph result?)";
		return undef;
	}
	return bless $instance, $class;
}


sub _property {
	my ($self, $key, $path, $search) = @_;
	
	if ( ! $path ) {
		return $self->{node}->{properties}->{$key};
	}
	
	if ($path eq 'relationship') {
		foreach my $item (@{$self->{relationships}}) {
			next if $search && $item->{type} !~ m/^$search$/;
			return $item->{properties}->{$key};
		}
	}
	if ($path eq 'node') {
		foreach my $item (@{$self->{relationships}}) {
			next if $search && ! grep m/^$search$/, @{$item->{node}->{labels}};
			return $item->{node}->{properties}->{$key};
		}
	}
#	grep m/^$person->{id}$/, @rel_nodes;
	
# 	foreach my $item (@$path) {
# 		next if $skip-- > 0;
# 		return $item->{$key} if $item->{$key};
# 	}
	return undef;
}


sub equals {
	my ($self, $other) = @_;
	return $self->node_id == $other->node_id;
}


sub node_id {
	my ($self, $other) = @_;
	return 0 + $self->{node}->{id} if $self->{node};
	die "node id unknown";
}


sub handle {
	my ($self) = @_;
	return $self->legacy_user if $self->legacy_user;
	return $self->node_id;
}


sub name {
	my ($self) = @_;
	return $self->{name} if $self->{name};
	return $self->{name} = $self->_property('name');
}


sub name_sortable {
	my ($self) = @_;
	return $self->{name_sortable} if $self->{name_sortable};
	
	my $prefix = $self->_property('prefix');  # e. g. "Dr."
	$self->name =~ m/^(.*) (.*)$/ or return $self->name;
	return $self->{name_sortable} = "$2, $1" . ($prefix ? " $prefix" : "");
}


sub name_part {
	my ($self, $last) = @_;
	$self->name =~ m/^(.*) (.*)$/ or return $self->name;
	return $last ? $2 : $1;
}


sub name_salutation {
	my ($self) = @_;
	return $self->{name_salutation} if $self->{name_salutation};
	my $salutation = $self->_property('salutation');
	return $self->{name_salutation} = $salutation if $salutation;
	return $self->{name_salutation} = "Hallo " . $self->name_part(0);
}


sub primary_emails {
	my ($self) = @_;
	my @emails = ();
	my @rels = $self->{_node}->get_incoming_relationships();
	
	foreach my $rel (@rels) {
		next if $rel->type ne 'FOR';
		next if ! $rel->get_property('primary');
		my $start_node = $rel->start_node;
		next if $start_node->get_property('type') ne 'email';
		my $email = $start_node->get_property('address');
		next if ! $email;
		push @emails, $email;
	}
# Non-primary addresses only make sense for the key factory, and *that* only makes sense once users are able to modify their own addresses. Meanwhile, non-primary addresses are a problem for the interim person report page in the 'member_list/node' template, where the email facade should only show for primary addresses.
# 	return @emails if @emails;
# 	
# 	# try non-primary addresses if no primaries are found
# 	foreach my $rel (@rels) {
# 		next if $rel->type ne 'FOR';
# 		my $start_node = $rel->start_node;
# 		next if $start_node->get_property('type') ne 'email';
# 		my $email = $start_node->get_property('address');
# 		next if ! $email;
# 		push @emails, $email;
# 	}
	return @emails;
}


sub age {
	my ($self) = @_;
	my ($day, $month, $year) = (localtime)[3..5];
	$self->_property('born') =~ m/^(\d{4})(?:-([01Q]\d)(?:-(\d\d))?)?/;
	my $born_year = $1 or return '';
	my $born_month = $2;
	my $born_day = $3;
	my $age_year = $year + 1900 - $born_year;
	if ($born_month) {
		if ($born_month =~ m/^Q/) {
			$born_month = 3 * (substr($born_month, 1) - 1) + 1;
			$age_year -= 1 if 1 + $month < 0 + $born_month;
			my $age_month = ($month + 1 - $born_month + 12) % 12;
			$age_year = " $age_year" if $age_year < 10;  # surprised this works in DataTables...
			return "${age_year}¾" if $age_month >= 9;
			return "${age_year}½" if $age_month >= 6;
			return "${age_year}¼" if $age_month >= 3;
			return $age_year;
		}
		die; # exact date: not currently used
#		$age -= 1 unless sprintf("%02d%02d", $month, $day) >= sprintf("%02d%02d", $birth_month, $birth_day);
	}
	return $age_year;
}


sub legacy_user {
	my ($self) = @_;
	return $self->_property('userId');
}


sub gs_verein_id {
	my ($self) = @_;
	return $self->_property('gsvereinId');
}


sub membership {
	my ($self, $path) = @_;
	die "not implemented" if $path;
	
	$self->{membership} = SKGB::Intern::Membership->new( $self ) if ! $self->{membership};
	return $self->{membership};
}

 
1;
