package Gitpan::Dist;

use Mouse;
use Gitpan::Types;

use perl5i::2;
use Method::Signatures;

with 'Gitpan::Role::HasBackpanIndex';

has name =>
  is            => 'ro',
  isa           => 'Gitpan::Distname',
  required      => 1;

has repo =>
  is            => 'ro',
  isa           => 'Gitpan::Repo',
  lazy          => 1,
  default       => method {
      require Gitpan::Repo;
      return Gitpan::Repo->new(
          distname => $self->name
      );
  };

has backpan_dist => 
   is           => 'rw',
   isa          => 'BackPAN::Index::Dist',
   lazy         => 1,
   builder      => method {
    return $self->backpan_index->dist($self->name);
};


around BUILDARGS => sub {
   my $orig = shift;
   my $class = shift;
   my %args = @_;
      # Provide a nicer API for the building up a dist object.
   $args{name} = $args{backpan_dist}->get_column('name') if exists $args{backpan_dist} && 
                                                            !exists $args{name};
   $class->$orig( %args );
};

method backpan_releases {
    return $self->backpan_dist->releases->search(
        # Ignore ppm releases, we only care about source releases.
        { path => { 'not like', '%.ppm' } },
        { order_by => { -asc => "date" } } );
}

method release(Str :$version) {
    require Gitpan::Release;
    return Gitpan::Release->new(
        distname        => $self->name,
        version         => $version
    );
}

1;
