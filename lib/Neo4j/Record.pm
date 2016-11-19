package Neo4j::Record;

use 5.016;
use utf8;

#use Devel::StackTrace qw();
use Data::Dumper qw();
use Carp qw(croak);


# sub test {
# 	my ($self) = @_;
# 	say Data::Dumper::Dumper $self;
# }


sub get {
	my ($self, $field) = @_;
	
	return $self->{row}->[0] if ! defined $field;
	return $self->{row}->[ $self->{column_keys}->key($field) ];
}


1;

__END__
