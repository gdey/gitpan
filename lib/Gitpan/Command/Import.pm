package Gitpan::Command::Import;
use v5.12;
use warnings;
use Mouse;
use Gitpan::Dist;
use Gitpan::Types;
use Gitpan::Repo;
use Gitpan::Release;
use File::Copy::Recursive qw(dircopy);
use Path::Class;

use perl5i::2;
use Method::Signatures;


with 'Gitpan::Role::HasBackpanIndex';
  # This object will be the main driver class for the Import subcommand.
  # Objective: To import one or more distrubution to github.

#has dists => 
#   is => 'ro',
#   isa => 'Gitpan::Dist',
#   builder => 'default_dists';
#method default_dists {
#   require Gitpan::Dist;
#   Gitpan::Dist->new(
#      
#   );
#}

has options => 
   is => 'ro',
   isa => 'HashRef',
   init_arg => undef,
   builder => 'default_options';

method default_options {
  # TODO: Do argv processing here.
  return {@ARGV};
}

# Factory method to allow us to customize the Repo object.
method new_gitpan_repo( $distname ){ Gitpan::Repo->new( distname => $distname ) }

method gitify_release( $release, $repo ) {

     # We need to see if the release already exists in the repo.
     # We assume that this repo has already been checkout and an preped for us.
     # We also assume that we can find each release with the corrosponding tag.
  my %tags = map { $_ => 1 } $repo->git->tags;
     # We are going to skip release, we have already done.
     # TODO: This is not fully correct. We need to extract out the 
     #       release, and make sure there weren't any changes. We can not trust 
     #       the contents of a release has not changed. It should never changes;
     #       but it's hard to know for sure.
  if( exists $tags{$release->release_version} ) {
      say 'Release '.$release->release_version.' already in repo.';
      return;
  }
     # Obtain the release
  $release->get;
  my $extrated_dir = $release->extract;
  say "Work dir: ".$release->work_dir;
  say "repo dir: ".$repo->directory;
  my $message = $release->commit_message;
  dircopy( $extrated_dir, $repo->directory );
  $repo->git->add_all;
  $repo->git->commit($message, '--date', $release->date, '--author',$release->author_email );
  $repo->git->tag($release->release_version, $message);
}
method main {

   require Data::Dumper;
   require File::Temp;
   my $search = '>= '.time;
   my $dists = $self->backpan_index->dists(); 
   say 'Found '.$dists->count.' number of distributions';
   #say Data::Dumper::Dumper( [ $dists->get_column('name')->all ] );
   my $first = $dists->first;
   say 'The first one is: '.$first->get_column('name');
   #my $dist = Gitpan::Dist->new( backpan_dist => $first );

   my $dist = Gitpan::Dist->new( name => 'MapReduce' );
   my $releases = $dist->backpan_releases;
   my $repo = Gitpan::Repo->new( distname =>  'Goodday' );
   $repo->git->clean;

   say 'The number of release(s) for MapReduce are: '.$releases->count;
   say 'The versions for MapReduce are: '.join(',',$releases->get_column('version')->all);
   while( my $backpan_release = $releases->next ){
        my $release = Gitpan::Release->new(
           distname => $dist->name,
           backpan_release => $backpan_release
        );
        $self->gitify_release( $release, $repo );
   }
}

