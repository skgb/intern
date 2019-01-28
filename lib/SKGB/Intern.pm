package SKGB::Intern;
use Mojo::Base 'Mojolicious';
use Mojolicious 7.75;
use Mojo::Log;
#use Perl::Version;
use SemVer;

#our $VERSION = Perl::Version->new( '2.0.0_5' );
our $VERSION = SemVer->new( '2.0.0-a32' );


sub startup {
	my ($app) = @_;
	
	$app->moniker('skgb-intern');
	$app->plugin('Config');# => {file => 'conf/' . $app->moniker . '.' . $app->mode . '.conf'});
	$app->secrets([ Mojo::Util::sha1_sum($app->moniker . $app->config->{intern}->{cookie_secret}) ]);
	$app->log( Mojo::Log->new( path => $app->config->{intern}->{log} ) ) if $app->mode eq 'production';
	
	push @{$app->commands->namespaces}, 'SKGB::Intern::Command';
	
	$app->plugin('SKGB::Intern::Plugin::Neo4j');
	$app->plugin('SKGB::Intern::Plugin::AuthManager');
	$app->plugin('SKGB::Intern::Plugin::Legacy');
	
	# Documentation browser under "/perldoc"
#	$app->plugin('PODRenderer');
	
	# needed by Regeln
	$app->helper(
		formattr => sub { 
			my ($self, $attribute, $param, $value, $default) = @_;
			if ( $self->param($param) && $self->param($param) eq $value || ! $self->param($param) && $default ) {
				return " $attribute";
			}
		},
	);
	
	$app->setup_routing_wiki;
	$app->setup_routing_database;
	$app->setup_routing_misc;
	$app->routes->get('/*not_found')->to('not_found#redirect');
	$app->routes->any([qw(PUT DELETE TRACE OPTIONS PATCH)] => '/*not_implemented')->to('not_found#method');
	
	print "SKGB-intern $VERSION (", $app->mode(), ")\n";
}


sub setup_routing_wiki {
	my ($app) = @_;
	
	my $w = sub {
		my $l = $app->logged_in->route;
		# the ':' is the default placeholder start and cannot be used as a literal unless we reassign this
		$l->pattern->placeholder_start('%');
		$l->via(shift);
		return $l->parse(shift);
	};
	$w->([qw(GET POST)] => "/wiki/edit:*entity")->to('wiki#edit')->name('wikiedit');
	$w->(GET => '/wiki/history:*entity')->to('wiki#history')->name('wikihistory');
	$w->(GET => '/wiki/old:*entity')->to('wiki#view')->name('wikiold');
	$w->(GET => '/wiki/diff:*entity')->to('wiki#diff')->name('wikidiff');
	
	# fall-through
	$w->(GET => '/wiki/*entity')->to('wiki#view', entity => undef)->name('wikiview');
}


sub setup_routing_database {
	my ($app) = @_;
	my $l = $app->logged_in;
	
	$l->get('/person/<#entity>')->to('member_list#person')->name('person');
	$l->get('/person/')->to('member_list#list_person')->name('list_person');
	$l->get('/person/<#entity>/gs-verein')->to('member_list#gsverein')->name('paradox');
	$l->get('/budgetliste')->to('member_list#list_budget')->name('list_budget');
	$l->get('/austrittsliste')->to('member_list#list_leaving')->name('list_leaving');
	$l->get('/schluesselliste')->to('member_list#list_keys')->name('list_keys');
	$l->get('/boxenliste')->to('member_list#list_berth')->name('list_berth');
	$l->get('/mitgliederliste')->to('member_list#list')->name('mglliste');
	$l->get('/anschriftenliste')->to('member_list#postal')->name('postliste');
	$l->get('/jugendliste')->to('member_list#youth')->name('jgdliste');
	$l->get('/export/intern1')->to('export#intern1')->name('export1');
	$l->get('/export/listen')->to('export#listen')->name('exportlisten');
	$l->get('/dosb')->to('stats#dosb')->name('dosb');
	
	$l->get('/stegdienst/erzeugen')->to('content#stegdienstliste')->name('stegdienstliste');
	$app->plugin(Mount => {'/stegdienst/drucken' => 'script/stegdienst.cgi'});
}


sub setup_routing_misc {
	my ($app) = @_;
	my $r = $app->routes;
	my $logged_in = $app->logged_in;
	
	$r->any([qw(GET POST)] => '/neues-kennwort')->to('key_manager#factory')->name('keyfactory');
	$r->any([qw(GET POST)] => '/login')->to('key_manager#login');
	
	$r->get('/')->to('content#index')->name('index');
	$r->get('/wetter')->to('content#wetter')->name('wetter');
	
	$logged_in->route('/regeln/:entity')->to('regeln#regeln', entity => undef)->name('regeln');
	$logged_in->any('/auth/:entity')->to('auth#auth', entity => undef)->name('auth');
}


sub logged_in {
	my ($app) = @_;
	$app->{logged_in_route} = $app->routes->under('/')->to('key_manager#logged_in') unless $app->{logged_in_route};
	return $app->{logged_in_route};
}


1;
