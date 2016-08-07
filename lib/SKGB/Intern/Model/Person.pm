package SKGB::Intern::Model::Person;

use 5.012;
use utf8;
use Carp qw( croak );
use List::MoreUtils qw( none );
use REST::Neo4p;
use SKGB::Intern::Plugin::Neo4j;
use Data::Dumper;


my $Q = {
  membership => REST::Neo4p::Query->new(<<QUERY),
MATCH a=(p:Person)-[:IS_A|IS_A_GUEST*]->(:Role {role:'member'})
 WHERE id(p) = {node}
 RETURN a
 LIMIT 1
QUERY
};


sub new {
	my ($class, $neo4jNode) = @_;
	my $instance = {
		_node => undef,
		_simple => undef,
		name => undef,
		name_sortable => undef,
		name_salutation => undef,
		membership => undef,
	};
	if ( ref $neo4jNode eq "REST::Neo4p::Node" ) {
		$instance->{_node} = $neo4jNode;
#		$instance->{_simple} = $neo4jNode->as_simple;  # DEBUG
	}
	elsif ( ref $neo4jNode eq "HASH" ) {
		$instance->{_simple} = $neo4jNode;
	}
	else {
		croak "Neo4j node required";
		return undef;
	}
	return bless $instance, $class;
}


sub new_membership {
	my ($class, $neo4jPath) = @_;
#	say Data::Dumper::Dumper $neo4jPath;
	if ( ref $neo4jPath eq "REST::Neo4p::Path" ) {
		$neo4jPath = $neo4jPath->as_simple;  # very slow due to REST::Neo4p::Path having to reload all entities from the server as their metadata is not in the original response (Neo4p uses the deprecated cypher endpoint of Neo4j)
	}
	elsif ( ref $neo4jPath eq "ARRAY" && scalar @$neo4jPath ) {
		if ( ref $neo4jPath->[0] eq "REST::Neo4p::Node" ) {
			# seems the 'fast' query was used
			$neo4jPath = [
				$neo4jPath->[0]->as_simple,
				$neo4jPath->[1]->as_simple,
				$neo4jPath->[2]->as_simple,
			];
		}
		# else: do nothing (seems path query was used with ResponseAsObjects=0, which means the result is already in the format we need)
	}
	else {
		croak "Neo4j path required";
		return undef;
	}
	my $instance = bless {}, $class;
#	my $instance = $class->new( ($neo4jPath->nodes)[0] );
	$instance->{_simple} = $neo4jPath->[0];
	$instance->membership($neo4jPath);
#	say Data::Dumper::Dumper $instance;
	return $instance;
}


sub _property {
	my ($self, $key, $path, $skip) = @_;
	$skip ||= 0;
	
	if ( ! $path ) {
		$self->{_simple} = $self->{_node}->as_simple if ! $self->{_simple};
		return $self->{_simple}->{$key};
	}
	
	foreach my $item (@$path) {
		next if $skip-- > 0;
		return $item->{$key} if $item->{$key};
	}
	return undef;
}


sub equals {
	my ($self, $other) = @_;
	return $self->node_id == $other->node_id;
}


sub node_id {
	my ($self, $other) = @_;
	return 0 + $self->{_simple}->{_node} if $self->{_simple};
	return 0 + $self->{_node}->id if $self->{_node};
	die "node id unknown";
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
	return @emails if @emails;
	
	# try non-primary addresses if no primaries are found
	foreach my $rel (@rels) {
		next if $rel->type ne 'FOR';
		my $start_node = $rel->start_node;
		next if $start_node->get_property('type') ne 'email';
		my $email = $start_node->get_property('address');
		next if ! $email;
		push @emails, $email;
	}
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
	return $self->{membership} if $self->{membership};
	
	$self->{membership} = { status_long => "Nichtmitglied" };
	if (! $path) {
		my $row = SKGB::Intern::Plugin::Neo4j::execute_memory($Q->{membership}, 1, (node => $self->node_id));
		return $self->{membership} if ! $row->[0];
#		my @nodes = $row->[0]->nodes;
#		my @rels = $row->[0]->relationships;
		$path = $row->[0]->as_simple;
# 		while (my $n = shift @nodes) {
# 			my $r = shift @relns;
# 			print $r ? $n->id."-".$r->id."->" : $n->id."\n";
# 		}
	}
	
	my $date = POSIX::strftime('%Y-%m-%d', localtime);
	my $joined = $self->_property('joined', $path);
	my $leaves = $self->_property('leaves', $path);
	return $self->{membership} if $joined && $joined gt $date || $leaves && $leaves lt $date;
	
	my $regular = $self->_property('regularContributor', $path);
	my $status = $self->_property('name', $path, 1);  # hack: path item 0 is the :Person
	$self->{membership}->{status} = $status;
	$self->{membership}->{regular} = $regular;
	$self->{membership}->{guest} = $self->_property('_type', $path) eq 'IS_A_GUEST';
	$self->{membership}->{joined} = $joined;
	$self->{membership}->{leaves} = $leaves;
	
	if ($self->_property('role', $path) eq 'honorary-member') {
		$status = $regular ? "Aktiv, $status" : "Passiv, $status";
	}
	if ($self->{membership}->{guest}) {
		$status .=  ", Gastmitglied";
	}
	$self->{membership}->{status_long} = $status;
	
	return $self->{membership};
}


