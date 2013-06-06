#!/usr/bin/perl

use strict;
use warnings;

use lib 'inc';

use Test::More;

use Gitpan::Github;

my $gh = Gitpan::Github->new;
isa_ok $gh, "Gitpan::Github";
use constant owner => 'gdey';



# exists_on_github()
{
    ok $gh->exists_on_github( owner => owner, repo => "gitpan" ),
     ' Test to make sure that gitpan repo does exists.';
    ok !$gh->exists_on_github( owner => owner, repo => "super-python" ), 
     ' Test to make sure that super-python repo does not exists';
}


# remote
{
    use Data::Dumper;
    my $remote = $gh->remote( repo => 'gitpan' );
    is $remote, 'git@github.com:gitpan/gitpan.git',
    ' Make sure the remote repo is the expected value.' ||
    diag( 'Got the value of: '.Dumper($remote) );
}

done_testing();
