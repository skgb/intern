package SKGB::Intern::Verbandsmeldung;

use utf8;
use 5.016;  # enable the full feature package of Perl 5.22 incl. full unicode

#use Data::Dumper;
use Carp;



sub new {
	my ($class, %options) = @_;
	%options{app} or croak 'Mojo app required';  # for database access using skgb.conf
	return bless \%options, $class;
}


# sub app {
# 	my ($self) = @_;
# 	return $self->{app};
# }
sub config {
	my ($self) = @_;
	return $self->{app}->config->{dosb};
}



# am not 100% sure if the date comparison is correct
my $Q = {
  dosb => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[r]-(s:Role)--(:Role{role:'member'})
 WHERE s.role <> 'guest-member'
 AND (NOT has(r.leaves) OR r.leaves >= toString({target}))
 AND r.joined <= toString({target})+'-01-01'
 RETURN p, s, r
 ORDER BY p.born, p.gender, s.role, r.regularContributor
QUERY
  no_berth => REST::Neo4p::Query->new(<<QUERY),
MATCH (b:Boat)--(:Person)-[r]-(s:Role)
 WHERE NOT (b)--(:Berth)
 AND s.role IN ['honorary-member','active-member','passive-member']
 AND (NOT has(r.leaves) OR r.leaves >= toString({target}))
 AND r.joined <= toString({target})+'-01-01'
 RETURN count(b)
QUERY
  berth => REST::Neo4p::Query->new(<<QUERY),
MATCH (b:Boat)--(:Person)-[r]-(s:Role)
 WHERE (b)--(:Berth)
 AND s.role IN ['honorary-member','active-member','passive-member']
 AND (NOT has(r.leaves) OR r.leaves >= toString({target}))
 AND r.joined <= toString({target})+'-01-01'
 RETURN count(b)
QUERY
};
# error in Neo4p:
#RETURN substring(p.born,0,4) AS born, p.gender, s.role, r.regularContributor


sub query {
	my ($self) = @_;
	
	my (undef, undef, undef, undef, undef, $targetYear, undef, undef, undef) = localtime time + 5270400;  # 5270400 seconds = 2 months; target next year from november
	$targetYear += 1900;
	
	my %years = ();
	$Q->{dosb}->execute(target => $targetYear);
	while ( my $row = $Q->{dosb}->fetch ) {
#		my ($born, $gender, $status, $regular) = @$row;
		my ($p, $s, $r) = @$row;
		my $born = substr $p->get_property('born'), 0, 4;
		my $gender = $p->get_property('gender');
		my $status = $s->get_property('role');
		my $regular = $r->get_property('regularContributor');
		
		if ($status eq 'active-member') {
			$status = 'A';
		}
		elsif ($status eq 'passive-member') {
			$status = 'P';
		}
		else {
			$status = $regular ? 'A' : 'P';
		}
		$years{$born} = { M_A => 0, M_P => 0, W_A => 0, W_P => 0 } unless $years{$born};
		$years{$born}->{"${gender}_$status"} += 1;
	}
	$Q->{dosb}->finish;
	
	$self->{years} = \%years;
	$self->{targetYear} = $targetYear;
	
	return $self;
}


# DOSB

sub club_number {
	my ($self, $digits) = @_;
	my $club_ksb = sprintf "%01d%02d%03d", $self->config->{ksb}, $self->config->{gsv}, $self->config->{club};
	return $club_ksb if $digits == 6;
	my $club_lsb = sprintf "%01d%s", $self->config->{rb}, $club_ksb;
	return $club_lsb if $digits == 7 || ! $digits;
	my $club_dosb = sprintf "%02d%02d%s", $self->config->{lsb}, $self->config->{rb}, $club_ksb;
	return $club_dosb if $digits == 10;
	croak 'club number precision must be exactly 6, 7 (default), or 10 digits';
}

sub dosb_filename {
	my ($self) = @_;
	
	my $club_ksb = $self->club_number(6);
	return "${club_ksb}ja.dat";
}

sub dosb {
	my ($self) = @_;
	
	$self->{years} or croak 'illegal state: execute query first';
	my %years = %{$self->{years}};
	
	my (undef, $min, $hour, $mday, $mon, $year, undef, undef, undef) = localtime;
	my $timestamp = sprintf("%02d.%02d.%04d_%02d:%02d", $mday, $mon + 1, $year + 1900, $hour, $min);
	
	my $club = $self->club_number(10);
	my ($pin, $tan) = (" " x 8, " " x 8);
	my @sports = (
		[$self->config->{assn}, $self->config->{sport}],
		[$self->config->{assn}, 0],
		[0, 0],
	);
	
	my @out = ();
	foreach my $sport (@sports) {
		foreach my $year (sort keys %years) {
			my %year = %{$years{$year}};
			push @out, $club, $pin, $tan;
			push @out, sprintf "%04d%04d", @$sport;
			push @out, sprintf "%04d%08d%08d%08d%08d", $year, $year{M_A}, $year{M_P}, $year{W_A}, $year{W_P};
			push @out, "$timestamp\n";
		}
	}
	return wantarray ? @out : join '', @out;
}


