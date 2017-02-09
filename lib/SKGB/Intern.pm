package SKGB::Intern;
use Mojo::Base 'Mojolicious';
use Mojo::Log;
#use Perl::Version;
use SemVer;

#our $VERSION = Perl::Version->new( '2.0.0_5' );
our $VERSION = SemVer->new( '2.0.0-a22' );


sub startup {
	my ($app) = @_;
	
	$app->moniker('skgb-intern');
	$app->plugin('Config');# => {file => 'conf/' . $app->moniker . '.' . $app->mode . '.conf'});
	$app->secrets([ Mojo::Util::sha1_sum($app->moniker . $app->config->{intern}->{cookie_secret}) ]);
	$app->log( Mojo::Log->new( path => $app->config->{intern}->{log} ) ) if $app->mode eq 'production';
	
	push @{$app->commands->namespaces}, 'SKGB::Intern::Command';
	
	$app->plugin('SKGB::Intern::Plugin::Neo4j');
	$app->plugin('SKGB::Intern::Plugin::DigestAuth');
	$app->plugin('SKGB::Intern::Plugin::AuthManager');
	
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
	
	$app->setup_routing;
	$app->routes->get('/*not_found')->to('not_found#redirect');
	
	print "SKGB-intern $VERSION (", $app->mode(), ")\n";
}


sub setup_routing {
	my ($app) = @_;
	my $r = $app->routes;
	
	$r->any([qw(GET POST)] => '/neues-kennwort')->to('key_manager#factory')->name('keyfactory');
	
	$r->get('/wetter')->to('content#wetter')->name('wetter');
	
	$r->any([qw(GET POST)] => '/login')->to('key_manager#login');
	$r->get('/')->to('content#index')->name('index');
	
	my $logged_in = $r->under('/')->to('key_manager#logged_in');
	$logged_in->get('/profile')->to('member_list#node')->name('mglpage');
	$logged_in->get('/person/(#person_placeholder)')->to('member_list#person')->name('person');
	$logged_in->get('/person/')->to('member_list#list_person')->name('list_person');
	$logged_in->get('/person/(#person_placeholder)/gs-verein')->to('member_list#gsverein')->name('paradox');
	$logged_in->get('/budgetliste')->to('member_list#list_budget')->name('list_budget');
	$logged_in->get('/austrittsliste')->to('member_list#list_leaving')->name('list_leaving');
	$logged_in->get('/boxenliste')->to('member_list#list_berth')->name('list_berth');
	$logged_in->get('/mitgliederliste')->to('member_list#list')->name('mglliste');
	$logged_in->get('/anschriftenliste')->to('member_list#postal')->name('postliste');
	$logged_in->get('/jugendliste')->to('member_list#youth')->name('jgdliste');
	$logged_in->get('/export/intern1')->to('export#intern1')->name('export1');
	$logged_in->get('/export/listen')->to('export#listen')->name('exportlisten');
	$logged_in->get('/dosb')->to('stats#dosb')->name('dosb');
	
	$logged_in->get('/stegdienst/erzeugen')->to('content#stegdienstliste')->name('stegdienstliste');
	$app->plugin(Mount => {'/stegdienst/drucken' => 'script/stegdienst.cgi'});
	
	$logged_in->route('/regeln/:moniker_placeholder')->to('regeln#regeln', moniker_placeholder => undef)->name('regeln');
	
	$logged_in->any('/auth')->to('auth#auth')->name('auth');
	
	my $wiki_action = $logged_in->route;
	$wiki_action->pattern->placeholder_start('%');  # the ':' is the default placeholder start and cannot be used as a literal unless we reassign this
	$wiki_action->parse('/wiki/(action):*slug_placeholder')->to('wiki#view', action_set => 1)->name('wiki');
	$r->any('/wiki/*slug_placeholder')->to('wiki#view', slug_placeholder => undef)->name('wikiview');  # fallback for empty actions
}


1;
