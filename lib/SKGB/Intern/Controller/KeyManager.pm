package SKGB::Intern::Controller::KeyManager;
use Mojo::Base 'Mojolicious::Controller';

use utf8;
use REST::Neo4p;
use String::Random;
use POSIX qw();
use Data::Dumper;
# use MIME::Lite;
use Encode qw();
use Mojo::SMTP::Client 0.15;
# use Mojo::IOLoop;
# use Email::Stuffer;
use Email::MessageID;
use Socket qw(:crlf);
#use String::Util;
use Mojo::Util qw(trim);
#use Mojo::Util;
#use Util::Any -list => ['all'];
use List::MoreUtils qw( all );

use SKGB::Intern::AccessCode;
use SKGB::Intern::Person::Neo4p;


my $Q = {
  searchname => REST::Neo4p::Query->new(<<QUERY),
MATCH (p:Person)-[:ROLE|GUEST*..4]->(:Role {role:'user'})
 WHERE p.name =~ {query} OR p.userId =~ {query} OR (p.userId + '\@skgb.de') =~ {query}
 RETURN p
 LIMIT 2  // we need to know whether there are 0, 1 or multiple results
QUERY
  searchmail => REST::Neo4p::Query->new(<<QUERY),
MATCH (a:Address {type:'email'})-[:FOR]->(p:Person)-[:ROLE|GUEST*..4]->(:Role {role:'user'})
 WHERE a.address =~ {query}
 RETURN p, a
QUERY
  get_luhn => REST::Neo4p::Query->new(<<QUERY),
MATCH (c:AccessCode)
 WHERE c.code =~ {code}
 RETURN c
 LIMIT 2  // should never yield more than 1 result; we want to verify this
QUERY
};


# cases:
# 0 user doesn't exist
# 1 user has no (active) key -> generate one
# 2 user has an active (non-expired) key -> re-use that one
# 3 user tries access with expired key -> greet user and offer to send key
# ? what about long-time keys?

# key expiry needs to be updated on each access
# or, alternatively and perhaps more useful: user last access time?
# -> access if key expiry in future or current time - last access time < time out
# not really more useful and prevents cookie auto-expiry

# https://html.spec.whatwg.org/multipage/forms.html#e-mail-state-(type=email)

# email addresses are supposed to be unique!


srand;
my $string_gen = String::Random->new;

# NOTE!!!: currently, String::Random uses Perl's built-in predictable random number generator so the passwords generated by it are insecure. 'srand' should solve the repeatability issue, but is still not secure. See:
#  <http://perldoc.perl.org/functions/rand.html>
#  <http://perldoc.perl.org/functions/srand.html>
#  <http://toroid.org/perl-secure-prng>
# my $string_gen = String::Random->new(rand_gen => sub {
#     my ($max) = @_;
#     return int rand $max;
# });


