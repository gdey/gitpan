package Gitpan::Repo;

use Mouse;

use perl5i::2;
use Method::Signatures;
use Path::Class;
use Gitpan::Types;
use Gitpan::Github;

use overload
  q[""]     => method { return $self->distname },
  fallback  => 1;

has distname        => 
  isa       => 'Gitpan::Distname',
  is        => 'ro',
  required  => 1;

has cwd     =>
  isa       => 'Gitpan::AbsDir',
  is        => 'ro',
  coerce    => 1,
  required  => 1,
  default   => method {
      return dir()->absolute;
  },
  documentation => "The current working directory at time of object initialization";

has directory =>
  isa       => 'Gitpan::AbsDir',
  is        => 'ro',
  required  => 1,
  lazy      => 1,
  coerce    => 1,
  default   => sub { $_[0]->distname };

has git     =>
  isa       => "Gitpan::Git",
  is        => 'rw',
  required  => 1,
  lazy      => 1,
  default   => sub {
      require Gitpan::Git;
      return Gitpan::Git->init($_[0]->directory);
  };

has github  =>
  isa       => "Gitpan::Github|HashRef",
  is        => 'rw',
  lazy      => 1,
  coerce    => 0,
  trigger   => method($new, $old?) {
      return $new if $new->isa("Gitpan::Github");
      my $gh = $self->_new_github($new);
      $self->github( $gh );
  },
  default   => method {
      return $self->_new_github;
  };

method BUILDARGS($class: %args) {
    if( my $module_name = delete $args{modulename} ) {
        my $dist_name = $module_name;
        $dist_name =~ s{::}{-}g;
        $args{distname} = $dist_name;
    }

    return \%args;
}

method _new_github(HashRef $args = {}) {
    return Gitpan::Github->new(
        repo      => $self->distname,
        %$args,
    );
}

method exists_on_github() {
    # Optimization, asking github is expensive
    my $origin = $self->git->remote("origin");
    return 1 if defined $origin && $origin =~ /github.com/;
    return $self->github->exists_on_github();
}

method note(@args) {
    # no op for now
}
