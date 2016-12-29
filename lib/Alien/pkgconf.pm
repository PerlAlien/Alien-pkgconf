package Alien::pkgconf;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Alien::pkgconf - Discover or download and install pkgconf + libpkgconf

=head1 SYNOPSIS

 use Alien::pkgconf;

=cut

sub cflags       {}
sub libs         {}
sub dynamic_libs {}
sub bin_dir      {}

1;

=head1 SEE ALSO

=over 4

=item L<PkgConfig::LibPkgConf>

=back

=head1 ACKNOWLEDGMENTS

Thanks to the C<pkgconf> developers for their efforts:

L<https://github.com/pkgconf/pkgconf/graphs/contributors>

=head1 AUTHOR

Graham Ollis

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 Graham Ollis.

This is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

