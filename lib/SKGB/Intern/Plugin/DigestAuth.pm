package SKGB::Intern::Plugin::DigestAuth;
use Mojo::Base 'Mojolicious::Plugin';

use Fcntl qw(:flock SEEK_SET SEEK_END);
#use Data::Dumper;
use Digest::MD5;
use Mojo::Util qw(md5_sum);
use Carp qw( croak );

sub register {
	my ($self, $app, $args) = @_;
	
	
	# Update the htdigest auth file for the red-legacy authentication scheme,
	# which was based on HTTP Digest Auth.
	$app->helper('skgb.legacy.digestauth' => sub {
		my ($c, $person, $code) = @_;
		$person && $code or croak "Cannot modify htdigest: person and code required";
		
		# (Looks like actually HTTPD::UserAdmin might already implement this... whatever.)
		# (also note Mojo::Util#slurp and Mojo::Util#spurt)
		
		# compose the digest auth line
		my $legacy_user = $person->legacy_user() or return;  # skip htdigest for users with no legacy user id
		my $realm = $app->config->{legacy}->{digest_realm};
		my $digest_line = "$legacy_user:$realm:";
		$digest_line .= Digest::MD5::md5_hex( $digest_line . $code );  # will croak if non-ASCII chars are present ... which shouldn't happen for SKGB-intern
die 'a' if md5_sum($digest_line) ne Digest::MD5::md5_hex($digest_line);
		
		# read htdigest file
		# NB: the locking is not 100% reliable, see flock docs
		open( my $fh, '+<', $app->config->{legacy}->{htdigest_path} ) or die "Cannot open htdigest: $!";
		flock($fh, LOCK_EX) or die "Cannot lock htdigest: $!";
		local $/ = undef;
		my $htdigest = <$fh>;
		
		# modify or append the digest auth line
		my $pattern = '(\s)' . quotemeta($legacy_user) . ':' . quotemeta($realm) . ':\S*';
		if ( $htdigest =~ s/$pattern/$1$digest_line/ ) {
			seek($fh, 0, SEEK_SET) or die "Cannot seek htdigest: $!";
			truncate($fh, 0) or die "Cannot truncate htdigest: $!";
			print $fh $htdigest;
		}
		else {
			seek($fh, 0, SEEK_END) or die "Cannot seek htdigest: $!";
			print $fh "$digest_line\n";
		}
		
		# clean up
		flock($fh, LOCK_UN) or die "Cannot unlock htdigest: $!";
		close($fh) or warn "Closing htdigest failed: $!";
	});
	
}

 
1;


__END__

Userinfo (i.e., username and password) are now disallowed in HTTP and
HTTPS URIs, because of security issues related to their transmission
on the wire.

https://tools.ietf.org/html/rfc7230#page-18
