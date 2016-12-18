package SKGB::Intern::Controller::Regeln;
use Mojo::Base 'Mojolicious::Controller';

use File::Find;
#use Try::Tiny;
use SKGB::Intern;
use SKGB::Regeln;


sub regeln {
	my $c = shift;
	
	if ( ! $c->skgb->may ) {
#		return $c->render(template => 'key_manager/forbidden', status => 403);
	}
	
	# regeln suchen, komplette liste erzeugen und mitgeben
	my $regeln_list = {};
	my $wanted = sub {
		m/^[^\.].*\.xml(?:\.|$)/ or return;
		my $xml;
		eval { $xml = SKGB::Regeln->load($_); };
		$xml or return;
		my $info = $xml->regeln_info or return;
		$info->{path} = $File::Find::name;
		$info->{file} = $_;
		my @version_list = $xml->version_list;
		$info->{version_list} = \@version_list;
		if (! $info->{shortname}) {
			$info->{shortname} = $info->{file};
			$info->{shortname} =~ s/(?:\..*)$//;
			$info->{shortname} = $info->{fullname} if length $info->{fullname} < length $info->{shortname};
		}
		$info->{colloquial} ||= $info->{fullname};
		my $key = $info->{shortname};
		my $nr = 2;
		while ($regeln_list->{$key}) {
			$key = $info->{shortname} . '_' . $nr++;
		}
		if ($nr > 2) {
			$info->{duplicate_name} = 1;
			$regeln_list->{$info->{shortname}}->{duplicate_name} = 1;
		}
		$regeln_list->{$key} = $info;
	};
	find($wanted, $c->config->{skgb}->{regeln_src});
	
	my $regeln_param = $c->param('regeln') || $c->stash('moniker_placeholder');
#	my $regeln_param = $c->param('regeln');
	if ( ! ($c->param('run') && $regeln_param && $c->param('base') && $c->param('changes') && $c->param('format')) ) {
#	if ( ! ($c->param('run') && $c->param('regeln') && $c->param('base') && $c->param('changes') && $c->param('format')) ) {
		$c->render( regeln_list => $regeln_list );
		return;
	}
	
	# params pruefen, ggf. fehlermeldung
	my $info;
	foreach my $key (sort keys %$regeln_list) {
		if ($key eq $regeln_param) {
			$info = $regeln_list->{$key};
			last;
		}
	}
	$info or die "unknown document";
	
	# run
	my $regeln = SKGB::Regeln->load( $info->{path} );
	$regeln->{html_stylesheet} = 'public/regeln/regeln2html.xsl';
	$regeln->{odf_stylesheet} = 'public/regeln/regeln2odf.xsl';
	
	my $baseVersion = $c->param('base');
	my $showChanges = $c->param('changes');
	if (! $baseVersion) {
		if ($showChanges eq 'none' || $showChanges eq 'all') {
			$baseVersion = 'head';
		}
		else {
			$baseVersion = $showChanges;
		}
	}
	$regeln->show_base($baseVersion);
	
	if ($showChanges eq 'none') {
		$regeln->hide_changes();
	}
	elsif ($showChanges ne 'all' && $baseVersion ne 'base') {
		my $showChanges = $baseVersion;
		if ($showChanges eq 'head') {
			$showChanges = $info->{version_list}->[-1];
		}
		$regeln->show_changes( $showChanges );
	}
	
	$c->app->types->type(xhtml => 'application/xhtml+xml;charset=UTF-8');
	$c->app->types->type(odt => 'application/vnd.oasis.opendocument.text');
	my $raw = $c->param('raw');
	if ($c->param('format') eq 'html') {
		$c->render(text => $regeln->as_html, format => $raw ? 'txt' : 'xhtml');
	}
#	elsif ($c->param('format') eq 'xhtml') {
#		$c->render(text => $regeln->as_html, format => $raw ? 'txt' : 'xhtml');
#	}
	elsif ($c->param('format') eq 'odf') {
		$regeln->{skgb_intern_version} = $SKGB::Intern::VERSION;
		$c->res->headers->content_disposition("attachment; filename=$info->{shortname}.odt;") unless $raw;
		$c->render(text => $regeln->as_odf, format => $raw ? 'xml' : 'odt');
	}
	elsif ($c->param('format') eq 'txt') {
		$c->render(text => $regeln->as_txt, format => 'txt');
	}
#	elsif ($c->param('format') eq 'rep') {
#		$c->render(text => $regeln->as_report, format => 'txt');
#	}
	elsif ($c->param('format') eq 'xml') {
		my $as_xml = $regeln->as_xml;
		$as_xml =~ s{<\?xml-stylesheet href="regeln2html\.xsl" type="text/xsl"\?>\n?}{} if $raw;
		$c->render(text => $as_xml, format => 'xml');
	}
	else {
		die "unsupported format";
	}
	
}



1;