# SVNRW

sub _bin_ages {
	my ($self, $max_ages, $out) = @_;
	
	$self->{years} and $self->{targetYear} or croak 'illegal state: execute query first';
	my %years = %{$self->{years}};
	my $targetYear = $self->{targetYear};
	
	my %bins = ();
	foreach (my $i = 0; $i < scalar @$max_ages; $i++) {
		$bins{$max_ages->[$i]} = { M_A => 0, M_P => 0, W_A => 0, W_P => 0 };
		$bins{$max_ages->[$i]}->{min} = $i ? $max_ages->[$i - 1] + 1 : 0;
		$bins{$max_ages->[$i]}->{max} = $max_ages->[$i];
	}
	my $i = -1;
	foreach my $year (sort { $b <=> $a } keys %years) {
		my $age = $targetYear - $year - 1;
		while ($i < 0 || $max_ages->[$i] < $age) {
			push @$out, sprintf "Jg. %4d-%-4d = %2d-%-2d J.\n",
					$targetYear - $max_ages->[$i + 1] - 1,
					$i >= 0 ? $targetYear - $max_ages->[$i] - 2 : $targetYear - 1,
					$i >= 0 ? $max_ages->[$i] + 1 : 0,
					$max_ages->[$i + 1]
					if $out && $self->{verbose} >= 2;
			$i++;
		}
		$bins{$max_ages->[$i]}->{M_A} += $years{$year}->{M_A};
		$bins{$max_ages->[$i]}->{M_P} += $years{$year}->{M_P};
		$bins{$max_ages->[$i]}->{W_A} += $years{$year}->{W_A};
		$bins{$max_ages->[$i]}->{W_P} += $years{$year}->{W_P};
	}
	return %bins;
}

sub _replace_inf {
	my ($self, $replacement, $out) = @_;
	foreach my $out_line (@$out) {
		$out_line =~ s/([0-9])-Inf J/\1$replacement J/;
	}
}

sub svnrw {
	my ($self, %params) = @_;
	$self->{years} and $self->{targetYear} or croak 'illegal state: execute query first';
	
	my @out = ();
	my %bins = $self->_bin_ages( [6, 14, 18, 26, 40, 60, 'Inf'], \@out );
	
	push @out, sprintf "Stichtag 1. 1. %s -- SVNRW\n", $self->{targetYear} if $self->{verbose};
	push @out, "  ";
	foreach my $bin (sort { $a <=> $b } keys %bins) {
		push @out, sprintf "%2d-%-2d J ", $bins{$bin}->{min}, $bins{$bin}->{max};
	}
	push @out, "\n   ";
	foreach my $bin (keys %bins) {
		push @out, " m  w   ";
	}
	push @out, "\nA  ";
	foreach my $bin (sort { $a <=> $b } keys %bins) {
		push @out, sprintf "%2d %2d   ", $bins{$bin}->{M_A}, $bins{$bin}->{W_A};
	}
	push @out, "\nP  ";
	foreach my $bin (sort { $a <=> $b } keys %bins) {
		push @out, sprintf "%2d %2d   ", $bins{$bin}->{M_P}, $bins{$bin}->{W_P};
	}
	$self->_replace_inf($params{infinity}, \@out) if $params{infinity};
	return wantarray ? @out : join '', @out;
}


# DSV

sub dsv {
	my ($self, %params) = @_;
	$self->{years} and $self->{targetYear} or croak 'illegal state: execute query first';
	
	my @out = ();
	my %bins = $self->_bin_ages( [18, 'Inf'], \@out );
	
	push @out, sprintf "Stichtag 1. 1. %s -- DSV\n", $self->{targetYear} if $self->{verbose};
	foreach my $bin (sort { $a <=> $b } keys %bins) {
		push @out, sprintf "%2d-%-2d J  ", $bins{$bin}->{min}, $bins{$bin}->{max};
	}
	push @out, "\n";
	foreach my $bin (keys %bins) {
		push @out, "  m  w   ";
	}
	push @out, "\n";
	foreach my $bin (sort { $a <=> $b } keys %bins) {
		push @out, sprintf " %2d %2d   ", $bins{$bin}->{M_A} + $bins{$bin}->{M_P}, $bins{$bin}->{W_A} + $bins{$bin}->{W_P};
	}
	
	$Q->{berth}->execute(target => $self->{targetYear});
	my $row = $Q->{berth}->fetch;
	push @out, "\nPrivate Boote mit Liegeplatz:  ", @$row;
	$Q->{no_berth}->execute(target => $self->{targetYear});
	my $row = $Q->{no_berth}->fetch;
	push @out, "\nPrivate Boote ohne Liegeplatz: ", @$row;
	
	$self->_replace_inf($params{infinity}, \@out) if $params{infinity};
	return wantarray ? @out : join '', @out;
}






#say Data::Dumper::Dumper(\%bins);


1;

__END__
