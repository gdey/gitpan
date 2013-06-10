package Gitpan::Release;

use Mouse;
use Gitpan::Types;
use File::chmod;  # use before autodie to avoid being blown over
use perl5i::2;
use Method::Signatures;

use Path::Class ();

with
  'Gitpan::Role::HasBackpanIndex',
  'Gitpan::Role::HasCPANPLUS',
  'Gitpan::Role::HasUA';

has distname =>
  is            => 'ro',
  isa           => 'Gitpan::Distname',
  required      => 1;

has version =>
  is            => 'ro',
  isa           => 'Str',
  required      => 1;

has backpan_release =>
  is            => 'ro',
  isa           => 'BackPAN::Index::Release',
  lazy          => 1,
  handles       => [qw(
      cpanid
      date
      distvname
      filename
      maturity
  )],
  default       => method {
      return $self->backpan_index->releases($self->distname)->single({ version => $self->version });
  };

has backpan_file     =>
  is            => 'ro',
  isa           => 'BackPAN::Index::File',
  lazy          => 1,
  handles       => [qw(
      path
      size
      url
  )],
  default       => method {
      $self->backpan_release->path;
  };

has author =>
  is            => 'ro',
  isa           => 'CPANPLUS::Module::Author',
  lazy          => 1,
  default       => method {
      my $cpanid = $self->cpanid;
      return $self->cpanplus->author_tree->{$cpanid};
  };

has work_dir =>
  is            => 'ro',
  isa           => 'File::Temp::Dir',
  lazy          => 1,
  default       => method {
      require File::Temp;
      return File::Temp->newdir;
  };

has archive_file =>
  is            => 'ro',
  isa           => 'Path::Class::File',
  lazy          => 1,
  default       => method {
      return Path::Class::File->new( $self->work_dir, $self->filename );
  };

has extract_dir =>
  is            => 'rw',
  isa           => 'Path::Class::Dir',
  coerce        => 1;

around BUILDARGS => sub {
   my $orig = shift;
   my $class = shift;
   my %args = @_;
      # Provide a nicer API for the building up a dist object.
   $args{version} = $args{backpan_release}->get_column('version') if exists $args{backpan_release};
   $class->$orig( %args );
};

method get {
    my $filename = $self->archive_file;
    my $res = $self->ua->get(
        $self->url,
        ":content_file" => "$filename"
    );

    croak "File ($filename) not fully retrieved" unless -e $self->archive_file  && -s _ == $self->size;

    return $res;
}

method extract {
    my $archive = $self->archive_file;
    my $dir     = $self->work_dir;

    croak "$archive does not exist, did you get it?" unless -e $archive;

    require Archive::Extract;
    my $ae = Archive::Extract->new( archive => $archive );
    croak "Couldn't extract $archive to $dir because ". $ae->error
      unless $ae->extract( to => $self->work_dir );

    $self->extract_dir( $ae->extract_path );

    $self->fix_permissions;

    return $self->extract_dir;
}
method release_version { $self->backpan_release };
  # This method returns the authors email address.
method author_email { $self->author->author.' <'.$self->author->email.'> ' }
  # A method that will provide a nice git commit message; for this release.
method commit_message {
  my ( $name,           $release_version,       $cpanid,               $backpan_file ) = 
     ( $self->distname, $self->backpan_release, $self->author->cpanid, $self->backpan_file );
  <<MSG;
initial import of $name $release_version from CPAN.

git-cpan-module: $name
git-cpan-version: $release_version
git-cpan-authorid: $cpanid
git-cpan-file: $backpan_file
MSG

}
  # Make sure the archive files are readable and the directories are traversable.
method fix_permissions {
    return unless -d $self->extract_dir;

    chmod "u+rx", $self->extract_dir;

    require File::Find;
    File::Find::find(sub {
        -d $_ ? chmod "u+rx", $_ : chmod "u+r", $_;
    }, $self->extract_dir);

    return;
}
