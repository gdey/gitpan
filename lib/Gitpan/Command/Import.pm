use v5.12;
use warnings;
package Gitpan::Command::Import v0.0.1 {
use Mouse;
use perl5i::2;
use Method::Signatures;

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

method main {

   require Data::Dumper;
   my $search = '>= '.time;
   my $dists = $self->backpan_index->dists(); 
   say 'Found '.$dists->count.' number of distributions';
   my $first = $dists->first;
   say 'The first one is: '.$first->get_column('name')
   #Data::Dumper::Dumper($dists);

}

with 'Gitpan::Role::HasBackpanIndex';
} # package
