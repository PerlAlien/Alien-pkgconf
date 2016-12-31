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
use File::Path qw( rmtree );
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
    'Test::Alien'  => '0.08',
  },
  BUILD_REQUIRES => {
    'HTTP::Tiny'           => '0.044',
    'Archive::Tar'         => '2.24',
    'JSON::PP'             => '2.27400',
    'IO::Uncompress::UnXz' => '2.070',
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

my($dll) = eval {
  require FFI::CheckLib;
  FFI::CheckLib::find_lib_or_die(
    lib => 'pkgconf',
  );
};

my $install_type = 'share';



rmtree '_alien', 0, 0 if -d '_alien';

eval {

  die "ALIEN_FORCE" if $ENV{ALIEN_FORCE};
  die "ALIEN_INSTALL_TYPE" if defined $ENV{ALIEN_INSTALL_TYPE} 
                           && $ENV{ALIEN_INSTALL_TYPE} eq 'share';

  system 'pkgconf', '--atleast-version=1.0.90', 'libpkgconf';
  die "no pkgconf" if $?;
  my $cflags = `pkgconf --cflags libpkgconf`;
  die "getting cflags" if $?;
  chomp $cflags;
  my $libs   = `pkgconf --libs libpkgconf`;
  die "getting libs" if $?;
  chomp $libs;
  my $version = `pkgconf --modversion libpkgconf`;
  die "getting version" if $?;
  chomp $version;

  require File::Spec;
  require JSON::PP;
  my $status_filename = File::Spec->catfile('_alien', 'stage.json');
  mkdir '_alien' unless -d '_alien';
  open my $fh, '>', $status_filename;
  print $fh JSON::PP::encode_json({
    cflags       => $cflags,
    libs         => $libs,
    install_type => 'system',
    version      => $version,
    ($dll ? (dll => $dll ) : ()),
  });
  close $fh;
  
  $install_type = 'system';

};

if(defined $ENV{ALIEN_INSTALL_TYPE})
{
  if($ENV{ALIEN_INSTALL_TYPE} ne $install_type)
  {
    die "requested install type $ENV{ALIEN_INSTALL_TYPE}, but could not be accomidated";
  }
}

print "install type: $install_type\n";

WriteMakefile(%args);

sub MY::postamble {

$install_type eq 'share'

? <<'SHARE_INSTALL'

alien_probe _alien/probe.json:
	$(FULLPERL) script/probe.pl $(INSTALLARCHLIB)

alien_fetch _alien/fetch.json:
	$(FULLPERL) script/fetch.pl

alien_extract _alien/extract.json: _alien/fetch.json
	$(FULLPERL) script/extract.pl

alien_build: _alien/build_dll.json _alien/build_static.json

alien_build_dll _alien/build_dll.json : _alien/extract.json _alien/probe.json
	$(FULLPERL) script/build.pl dll

alien_build_static _alien/build_static.json : _alien/extract.json _alien/probe.json
	$(FULLPERL) script/build.pl static

alien_stage _alien/stage.json: _alien/build_dll.json _alien/build_static.json
	$(FULLPERL) script/stage.pl

alien_clean:
	$(FULLPERL) script/clean.pl

pure_all :: _alien/stage.json

realclean purge :: alien_clean

SHARE_INSTALL

: <<'SYSTEM_INSTALL';

alien_system _alien/system.json : _alien/stage.json
	$(FULLPERL) script/system.pl

alien_clean:
	$(FULLPERL) script/clean.pl

pure_all :: _alien/system.json

realclean purge :: alien_clean

SYSTEM_INSTALL

}
