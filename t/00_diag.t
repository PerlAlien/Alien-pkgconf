use strict;
use warnings;
use Test2::Bundle::More;
use Alien::pkgconf;
use Data::Dumper qw( Dumper );

diag '';
diag '';
diag '';

diag "_dist_dir = ", Alien::pkgconf::_dist_dir();

diag Dumper( Alien::pkgconf::_config() );

diag '';
diag '';

ok 1;

done_testing;
