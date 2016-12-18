package SKGB::Intern;
use Mojo::Base 'Mojolicious';
use Mojo::Log;
#use Perl::Version;
use SemVer;

#our $VERSION = Perl::Version->new( '2.0.0_5' );
our $VERSION = SemVer->new( '2.0.0-a15' );


sub startup {
	my ($app) = @_;
	
#	$ENV{MOJO_REVERSE_PROXY} = 1;
	
	$app->moniker('skgb-intern');
	$app->plugin('Config');# => {file => 'conf/' . $app->moniker . '.' . $app->mode . '.conf'});
	$app->secrets([ Mojo::Util::sha1_sum($app->moniker . $app->config->{intern}->{cookie_secret}) ]);
	$app->log( Mojo::Log->new( path => $app->config->{intern}->{log} ) ) if $app->mode eq 'production';
	
	push @{$app->commands->namespaces}, 'SKGB::Intern::Command';
	
	$app->plugin('SKGB::Intern::Plugin::Neo4j');
	$app->plugin('SKGB::Intern::Plugin::SessionManager');
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
	
	print "SKGB-intern $VERSION (", $app->mode(), ")\n";
}


sub setup_routing {
	my ($app) = @_;
	my $r = $app->routes;
	
	$r->any([qw(GET POST)] => '/neues-kennwort')->to('key_manager#factory')->name('keyfactory');
	
	$r->any('/wetter')->to('content#wetter')->name('wetter');
	
	$r->any('/login')->to('key_manager#login');
	$r->any('/')->to('content#index')->name('index');
	
	$r->any('/auth/:code_placeholder')->to('auth#auth', code_placeholder => undef)->name('auth');
	
	my $logged_in = $r->under('/')->to('key_manager#logged_in');
#	$logged_in->any('/content/:name')->to('content#content');
	$logged_in->any('/profile')->to('member_list#node')->name('mglpage');
#	$logged_in->any('/person/(:person)')->to('member_list#person', person => undef)->name('person');
	$logged_in->any('/person/(#person_placeholder)')->to('member_list#person')->name('person');
	$logged_in->any('/person/')->to('member_list#list_person')->name('list_person');
	$logged_in->any('/austrittsliste')->to('member_list#list_leaving')->name('list_leaving');
	$logged_in->any('/mitgliederliste')->to('member_list#list')->name('mglliste');
	$logged_in->any('/anschriftenliste')->to('member_list#postal')->name('postliste');
	$logged_in->any('/jugendliste')->to('member_list#youth')->name('jgdliste');
	$logged_in->any('/export/intern1')->to('export#intern1')->name('export1');
	$logged_in->any('/export/listen')->to('export#listen')->name('exportlisten');
	
	$logged_in->any('/stegdienst/erzeugen')->to('content#stegdienstliste')->name('stegdienstliste');
	$app->plugin(Mount => {'/stegdienst/drucken' => 'script/stegdienst.cgi'});
	
	$logged_in->route('/regeln/:moniker_placeholder')->to('regeln#regeln', moniker_placeholder => undef)->name('regeln');
	
	$logged_in->any('/dosb')->to('stats#dosb')->name('dosb');
	
	my $wiki_action = $logged_in->route;
	$wiki_action->pattern->placeholder_start('%');  # the ':' is the default placeholder start and cannot be used as a literal unless we reassign this
	$wiki_action->parse('/wiki/(action):*slug_placeholder')->to('wiki#view', action_set => 1)->name('wiki');
	$r->any('/wiki/*slug_placeholder')->to('wiki#view', slug_placeholder => undef)->name('wikiview');  # fallback for empty actions
}


1;
