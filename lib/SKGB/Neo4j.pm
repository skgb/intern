package SKGB::Neo4j;
#package REST::Neo4j;

use 5.014;
use utf8;

our $VERSION = 0.01;

#use Devel::StackTrace qw();
use Data::Dumper qw();
use Carp qw(croak);

#use URI;
use REST::Client;
use Cpanel::JSON::XS;


our $TRANSACTION_ENDPOINT = '/db/data/transaction';
our $CONTENT_TYPE = 'application/json; charset=UTF-8';


sub new {
	my ($class, $url, $user, $pass) = @_;
#	print Data::Dumper::Dumper($url, $user, $pass);
	
	$url =~ m{^(\w+)://(.*)$} or croak;
	my $client = REST::Client->new( host => "$1://$user:$pass\@$2", timeout => 60, follow => 1 );
	$client->addHeader('Accept', $CONTENT_TYPE);
	$client->addHeader('Content-Type', $CONTENT_TYPE);
	$client->addHeader('X-Stream', 'true');
#	my $l = 'http://127.0.0.1:7474/db/data/';
#	$client->GET( URI->new($l)->path_query );
#	say 'Status: ', $client->responseCode();
#	say $client->responseContent();
	
	return bless { client => $client }, $class;
}


sub client {
	my ($self) = @_;
	return $self->{client};
}


sub query {
	my ($self, $query) = @_;
	my $json = {
		statements => [
			{
				statement => $query,
				includeStats => \1,
				resultDataContents =>  [ "row", "graph" ],
			},
		],
#		query => $query,
	};
#	my $endpoint = "/db/data/cypher";
	my $endpoint = "$TRANSACTION_ENDPOINT/commit";
	$self->client->POST( $endpoint, encode_json($json) );
	say 'Status: ', $self->client->responseCode();
#	say $self->client->responseContent();
	say Data::Dumper::Dumper decode_json $self->client->responseContent();
}



1;

__END__

http://neo4j.com/docs/developer-manual/3.0/http-api/#http-api-transactional

https://neo4j.com/docs/rest-docs/current/#rest-api-service-root


***********************
http://neo4j.com/docs/developer-manual/3.0/drivers/#driver-use-the-driver


https://metacpan.org/pod/REST::Client
https://metacpan.org/pod/JSON::MaybeXS
http://stackoverflow.com/questions/14591444/which-perl-module-would-you-recommend-for-json-manipulation
http://perlmaven.com/comparing-the-speed-of-json-decoders












use Mojolicious 7.0;  # 6.x dies when using the Config plugin like this
use Mojolicious::Plugin::Config;

sub config {
	my ($file, $conf, $app) = ('skgb.conf', undef, undef);
	my $t = Mojolicious::Plugin::Config->load($file, $conf, $app);
#	print Data::Dumper::Dumper($t);
	return $t;
}

my $config = config();


my $n = SKGB::Neo4j->new( @{$config->{neo4j_url_user_pass}} );
#$n->query("CREATE (n) RETURN id(n)");
$n->query("MATCH a=(p:Person)-[:IS_A|IS_A_GUEST*..2]->(:Role {role:'member'}) WHERE p.name = 'Arne Johannessen' RETURN a");
#$n->query("MATCH (p:Person) WHERE p.name = 'Elke Becker' MATCH (p)-[r1]-(r)-[r2]-(o:Person) WHERE NOT r:Role AND NOT r:Person AND p <> o RETURN o,collect([r,r1,r2])");