sub factory {
	my $self = shift;
	
	my $query = quotemeta(trim( $self->param('name') || "" ));
	$query =~ s/^aj$/Arne Johannessen/;
	$query =~ s/([^@]*)$/(?i)$1/;  # case insensitive (except the part before an '@', if any)
#	$query = "^$query\$";
#	say $query;
	my @persons = ();
	my $email;
	
	# search for an email address: associations with multiple persons possible
	my @rows = $self->neo4j->execute_memory($Q->{searchmail}, 1000, (query => $query));
	if (@rows) {
		foreach my $row (@rows) {
			push @persons, SKGB::Intern::Person::Neo4p->new( $row->[0] );
		}
		$email = $rows[0]->[1]->get_property('email');
#		say "address '$query' found for $#persons+1 persons";
	}
	else {
		# search for a person's name: unambiguous result required
		@rows = $self->neo4j->execute_memory($Q->{searchname}, 2, (query => $query));
		$rows[0] or return $self->render(user_unknown => 1, user_ambiguous => 0);
		$rows[1] and return $self->render(user_unknown => 1, user_ambiguous => 1);
		@persons = ( SKGB::Intern::Person::Neo4p->new($rows[0]->[0]) );
#		say "name/id '$query' found for $#persons+1 persons";
	}
	
	my $secure = $self->param('secure');
	if ($secure) {
		$self->_should_secure_session() or return $self->reply->forbidden;
	}
	my $code_length = $secure ? $self->config->{keyfactory}->{length_secure} : $self->config->{keyfactory}->{length_on_request};
	
	# Because every email address might relate to any number of persons, we
	# send each of these persons an individual access code. The easiest way to
	# do this is to send multiple emails. OTOH a single person might have
	# several email addresses, so if the user queried a name, we first need to
	# determine the primary/default email address(es) -- happening in _send_key_mail.
	foreach my $person (@persons) {
		
		my $code = $self->_generate_luhn( $code_length );
	#	my $r1 = REST::Neo4p::Relationship->new($code => $person, 'IDENTIFIES');  # bug in Neo4p: is_a() instead of isa()
		$code->set_property({ creation => SKGB::Intern::AccessCode::new_time() });
		my $r1 = $code->relate_to($person->{_node}, 'IDENTIFIES');
		
		my $code_string = $code->get_property('code');
		return $self->_secure_session($code, $code_string) if $secure;
		
#		$self->skgb->legacy->digestauth( $person, $code_string );
		$self->_send_key_mail($person, $code_string, $email);
	}
	
	return $self->render(user_unknown => 0, user_ambiguous => 0);
}


sub _should_secure_session {
	my ($self) = @_;
	
	my $session = $self->skgb->session;
	my $may_login = $session && $session->user && $self->skgb->may('user');
	
	return $may_login;
	# TODO: return false if this user may not create a secure session right now, e. g. because the session already is secure, another secure session code already exists and replacing it is not allowed by policy, the current session key has already created a secure session, the user lacks the rights required for secure sessions, ...
}


sub _secure_session {
	my ($self, $node, $key) = @_;
	
	$node->set_property({ secure => \1 });
	my $session = $self->skgb->session( $key );  # change the session cookie
	
	return $self->redirect_to( $self->url_for('auth', entity => $session->handle) );
}


sub _send_key_mail {
	my ($self, $person, $code, $email) = @_;
	
	# Q-encode headers only where necessary
	my $name = $person->name();
	$name = Encode::encode('MIME-Q', $name) if $name !~ m/^[- \w]*$/a;  # may need refinement; check RFC
	
	my @primary_emails = $person->primary_emails();
	my $primary_header = "";
	foreach my $primary_email (@primary_emails) {
		$primary_header .= ", " if $primary_header;
		$primary_header .= "$name <$primary_email>";
	}
	
	my ($to, $to_header, $cc_header);
	if ($email) {
		$to_header = "$name <$email>";
		$to = $email;
		# If a non-primary email address is queried, send a copy to the primary to
		# make sure the owner knows what's happening.
		if ( all {$_ ne $email} @primary_emails ) {
			$cc_header = $primary_header;
			$to = [ @primary_emails, $email ];
		}
	}
	else {
		$to_header = $primary_header;
		$to = \@primary_emails;
	}
	$to_header or warn "No recipient address found" and return;
	
	# BUG: when TLS is used to connect to the MSA, only one mail can be sent at a time
	
	my @query = (key => $code);
	push @query, (target => $self->param('target')) if $self->param('target');
	my $link = $self->url_for('login')->query(@query)->to_abs;
	$link = $link->scheme('https') if $self->app->mode ne 'development';
	
	my $mail = Encode::encode('UTF-8', $self->render_to_string('key_manager/factorymail',
		format => 'rfc822',
		to_header => $to_header,
		cc_header => $cc_header,
		person => $person,
		code => $code,
		link => $link,
	));
	my @mail = split(m/^/, $mail);
	my @lines = ();
	
	while (my $line = shift @mail) {
		chomp $line;
		last if $line eq '';
		push @lines, $line;
	}
	my $lines = join($CRLF, @lines, $CRLF . join('', @mail)) . $CRLF;
	
	say "Sending code $code to " . $person->name if $self->app->mode eq 'development';
	$self->_send_mail($to, $lines);
}


