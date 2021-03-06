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
	if (! $person || ! defined $person->{id} || ! $person->{labels} || ! $person->{properties}) {
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
	return 1 if $self == $other;
	return $self->node_id == $other->node_id if defined $self->node_id && defined $other->node_id;
	return $self->handle eq $other->handle if defined $self->handle && defined $other->handle;
	croak "equals not decidable: neither id nor handle known for both objects";
}


sub node_id {
	my ($self) = @_;
	return 0 + $self->{node}->{id} if $self->{node} && defined $self->{node}->{id};
	return undef;
	# NB: 0 is a valid node ID in Neo4j
}


sub handle {
	my ($self) = @_;
	return $self->_property('handle') if $self->_property('handle');
	return $self->_property('userId') if $self->_property('userId');
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
	
	my $name_sortable = $self->_property('nameSortable');
	return $self->{name_sortable} = $name_sortable if $name_sortable;
	
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
	$month += 1;  # month is 0-based
	$self->_property('born') =~ m/^(\d{4})(?:-([01Q]\d)(?:-(\d\d))?)?/;
	my $born_year = $1 or return '';
	my $born_month = $2;
	my $born_day = $3;
	my $age_year = $year + 1900 - $born_year;
	my $age_month = 0;
	if ($born_month) {
		if ($born_month =~ m/^Q/) {
			$born_month = 3 * (substr($born_month, 1) - 1) + 1;
		}
		$age_year -= 1 if $month < 0 + $born_month;
		$age_month = ($month - $born_month + 12) % 12;
	}
	if ($born_day) {
		$age_month -= 1 if $day < 0 + $born_day;
#		# :BUG: doesn't take into account months with different lengths
#		my $age_day = ($day - $born_day + 30) % 30;
	}
	# Even if the exact birthday is recorded in the database, we elect to only display the approximate age as it is good enough for most purposes.
	$age_year = " $age_year" if $age_year < 10;  # surprised this works in DataTables...
	return "${age_year}¾" if $age_month >= 9;
	return "${age_year}½" if $age_month >= 6;
	return "${age_year}¼" if $age_month >= 3;
	return $age_year;
}


sub legacy_user {
	my ($self) = @_;
	return $self->_property('userId') if $self->_property('userId');
	return $self->_property('handle');
}


# Query builder for this Person node.
#  $r = $t->run($user->query("p", "SET p.skills = {skills}"), skills => "Perl");
sub query {
	my ($self, $var, $clause) = @_;
	my ($where, $_person);
	if (defined $self->node_id) {
		$where = "id($var) = {_person}";
		$_person = $self->node_id;
	}
	elsif (defined $self->handle) {
		$where = "$var.handle = {_person} OR NOT exists($var.handle) AND $var.userId = {_person}";
		$_person = $self->handle;
		die "Cypher query build for Person '$_person' failed: id unknown";  # debug only: there is no reason to die here if a handle is available, since those should be unique
	}
	else {
		croak "Cypher query build for Person failed: id and handle unknown";
	}
	return ("MATCH ($var:Person) WHERE ($where) $clause", _person => $_person);
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
