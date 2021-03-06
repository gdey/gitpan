package Gitpan::Types;

use Mouse::Util::TypeConstraints;

class_type "BackPAN::Index";
class_type "File::Temp::Dir";
class_type "File::Temp";
class_type "Gitpan::Dist";
class_type "Gitpan::Repo";
class_type "Path::Class::Dir";
class_type "Path::Class::File";
class_type "URI";

subtype "Gitpan::AbsDir",
  as "Path::Class::Dir",
  where { $_->is_absolute };

coerce "Gitpan::AbsDir",
  from "Path::Class::Dir",
  via {
      return $_->absolute;
  };

coerce "Gitpan::AbsDir",
  from "Str",
  via {
      require Path::Class;
      return Path::Class::Dir->new($_)->absolute;
  };

coerce "Path::Class::Dir",
  from "Str",
  via {
      require Path::Class;
      return Path::Class::Dir->new($_);
  };

coerce "Path::Class::File",
  from "Str",
  via {
      require Path::Class;
      return Path::Class::File->new($_);
  };

subtype "Gitpan::Distname",
  as "Str",
  message { "A CPAN distribution name" },
  where { !/\s/ and !/::/ };

subtype "Gitpan::Module",
  as "Str",
  message { "A CPAN module name " },
  where { /^[A-Za-z]+ (?: :: \w+)* /x };

coerce "URI",
  from "Str",
  via {
      require URI;
      return URI->new($_);
  };

1;
