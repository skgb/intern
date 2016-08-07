package SKGB::Regeln;

use 5.014;
use utf8;

our $VERSION = 0.81;

#use File::Spec;
#use File::Basename;
use XML::LibXML 1.70 qw();
use XML::LibXSLT;
#use Devel::StackTrace qw();
#use Data::Dumper qw();

#use Carp qw();
#use POSIX qw();


sub load {
	my ($class, $location) = @_;
	my $instance = {
		path => $location,
		doc => XML::LibXML->load_xml(location => $location),
		xslt => undef,
		versions => undef,
		html_stylesheet => 'regeln2html.xsl',
		odf_stylesheet => 'regeln2odf.xsl',
	};
	return bless $instance, $class;
}


sub path {
	my ($self) = @_;
	return $self->{path};
}


sub regeln_info {
	my ($self) = @_;
	my $context = XML::LibXML::XPathContext->new($self->{doc});
	$context->registerNs('regeln', 'http://www.skgb.de/2005/regeln');
	my $version = $context->findnodes('/regeln:regeln/@version');
	$version or return undef;
	my $info = { regeln_version => $version->string_value() };
	my $fullname = $context->findnodes('/regeln:regeln/*/regeln:name');
	$fullname and $info->{fullname} = $fullname->string_value();
	my $shortname = $context->findnodes('/regeln:regeln/*/regeln:name/@abkuerzung');
	$shortname and $info->{shortname} = $shortname->string_value();
	my $colloquial = $context->findnodes('/regeln:regeln/*/regeln:name/@umgangssprachlich');
	$colloquial and $info->{colloquial} = $colloquial->string_value();
	my $stand = $context->findnodes('//regeln:stand');
	$stand and $info->{stand} = $stand->string_value();
	my $aktuell = $context->findnodes('//regeln:aktuell/@den');
	$aktuell and $info->{aktuell} = $aktuell->string_value();
	return $info;
}


sub xslt {
	my ($self) = @_;
	$self->{xslt} ||= XML::LibXSLT->new();
	return $self->{xslt};
}


sub _transform {
	my ($self, $style_doc) = @_;
	my $stylesheet = $self->xslt->parse_stylesheet($style_doc);
	my $results = $stylesheet->transform($self->{doc});
	my $new_source = XML::LibXML->load_xml( string => $stylesheet->output_as_chars($results), load_ext_dtd => 0 );
	return $new_source;
}


sub _transform_stylesheet {
	my ($self, $style) = @_;
	$self->{doc} = $self->_transform(XML::LibXML->load_xml( location => $style, no_cdata => 1 ));
}


sub _transform_singlerule {
	my ($self, $style) = @_;
	$style or return;# $self->{doc};
#	print STDERR "---\n$style\n";
	# based on http://www.usingxml.com/Transforms/XslIdentity
	$self->{doc} = $self->_transform(XML::LibXML->load_xml( string => <<'EOT' . $style . '</xsl:transform>', no_cdata => 1 ));
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<xsl:transform version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.skgb.de/2005/regeln" xmlns:regeln="http://www.skgb.de/2005/regeln" xmlns:html="http://www.w3.org/1999/xhtml" exclude-result-prefixes="regeln">
<xsl:output method="xml" media-type="application/xml" encoding="UTF-8" omit-xml-declaration="no" standalone="yes" indent="no"/>
<xsl:template match="/ | @* | node()">
	<xsl:copy>
		<xsl:apply-templates select="@* | node()" />
	</xsl:copy>
</xsl:template>
EOT
#	return $self->doc;
}


