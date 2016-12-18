package SKGB::Intern::Controller::Wiki;
use Mojo::Base 'Mojolicious::Controller';

#use Data::Dumper;
use POSIX qw();
use Text::WordDiff qw();


has main_page_slug => 'Hauptseite';


my $Q = {
  article => REST::Neo4p::Query->new(<<QUERY),
MATCH (a:WikiArticle)-->(r:WikiRevision)<--(p:Person)
 WHERE a.slug = {slug}
 RETURN a, r, p
 ORDER BY r.date DESC
 LIMIT 1
QUERY
  old_article => REST::Neo4p::Query->new(<<QUERY),
MATCH (a:WikiArticle)-->(r:WikiRevision)<--(p:Person)
 WHERE a.slug = {slug} AND r.date = {oldid}
 RETURN a, r, p
 LIMIT 1
QUERY
  history => REST::Neo4p::Query->new(<<QUERY),
MATCH (a:WikiArticle)-->(r:WikiRevision)<--(p:Person)
 WHERE a.slug = {slug}
 RETURN r.date, p.name
 ORDER BY r.date DESC
QUERY
  diff => REST::Neo4p::Query->new(<<QUERY),
MATCH (r1:WikiRevision)<--(a:WikiArticle)-->(r2:WikiRevision)
 WHERE a.slug = {slug} AND r1.date = {date1} AND r2.date = {date2}
 RETURN r1.text, r2.text
 LIMIT 1
QUERY
};


sub view {
	my ($self) = @_;
	
	# normalise URL
	return $self->redirect_to($self->url_for('wikiview')) if $self->stash('action_set');
	my $slug = $self->_slug;
	return if ! $slug;
	
	my $user = $self->skgb->session->user;
	
	my $article = $self->_article($slug);
	if ($article) {
		return $self->render(logged_in => $user, name => $slug, article => $article);
	}
	else {
		return $self->render(template => 'wiki/empty', logged_in => $user, name => $slug, article => undef, status => 404);
	}
}

# https://metacpan.org/pod/Text::MultiMarkdown


sub diff {
	my ($self) = @_;
	
	# normalise URL
	my $slug = $self->_slug;
	return if ! $slug;
	
	my $row = $self->neo4j->execute_memory($Q->{diff}, 1, (slug => $slug, date1 => 0 + $self->param('oldid'), date2 => 0 + $self->param('diff')));
#	if (! $row) {
#		return $self->render(text => 'revisions not found', status => 404);
#	}
	return undef if ! $row;
	my ($a, $b) = ($row->[0], $row->[1]);
	
	my $diff = Text::WordDiff::word_diff \$a, \$b, { STYLE => 'HTML' };
	
	my $user = $self->skgb->session->user;
	
	return $self->render(logged_in => $user, name => $slug, diff => $diff);
}

# https://metacpan.org/search?q=diff&search_type=modules


sub history {
	my ($self) = @_;
	
	# normalise URL
	my $slug = $self->_slug;
	return if ! $slug;
	
#	my $article;
	my @revisions = ();
	my @rows = $self->neo4j->execute_memory($Q->{history}, 1000, (slug => $slug));
	foreach my $row (@rows) {
#		$article //= $row->[-1];
		my $date = $row->[0];
		my $revision_url = $self->url_for('wikiview');
#		$revision_url = $revision_url->query(oldid => $date) if @revisions;
		$revision_url = $revision_url->query(oldid => $date);
		push @revisions, [
			$row->[1],
			$self->_date( $date ),
			$date,
			$revision_url,
			];
	}
	
	# add diff links
	for (my $i = -1 + scalar @revisions; $i >= 0; $i--) {
		my $revision = $revisions[$i];
		my ($diff_prev_url, $diff_curr_url);
		$diff_prev_url = $self->url_for('wiki', action => 'diff')->query(oldid => $revisions[$i + 1]->[2], diff => $revision->[2]) if $i < -1 + scalar @revisions;
		$diff_curr_url = $self->url_for('wiki', action => 'diff')->query(oldid => $revision->[2], diff => $revisions[0]->[2]) if $i > 0;
		push @$revision, $diff_prev_url, $diff_curr_url;
	}
#	say Data::Dumper::Dumper(\@revisions);
	
	my $user = $self->skgb->session->user;
	
	return $self->render(logged_in => $user, name => $slug, revisions => \@revisions);
}


sub edit {
	my ($self) = @_;
	
	# normalise URL
	my $slug = $self->_slug;
	return if ! $slug;
	
	return $self->_save($slug) if $self->param('save');
	return $self->redirect_to($self->url_for('wikiview')) if $self->param('cancel');
	
	my $user = $self->skgb->session->user;

	my $article = $self->_article($slug);
	return $self->render(logged_in => $user, name => $slug, article => $article);
}


sub _save {
	my ($self, $slug) = @_;
	
	return $self->render(text => 'Bad CSRF token!', status => 403) if $self->validation->csrf_protect->has_error('csrf_token');
	
	my $user = $self->skgb->session->user;
	
	my $article = $self->_article($slug);
	if (! $article) {
		$article = { article => REST::Neo4p::Node->new( {slug => $slug} ) };
		$article->{article}->set_labels('WikiArticle');
	}
	$article->{revision} = REST::Neo4p::Node->new( {date => time(), text => $self->param('content')} );
	$article->{revision}->set_labels('WikiRevision');
	$article->{article}->relate_to($article->{revision}, 'REVISION');
	$user->{_node}->relate_to($article->{revision}, 'WROTE');
	
	return $self->redirect_to($self->url_for('wikiview'));
}


sub _article {
	my ($self, $slug) = @_;
	
	my $row;
	if ($self->param('oldid')) {
		$row = $self->neo4j->execute_memory($Q->{old_article}, 1, (slug => $slug, oldid => 0 + $self->param('oldid')));
	}
	if (! $row) {
		$row = $self->neo4j->execute_memory($Q->{article}, 1, (slug => $slug));
	}
	return undef if ! $row;
	return {
		article => $row->[0],
		revision => $row->[1],
		date => $self->_date( $row->[1]->get_property('date') ),
		author => $row->[2],
	};
}


sub _date {
	my ($self, $time) = @_;
	
	return POSIX::strftime('%Y-%m-%dT%H:%M:%SL', localtime( $time ));
}


sub _slug {
	my ($self) = @_;
	
	my $slug = $self->stash('slug_placeholder');
	
	# empty slug -> Main Page
	$self->redirect_to($self->url_for(slug_placeholder => $self->main_page_slug)) if ! $slug;
	return undef if ! $slug;
	
	# normalise (for URL)
	$slug =~ s/ /_/g;
	$slug =~ s/^_+|_+$//g;
	$slug =~ s{([^_])/([^_])}{$1_/_$2}g;
	if ($slug ne $self->stash('slug_placeholder')) {
		$self->redirect_to($self->url_for('wiki', slug_placeholder => $slug));
		return undef;
	}
	
	# readable title
	my $title = $slug;
	$title =~ s/_/ /g;
	return $title;
	
# 	return {
# 		url => $slug,
# 		title => $title,
# 	};
}

	
1;