# sub membership_old {
# 	my ($self) = @_;
# 	return $self->{membership} if $self->{membership};
# 	
# 	$self->{membership} = { status_long => "Nichtmitglied" };
# 	my $row = SKGB::Intern::Plugin::Neo4j::execute_memory($Q->{membership}, 1, (node => 0 + $self->{node}->id));
# 	return $self->{membership} if ! $row->[0];
# #	my @nodes = $row->[0]->nodes;
# #	my @rels = $row->[0]->relationships;
# 	my $path = $row->[0]->as_simple;
# # 	while (my $n = shift @nodes) {
# # 		my $r = shift @relns;
# # 		print $r ? $n->id."-".$r->id."->" : $n->id."\n";
# # 	}
# 	
# 	my $date = POSIX::strftime('%Y-%m-%d', localtime);
# 	my $joined = $self->_property('joined', $path);
# 	my $leaves = $self->_property('leaves', $path);
# 	return $self->{membership} if $joined && $joined ge $date || $leaves && $leaves lt $date;
# 	
# 	my $regular = $self->_property('regularContributor', $path);
# 	my $status = $self->_property('name', $path, 1);  # hack: path item 0 is the :Person
# 	$self->{membership}->{status} = $status;
# 	$self->{membership}->{regular} = $regular;
# 	$self->{membership}->{guest} = $self->_property('_type', $path) eq 'IS_A_GUEST';
# 	$self->{membership}->{joined} = $joined;
# 	$self->{membership}->{leaves} = $leaves;
# 	
# 	if ($self->_property('role', $path) eq 'honorary-member') {
# 		$status = $regular ? "Aktiv, $status" : "Passiv, $status";
# 	}
# 	if ($self->{membership}->{guest}) {
# 		$status .=  ", Gastmitglied";
# 	}
# 	$self->{membership}->{status_long} = $status;
# 	
# 	return $self->{membership};
# }
# 
# 
# sub membership_oldest {
# 	my ($self) = @_;
# 	return $self->{membership} if $self->{membership};
# 	
# 	my @rels = $self->{node}->get_outgoing_relationships();
# 	my $date = POSIX::strftime('%Y-%m-%d', localtime);
# 	my ($status, $status_long, $membership);
# 	foreach my $rel (@rels) {
# 		next if $rel->type ne 'IS_A' && $rel->type ne 'IS_A_GUEST';
# 		my $role = $rel->end_node->get_property('role');
# 		next if $role eq 'user';  # TODO: hack; verify that this role really is a member role
# #		say $self->name ." ". $role;
# 		$membership = $rel;
# 		
# 		$status = $membership->end_node->get_property('name');
# 		if ($role eq 'honorary-member') {
# 			if ($membership->get_property('regularContributor')) {
#  				$status_long = "Aktiv, $status";
#  			}
#  			else {
#  				$status_long = "Passiv, $status";
#  			}
#  		}
# 		if ($status && $membership->type eq 'IS_A_GUEST') {
# 			$status .=  ", Gastmitglied";
# 		}
# 		$status_long ||= $status;
# 		if ($membership->get_property('joined')) {
# 			
# 		}
# 		my ($joined, $leaves) = ( $membership->get_property('joined'), $membership->get_property('leaves') );
# 		$status = undef if $joined && $joined ge $date ||  $leaves && $leaves lt $date;
# 		if (! $status) {
# 			$status_long = "Nichtmitglied";
# #			print $fh $mandate{umr} && $Gbetrag eq "0,00" ? "Nichtmitglied, Kontoinhaber" : "Nichtmitglied" if ! $status;
# 		}
# 		last;
# 	}
# 	
# 	$self->{membership} = { status_long => $status_long };
# 	if ($membership) {
# 		$self->{membership}->{status} = $status;
# 		$self->{membership}->{regular} = $membership->get_property('regularContributor');
# 		$self->{membership}->{guest} = $membership->type eq 'IS_A_GUEST';
# 		$self->{membership}->{joined} = $membership->get_property('joined');
# 		$self->{membership}->{leaves} = $membership->get_property('leaves');
# 	}
# 	return $self->{membership};
# }

 
1;
