package SKGB::Intern::Article;

use 5.012;
use utf8;
use Data::Dumper;
use CommonMark;


sub init {
	my ($class, @params) = @_;
	my $self = bless {@params}, $class;
	
	return $self;
}


sub _wikilinks_to_html {
	my ($self, $text) = @_;
	
	# parse wikilinks
	my $end = -2;
	while ( (my $start = index $text, "[[", $end) >= $end ) {
		$end = 2 + index $text, "]]", $start;
		last if $end < 2;
		my $link = substr $text, $start, $end - $start;
#		say "$start $end '$link'";
		$link =~ m/^\[\[((?:(?!\]\[).)+)\](?:\[(?:([a-z]+):)?(.+)\])?\]$/;
		my $linktext = $1;
		my $wikicommand = $2 // "view";
		my $linkdest = $3 ? $3 : $1;
#		say "$linktext -> $linkdest ($wikicommand)";
		
		# replace with HTML
		my $replacement = $self->{auth_manager}->auth_link_to("$wikicommand:$linkdest", $linktext);
		substr($text, $start, $end - $start) = $replacement;
		$end = $start + length $replacement;
#		say "]] $end";
		
	}
	return $text;
}


sub normalise_slug {
	my ($self, $slug) = @_;
	$slug = $self->{slug} if ! $slug && ref $self;
	
	$slug =~ s/ /_/g;
	$slug =~ s/^_+|_+$//g;
	$slug =~ s/^([a-z]*):/$1_:/g;
	$slug =~ s{([^_])/([^_])}{$1_/_$2}g;
	return $slug;
}


sub html {
	my ($self) = @_;
	my $text = $self->{revision}->get_property('text');
	$text = $self->_wikilinks_to_html($text);
#	$text = Mojo::Util::xml_escape $text;
	$text = CommonMark->markdown_to_html( $text, CommonMark::OPT_SMART );
	# NB: OPT_SMART only works for dashes, not for quotes, because of xml_escape
	return $text;
}



1;


__END__

=pod

=head1 NAME

SKGB::Intern::Article

=head1 AUTHOR

Copyright (c) 2017 THAWsoftware, Arne Johannessen.
All rights reserved.

=cut