sub version_list {
	my ($self) = @_;
	open (FILE, '<', $self->{path}) or die ("ERROR: Could not read file '" . $self->{path} . "'");
	my %dates = ();
	while (<FILE>) {
#		while (/=['"][^'"]*(\d\d\d\d-\d\d-\d\d)[^'"]*['"][^>]*>/g) {  # bug: in case of multiple dates (e.g. in @nachgefuehrtam), only one is recognised
		next if m/^\$Id: /;
		while (m/['" ](\d\d\d\d-\d\d-\d\d)['" ]/g) {
#			print pos, "\n";
			$dates{$1} = 1;
		}
	}
	close (FILE);
	return sort {$a cmp $b} keys %dates;
}


sub show_base {
	my ($self, $baseVersion) = @_;
	if ($baseVersion ne 'head') {
		my @versionList = $self->version_list;
		my @hideVersions = ();
		foreach my $version (@versionList) {
			if ($baseVersion eq 'base' || $version gt $baseVersion) {
				push @hideVersions, $version;
			}
		}
	#	if (! @hideVersions) {
	#		$style_rule = undef;
	#	}
	#	else {
			@hideVersions = sort {$b cmp $a} @hideVersions;
	#		die "@hideVersions";
			my $stand = $baseVersion eq 'base' ? 'ursprünglichen Beschluss' : $baseVersion;
			for my $hideVersion (@hideVersions) {
				my $style_rule = <<"EOT";
<!-- last XSLT rule has highest precendence => is evaluated first -->
<xsl:template match=\"*[\@eingefuegtam and \@eingefuegtam='$hideVersion']\" />
<xsl:template match=\"*[\@gestrichenam and \@gestrichenam='$hideVersion'] | *[\@nachgefuehrtam and \@nachgefuehrtam='$hideVersion']\">
	<xsl:copy>
		<xsl:apply-templates select=\"\@eingefuegtam | \@hinweis | node()\" />
	</xsl:copy>
</xsl:template>
<xsl:template match=\"//regeln:ordnung | //regeln:satzung\">
		<xsl:copy>
			<xsl:attribute name="stand">$stand</xsl:attribute>
			<xsl:apply-templates select="@* | node()" />
		</xsl:copy>
</xsl:template>
EOT
				$self->_transform_singlerule($style_rule);
			}
	#	}
	}
}


sub hide_changes {
	my ($self) = @_;
	$self->_transform_singlerule(<<'EOT');
<!-- last XSLT rule has highest precendence => is evaluated first -->
<xsl:template match="*[@eingefuegtam] | *[@nachgefuehrtam]">
	<xsl:copy>
		<xsl:apply-templates select="@gestrichenam | node()" />
	</xsl:copy>
</xsl:template>
<xsl:template match="*[@gestrichenam]" />
EOT
}


sub show_changes {
	my ($self, $showChanges) = @_;
	$self->_transform_singlerule(<<"EOT");
<!-- last XSLT rule has highest precendence => is evaluated first -->
<xsl:template match=\"*[\@eingefuegtam and not(\@eingefuegtam='$showChanges')] | *[\@nachgefuehrtam and not(\@nachgefuehrtam='$showChanges')]\">
	<xsl:copy>
		<xsl:apply-templates select=\"\@gestrichenam | \@hinweis | node()\" />
	</xsl:copy>
</xsl:template>
<xsl:template match=\"*[\@gestrichenam and not(\@gestrichenam='$showChanges')]\" />
EOT
}


sub as_html {
	my ($self) = @_;
#	print transform_stylesheet($xml, 'regeln2html.xsl');
	$_ = join '', $self->_transform_stylesheet($self->{html_stylesheet});
	utf8::decode $_ or warn 'Unicode error';
	# leere Beitragslistenelemente entfernen (Folge der dortigen Probleme mit ins-del)
	s{<dt>:</dt><dd>[^<]*</dd>}{}g;
	return $_;
}


sub as_odf {
	my ($self) = @_;
	$_ = join '', $self->_transform_stylesheet($self->{odf_stylesheet});
	utf8::decode $_ or warn 'Unicode error';
	s{<meta:generator>}{<meta:generator>SKGB::Regeln/$VERSION }g;
	s{<meta:generator>}{<meta:generator>SKGB::Intern/$self->{skgb_intern_version} }g if $self->{skgb_intern_version};
	# BUG: in 9 (1) satzung kapselt <s> eine lit-Liste - böse, aber prinzipiell ja nicht falsch. was es bedeutet: <s> muss, falls wir es weiterverwenden wollen, den "satz" als einzige semantik beinhalten und die listen/textabsatz-logik muss anders entstehen (was wohl so war, wie's mal gedacht war).
	s{<text:p([^>]*)>\s*([^<>]+)\s*<text:list>}{<text:p$1>$2</text:p><text:list>}g;
	s{</text:list>\s*</text:p>}{</text:list>}g;
	s{</text:list>\s*([^<>]+)\s*</text:p>}{</text:list><text:p text:style-name="SKGB-Regeln-Buchstaben">$1</text:p>}g;
	# paragraph mit 1 absatz MIT <abs>
	s{<text:p text:style-name="SKGB-Regeln-Absatz-single"/>\s*<text:list-item>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Absatz-single">}g;
	s{</text:list-item>\s*</text:list-item>}{</text:list-item>}g;
	# paragraph mit 1 absatz OHNE <abs>
	s{<text:p text:style-name="SKGB-Regeln-Absatz-single"/>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Absatz-single">}g;
	# BUG: ist mitten im absatz eine lit-liste eingefuegt, wird diese hiermit uebersprungen und erst am ende eingefuegt. was wir bräuchten: CSS-+-selektor; einstweilige loesung: ein <text:p> je <regeln:s>
	s{</text:p>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{ }g;
	# BUG: [ins-del] es entstehen evtl. unnütze Leerzeichen
	s{ +}{ }g;
	s{<text:line-break/> (\w)}{<text:line-break/>$1}g;  # NEU
	# BUG: [ins-del] es entstehen evtl. Artefakte wie "Wort1 , Wort2" oder "01.09. 1967" <- noch keine Loesung
	# BUG: [regeln:lit] schlaegt fehl, wenn das lit noch irgendwas anderes enthaelt
	s{<text:p text:style-name="SKGB-Regeln-Buchstaben">\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{<text:p text:style-name="SKGB-Regeln-Buchstaben">}g;
	s{</text:p>\s*</text:p>}{</text:p>}g;
#	s{([a-z]) , }{$1, }g;
	# aufhuebschen
	s{><text:list-item>}{>\n<text:list-item>}g;
	# BUG: geht's nach lit-Liste mit fliesstext weiter, soll kein vertikaler abstand entstehen
	s{</text:list>\s*<text:p text:style-name="SKGB-Regeln-Absatz">}{</text:list>\n<text:p text:style-name="SKGB-Regeln-Buchstaben">}g;
	return $_;
}


sub as_txt {
	my ($self) = @_;
	$_ = $self->xslt->parse_stylesheet(XML::LibXML->load_xml( string => <<'EOT', no_cdata => 1 ))->transform($self->{doc});
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" media-type="text/plain" encoding="utf-8" omit-xml-declaration="yes"/>
</transform>
EOT
	utf8::decode $_ or warn 'Unicode error';
	s{<\?[^\?]*\?>}{}g;  # remove XML declaration
	s{^\s*}{}mg;  # chomp
	s{\n(\d+)\n}{ $1\n}g;  # Beitragslistenelemente auf einzelne Zeilen zusammenführen
	s{ +}{ }g;  # BUG: [ins-del] es entstehen evtl. doppelte Leerzeichen
	return $_;
}


sub as_report {
	my ($self) = @_;
	die 'report / "Artikelgesetz" - not implemented';
}


sub as_xml {
	my ($self) = @_;
	$_ = $self->{doc};
	utf8::decode $_ or warn 'Unicode error';
	return $_;
}




# ./regeln.pl FinO.xml -l > FinO.list ; while read f ; do ./regeln.pl -c "$f" -f html FinO.xml > "FinO.$f.d.xhtml" ; done < FinO.list


1;

__END__
