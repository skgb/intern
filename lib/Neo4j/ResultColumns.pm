package Neo4j::ResultColumns;

use 5.016;
use utf8;

#use Devel::StackTrace qw();
use Data::Dumper qw();
use Carp qw(croak);


# sub test {
# 	my ($self) = @_;
# 	say Data::Dumper::Dumper $self;
# }


sub new {
	my ($class, $result) = @_;
	
	my $columns = $result->{columns};
	my $column_keys = {};
#	say "[[[[ ", Data::Dumper::Dumper $columns;
#	if (scalar(@$columns) == 1 && $columns->[0] =~ m/^\[(.*)\]$/) {
		# strange result format -- possibly a permanent bug in Neo4j?
		# no -- looks more like my query requested columns inside of an array
		# TODO: compare actual column number instead of just checking for braces; also: make sure that this "bug" is indeed to be expected in the result
#		my @columns = split m/\s*,\s*/, $1;
#		$columns = \@columns;
#		say "++++ ", Data::Dumper::Dumper $columns;
#	}
	for (my $f = scalar(@$columns) - 1; $f >= 0; $f--) {
		$column_keys->{$columns->[$f]} = $f;
		$column_keys->{$f} = $f;
	}
	
	return bless $column_keys, $class;
#	say "]]]] ", Data::Dumper::Dumper $column_keys;
#	return $column_keys;
}


sub key {
	my ($self, $key) = @_;
	
	return $self->{$key};
}


sub add {
	my ($self, $column) = @_;
	
	my $index = $self->count;
	$self->{$column} = $self->{$index} = $index;
	return $index;
}


sub count {
	my ($self) = @_;
	
	my $column_count = (scalar keys %$self) >> 1;  # each column has two hash entries (numeric and by name)
	return $column_count;
}


1;

__END__
