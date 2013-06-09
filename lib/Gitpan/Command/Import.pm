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
     # Obtain the release
  #$release->get;
  #my $extrated_dir = $release->extract;
  say "Work dir: ".$release->work_dir;

  say "repo dir: ".$repo->directory;
  my $message = $relase->commit_message;
  #$repo->git->clean;
  #dircopy( $extrated_dir, $repo->directory );
  $repo->git->add_all;
  $repo->git->commit($message, '--date', $release->date, '--author',$release->author_email );
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
   say 'The number of release(s) are: '.$releases->count;
   say 'The number of release(s) are: '.join(',',$releases->get_column('version')->all);
   my $first_release = $releases->first;
   my $name = $dist->name;
   #my $repo = Gitpan::Repo->new( distname => $name );
   my $repo = Gitpan::Repo->new( distname =>  'Goodday' );
   my $release = Gitpan::Release->new( 
         distname => $name, 
         backpan_release => $first_release,
   );
  $self->gitify_release( $release, $repo );
}