sub _send_mail {
	my ($self, $to, $lines) = @_;
	
	# NB: Mojo::SMTP::Client seems to be kind of unmaintained, while
	# Email::Sender & Friends keep getting upgrades. Perhaps this is the
	# wrong module to use?
	
	my $smtp = Mojo::SMTP::Client->new(
		address => $self->config->{msa}->{host},
		port => $self->config->{msa}->{port},
		tls => $self->config->{msa}->{port} == 465,
		hello => $self->config->{msa}->{helo},
	);
	
	my @smtp_auth = ();
	@smtp_auth = (auth => {login => $self->config->{msa}->{user}, password => $self->config->{msa}->{pass}}) if $self->config->{msa}->{user};
	$smtp->send(
		@smtp_auth,
		from => $self->config->{msa}->{from},
		to   => $to,
		data => $lines,
		quit => 1,
		sub {
			my ($smtp, $resp) = @_;
			warn $resp->error ? "Failed to send: ".$resp->error : "Sent successfully";
		},
	);
}


our $code_definition = {
	FullCharacterPattern => 'A-HJ-Z2-9',
	LimitedCharacterPattern => 'GHJKLMNOPQRSTUVW',
	AmbiguousCharacterPairs => sub { $_ = shift; return m/A9/ || m/9A/; },  # see luhn disadvantages
	NumberOfValidInputCharacters => ( length join '', ('A'..'H', 'J'..'Z', '2'..'9') ),
	CodePointFromCharacter => sub {  ord (shift =~ tr|A-HJ-Z2-9|\x00-\x20|r) },
	CharacterFromCodePoint => sub { (chr shift) =~ tr|\x00-\x20|A-HJ-Z2-9|r  },
#	SanitizeKey => sub { if (!$_[0]) {die}; (uc shift) =~ tr|I10|LLO|r },
	SanitizeKey => sub { (uc shift) =~ tr|I10|LLO|r },
};


sub _GenerateCheckCharacterLuhn {
	my $self = shift;
	my $input = shift;
	
	my $factor = 2;
	my $sum = 0;
	my $n = $code_definition->{NumberOfValidInputCharacters};

	# Starting from the right and working leftwards is easier since 
	# the initial "factor" will always be "2" 
	for (my $i = length($input) - 1; $i >= 0; $i--) {
		my $codePoint = $code_definition->{CodePointFromCharacter}->(substr $input, $i, 1);
		my $addend = $factor * $codePoint;

		# Alternate the "factor" that each "codePoint" is multiplied by
		$factor = ($factor == 2) ? 1 : 2;

		# Sum the digits of the "addend" as expressed in base "n"
		$addend = ($addend / $n) + ($addend % $n);
		$sum += $addend;
	}

	# Calculate the number that must be added to the "sum" 
	# to make it divisible by "n"
	my $remainder = $sum % $n;
	my $checkCodePoint = ($n - $remainder) % $n;

	return $code_definition->{CharacterFromCodePoint}->($checkCodePoint);
	
	# This implementation: <https://en.wikipedia.org/wiki/Luhn_mod_N_algorithm>
	# Possible alternative, supposedly better but also more complicated: <https://en.wikipedia.org/wiki/Verhoeff_algorithm> <https://www.google.de/search?q=Verhoeff+algorithm+alphanumeric> <https://gist.github.com/mwgamera/1087019>
	# Base32 considerations: <https://en.wikipedia.org/wiki/Base32> <http://www.crockford.com/wrmg/base32.html>
}


