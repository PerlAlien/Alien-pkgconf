use strict;
use warnings;

BEGIN {
  unless(eval q{ use 5.008001; 1 })
  {
    print "Sorry!  Perl 5.8.1 or better required\n";
    exit;
  }
}

use ExtUtils::MakeMaker;
use Config;

my %args = (
  ABSTRACT           => 'Discover or download and install pkgconf + libpkgconf',
  AUTHOR             => [ 'Graham Ollis <plicease@cpan.org>' ],
  DISTNAME           => 'Alien-pkgconf',
  LICENSE            => 'perl',
  MIN_PERL_VERSION   => '5.008001',
  NAME               => 'Alien::pkgconf',
  VERSION_FROM       => 'lib/Alien/pkgconf.pm',
  
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
  },
  TEST_REQUIRES      => {
    'Test2'        => '1.302073',
    'Test2::Suite' => '0.000065',
  },
  BUILD_REQUIRES => {
    'HTTP::Tiny' => '0.044',
    'Archive::Tar' => '2.24',
  },
  PREREQ_PM => {
  },
  
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => "http://github.com/plicease/Alien-pkgconf",
      bugtracker => "http://github.com/plicease/Alien-pkgconf/issues",
      x_MailingList => "https://groups.google.com/forum/#!forum/perl5-alien",
      x_IRC => "irc://irc.perl.org/#native",
    }
  },
  
  clean => {
    # !!??
  }
);

my %fallback = (
  %{ $args{TEST_REQUIRES} },
  %{ $args{BUILD_REQUIRES} },
  %{ $args{PREREQ_PM} },
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  $args{PREREQ_PM} = \%fallback;
  delete $args{TEST_REQUIRES};
  delete $args{BUILD_REQUIRES};
}

delete $args{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%args);
