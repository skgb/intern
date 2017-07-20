package SKGB::Intern::Plugin::Legacy;
use Mojo::Base 'Mojolicious::Plugin';

use Fcntl qw(:flock SEEK_SET SEEK_END);
use Mojo::Util qw(b64_encode);
use Carp qw(croak);
use Try::Tiny;

use Mojolicious::Plugin::ReverseProxy 0.705_001;
use SKGB::Intern::Plugin::AuthManager;

sub register {
	my ($self, $app, $args) = @_;
	
	
	my $legacy_url = $app->config->{legacy}->{legacy_url};
	my $proxy_base = $app->config->{legacy}->{proxy_base};
	my $mount_point = $args->{mount_point} // '/digest';
	$app->plugin('Mojolicious::Plugin::ReverseProxy', {
		destination_url => $legacy_url,
		routes => $app->routes,
		mount_point => $mount_point,
		req_processor => sub {
			my ($c, $req) = @_;
			
			my $user = $c->skgb->session->user;
			$user or return $c->redirect_to($c->url_for('login')->query( target => $c->url_with ));
#			$user->membership->{status} or return $c->reply->forbidden;
			# TODO: should we exclude users with no primary email here, or rather handle that through roles?
			
			my $password = $c->skgb->legacy->password($user);
			my $hash = b64_encode $user->handle . ":$password";
			chomp $hash;
			$req->headers->authorization("Basic $hash");
			$req->headers->user_agent($req->headers->user_agent . " SKGB-intern/$SKGB::Intern::VERSION");
			
			$c->app->log->debug("Reverse proxy to " . $req->url);
		},
		res_processor => sub {
			my ($c, $res) = @_;
			
			if (my $location = $res->headers->location) {
				if ($location =~ s{\Q$legacy_url\E}{$proxy_base$mount_point/}) {
					$res->headers->location($location);
				}
			}
			if ($res->headers->content_type =~ m{text/} and my $body = $res->body) {
				my $i = 0;
				$i += $body =~ s{(HREF|SRC|CITE|LONGDESC|USEMAP|ACTION|DATA|CODEBASE)=(["'])\Q$legacy_url\E}{$1=$2/}gi;
				$i += $body =~ s{(HREF|SRC|CITE|LONGDESC|USEMAP|ACTION|DATA|CODEBASE)=(["'])(/|/[^/][^"']*)(["'])}{$1=$2$mount_point$3$4}gi;
				$i += $body =~ s{(HREF|SRC|CITE|LONGDESC|USEMAP|ACTION|DATA|CODEBASE)=(["'])https?:(//servo\.skgb\.de/)}{$1=$2$3}gi;
				$i += $body =~ s{\@import url\("/screen.css"\);}{\@import url("$mount_point/screen.css");}g;
				if ($i) {
					$res->body($body);
					$res->headers->content_length(length($body));
				}
			}
		},
	});
	
	
	$app->helper('skgb.legacy.mount_point' => sub {
		my ($c) = @_;
		return $mount_point;
	});
	

	$app->helper('skgb.legacy.password' => sub {
		my ($c, $user) = @_;
		my $password = $user->_property('legacyPassword');
		if (! $password) {
			$password = join '', map {chr 32 + int rand 95} 1..8;
			
			my $t = $c->neo4j->session->begin_transaction;
			try {
				
				# store in 2.0 database
				$t->{return_stats} = 1;
				my $result = $t->run($user->query("p", "SET p.legacyPassword = {password}"), password => $password);
				$result->stats->{properties_set} or die 'Failed to modify databases';
				
				# store in 1.4 database
				$c->skgb->legacy->basicauth($user, $password);
				
				$t->commit;
			}
			catch { die $_ } finally { $t->rollback };
			
			$user->{node} //= {};
			$user->{node}->{properties} //= {};
			$user->{node}->{properties}->{legacyPassword} = $password;
		}
		return $password;
	});
	
	
	$app->helper('skgb.legacy.basicauth' => sub {
		my ($c, $person, $password) = @_;
		$person && $password or croak "Cannot modify htpasswd: person and password required";
		
		# (Looks like actually HTTPD::UserAdmin might already implement this... whatever.)
		# (also note Mojo::Util#slurp and Mojo::Util#spurt)
		
		# compose the basic auth line
		my $legacy_user = $person->legacy_user or die "No legacy login for users with no legacy user id";
		my $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
		my $basic_line = "$legacy_user:" . crypt $password, $salt;
		
		# read htpasswd file
		# NB: the locking is not 100% reliable, see flock docs
		defined $app->config->{legacy}->{htpasswd_path} or die "Cannot find htpasswd";
		open( my $fh, '+<', $app->config->{legacy}->{htpasswd_path} ) or die "Cannot open htpasswd: $!";
		flock($fh, LOCK_EX) or die "Cannot lock htpasswd: $!";
		local $/ = undef;
		my $htpasswd = <$fh>;
		
		# modify or append the basic auth line
		my $pattern = '(^|\s)' . quotemeta($legacy_user) . ':\S*';
		if ( $htpasswd =~ s/$pattern/$1$basic_line/ ) {
			seek($fh, 0, SEEK_SET) or die "Cannot seek htpasswd: $!";
			truncate($fh, 0) or die "Cannot truncate htpasswd: $!";
			print $fh $htpasswd;
		}
		else {
			seek($fh, 0, SEEK_END) or die "Cannot seek htpasswd: $!";
			print $fh "$basic_line\n";
		}
		
		# clean up
		flock($fh, LOCK_UN) or die "Cannot unlock htpasswd: $!";
		close($fh) or warn "Closing htpasswd failed: $!";
	});
	
}

 
1;


__END__

Userinfo (i.e., username and password) are now disallowed in HTTP and
HTTPS URIs, because of security issues related to their transmission
on the wire.

https://tools.ietf.org/html/rfc7230#page-18