sub _generate_luhn {
	my $self = shift;
	my $length = -1 + shift;
	
	my $charPattern = $code_definition->{FullCharacterPattern};
	my $codePattern =
		"[$charPattern]" .
		"[" . $code_definition->{LimitedCharacterPattern} . "]" .
		"[$charPattern]{" . ($length - 2) . "}";
	if ($length == 1) {
		$codePattern = "[$charPattern]";
	}
	
	my $max_attempts = $self->config->{keyfactory}->{max_rand_attempts};
	
	my $code;
	for (my $i = 0; $i < $max_attempts; $i++) {
#		say $self->config->{md};
		$code = $string_gen->randregex( $codePattern );
		if ($code_definition->{AmbiguousCharacterPairs}->($code)) {
			next;
		}
		my @rows = $self->neo4j->execute_memory($Q->{get_luhn}, 2, (code => "^$code.\$"));
		if ($rows[0]) {
			if ($rows[1]) {
				die "duplicate AccessCode '$code'; database corrupted";  # only ever triggers by chance; check on login would be more useful
			}
			next;
		}
		$code .= $self->_GenerateCheckCharacterLuhn($code);
# 		$rows = $self->_execute_memory($Q->{store_luhn}, 1, (code => $code));
# 		my $node = $rows->[0]->[0];  # fresh REST::Neo4p::Node instance
		my $node = REST::Neo4p::Node->new( {code => $code} )->set_labels('AccessCode');
		return $node;
	}
	
	die("no available code found in $max_attempts attempts, last attempt was '$code'");
}



#############################


# "session?" step, with redirect
sub logged_in {
	my ($self) = @_;
	
	my $session = $self->skgb->session;
	if ( $session->valid ) {
		if ( $self->skgb->may ) {
			return 1;  # user access, authenticated and authorized
		}
		# authorization bad!
		
		$self->reply->forbidden;
		return undef;
	}
	elsif ( $self->skgb->may ) {
		return 1;  # public access, not authenticated
	}
	# authentication bad!
	
	# determine reason:
	# 1 no session cookie => treat as new user => no error msg
	# 2 key not/no longer in db => error
	# 3 key expired => notice, delete session cookie
	# 4 session expired, re-login possible => notice
	my @reason = ();
	if ($self->session('key')) {
		say "hello2, '$session'";
		if (! $session->code) {
			# this means we have a session cookie, but not the corresponding key => always either a coding error or an attempted attack, but treat as new user -- no error msg
			$self->_count_failed_login;
		}
		elsif ($session->expired) {
			$self->flash(reason => 'key');
#			@reason = (reason => 'key');
		}
		elsif ($session->session_expired) {
			$self->flash(reason => 'session');
#			@reason = (reason => 'session');
		}
		else {
			die "unknown reason";
		}
	}
	
	$self->redirect_to($self->url_for('login')->query(
		target => $self->url_for(),
		@reason,
	));
	return undef;
}


sub _count_failed_login {
	my ($self) = @_;
	
	my $config = $self->config->{login_fails};
	my $record = $self->neo4j->run_stats(<<_, $config)->single;
MATCH (s:System)
SET s.shortLoginFails = s.shortLoginFails + 1, s.longLoginFails = s.longLoginFails + 1
RETURN s.shortLoginFails > {short_limit} AS shortFail, s.longLoginFails > {long_limit} AS longFail, s.shortLoginReport, s.longLoginReport
_
	$record->summary->counters->properties_set or warn 'Incrementing login failure counters failed';
	if ($record->get('shortFail') && ! $record->get('s.shortLoginReport')) {
		$self->neo4j->session->run("MATCH (s:System) SET s.shortLoginReport = {now}", now => SKGB::Intern::AccessCode::new_time);
		$self->_send_report_mail($config->{report}, 'short');
	}
	elsif ($record->get('longFail') && ! $record->get('s.longLoginReport')) {
		$self->neo4j->session->run("MATCH (s:System) SET s.longLoginReport = {now}", now => SKGB::Intern::AccessCode::new_time);
		$self->_send_report_mail($config->{report}, 'long');
		# TODO: shut down the application server?
	}
}


sub _send_report_mail {
	my ($self, $to, $stage) = @_;
	my $subject = "too many login failures; denying login access ($stage)";
	say $subject;
	return if ! $to;
	
	my @headers = (
		'Content-Type: text/plain; charset=UTF-8',
		"X-Mailer: SKGB-intern/$SKGB::Intern::VERSION Mojo::SMTP::Client/$Mojo::SMTP::Client::VERSION Perl/" . substr($^V, 1),
		'Message-ID: ' . Email::MessageID->new(host => 'intern.skgb.de')->in_brackets,
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S %z', localtime),
		'From: login@intern.skgb.de.invalid',
		"To: $to",
		"Subject: $subject",
		'MIME-Version: 1.0',
	);
	my $mail = "SKGB-intern on ".`hostname`."$CRLF$subject$CRLF$CRLF";
	$mail .= Dumper $self->neo4j->session->run("MATCH (s:System) RETURN s")->single->{row}->[0];
	my $lines = join($CRLF, @headers) . $CRLF . $CRLF . $mail . $CRLF;
	
	$self->_send_mail($to, $lines);
}


# The Login page.
sub login {
	my ($self) = @_;
	
	if ($self->param('logout')) {
		$self->session(expires => 1);
		my $target = $self->param('target') || 'index';
		return $self->redirect_to($target);
	}
	
	my $result = $self->neo4j->session->run(<<_, $self->config->{login_fails});
MATCH (s:System)
RETURN (s.shortLoginFails > {short_limit} OR s.longLoginFails > {long_limit}) AS fail
_
	if ($result->single->get('fail')) {
		$self->_count_failed_login if $self->param('key');
		return $self->reply->exception('too many login failures; denying login access');
	}
	
	my $key = $self->param('key');
	if ($key) {
		$key =~ s/^\s*|\s*$//g;
		$key = $code_definition->{SanitizeKey}->( $key );
	}
	
	my $session;
	my $may_login = $self->skgb->may('user', $key) && ! $self->flash('reason');
	if ($may_login) {
		$session = $self->skgb->session( $key );  # set the session cookie
		$may_login = $session && $session->user && $self->skgb->may('user');
		if ($may_login) {
			
			my $target = $self->param('target') || 'index';
			$target = 'index' if $target eq $self->url_for('getkey');
			return $self->redirect_to($target);
		}
	}
	# not logged in
	
	if ($self->flash('reason')) {  # because of key expiration or session time-out
		$self->session(expires => 1);  # delete the cookie
	}
	if ($self->param('key')) {  # failed login attempt
		$self->_count_failed_login;
	}
	
	my @status = ();
	@status = (status => 401) if ! $may_login && $self->param('key') || $self->param('target');  # WWW-Authenticate header is set by AuthManager plugin
	return $self->render(session => $session, @status);
}




	
1;

__END__


Annahme für code on request:
- base32
- angreifer versucht ein paar dutzend mal (sagen wir, 40)
- max 1 % statistische wahrscheinlichkeit, einen gültigen code zu treffen
- 60 codes im jahr (sagen wir: 100 user, von denen 10 % mehrmals im jahr einen code holen, weitere 25 % einmal im jahr)
- forderung: ausreichend unike codes für das 10-fache der lebensdauer
32^5/40/100/60/10 => 6-stelliger code ergibt lebensdauer 13 Jahre, das ist okay

Annahme für 128 bit:
- base32
- log(2^128)/log(32) = 25.6 => 27-stelliger code (UUID: 32-stellig)

         1         2         3
1234567890123456789012345678901
ABCDEF-GHJKLM-NOPQRS-TUVWXY-Z23 - test, anders lösen

Annahme für unsolicited codes:
- angreifer versucht ein paar dutzend mal (sagen wir, 40)
- max 0.01 % statistische wahrscheinlichkeit, einen gültigen code zu treffen
- 3000 codes im jahr (sagen wir: 100 user, 30 emails im jahr)
- forderung: ausreichend unike codes für das 10-fache der lebensdauer
32^8/40/10000/3000/10 => 9-stelliger code ergibt lebensdauer 91 Jahre, das ist okay
bei wiederverwendung nach wenigen jahren auch 8-stelliger code denkbar
33^7/40/10000/2000/10 => 8-stelliger code mit base33 und weniger emails ergibt lebensdauer 5 jahre, das ist für den anfang knapp akzeptabel

Annahme für Test-Codes:
- max 0.1 % statistische wahrscheinlichkeit, einen gültigen code zu treffen
- 4-stelliger code
32^8/100/10000/10 => 32 unike codes

Annahme für Dev-Codes:
- 3-stelliger code, kein schutz vor duplikaten abgesehen von luhn
33^2 => ein paar 100 unike codes
