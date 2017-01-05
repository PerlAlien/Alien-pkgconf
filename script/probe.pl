use strict;
use warnings;
use Config;
use File::Spec;
use JSON::PP qw( encode_json decode_json );

my $status_filename = File::Spec->catfile('_alien', '01probe.json');
exit if -e $status_filename;

my $archlib = do {
  my($type, $perl, $site, $vendor) = @ARGV;
  die "invoke from makefile" unless $type && $perl && $site;
  $type eq 'perl' ? $perl : $type eq 'site' ? $site : $type eq 'vendor' ? $vendor : die "illegal INSTALLDIRS ($type)";
};
my @prefix = ($archlib, qw( auto share dist Alien-pkgconf ));

my %status = (
  prefix => \@prefix
);

#my @pkg_config_dir;
#my @system_libdir;
#my @system_includedir;

# These are based on experience in development of PkgConfig.pm:

if($^O eq 'solaris')
{
  if($Config{ptrsize} == 8)
  {
    $status{pkg_config_dir}    = [qw(
      /usr/local/lib/64/pkgconfig
      /usr/local/share/pkgconfig
      /usr/lib/64/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = [qw(
      /usr/local/lib/64
      /usr/lib/64
    )];
    $status{system_includedir} = [qw(
      /usr/local/include
      /usr/include
    )];
  }
  else
  {
    $status{pkg_config_dir}    = [qw(
      /usr/local/lib/pkgconfig
      /usr/local/share/pkgconfig
      /usr/lib/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = [qw(
      /usr/local/lib
      /usr/lib
    )];
    $status{system_includedir} = [qw(
      /usr/local/include
      /usr/include
    )];
  }
}

elsif($^O eq 'linux' && -f '/etc/gentoo-release')
{
  if($Config{ptrsize} == 8)
  {
    $status{pkg_config_dir}    = [qw(
      /usr/lib64/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = ['/usr/lib64'];
    $status{system_includedir} = ['/usr/include'];
  }
  else
  {
    $status{pkg_config_dir}    = [qw(
      /usr/lib/pkgconfig
      /usr/share/pkgconfig
    )];
    $status{system_libdir}     = ['/usr/lib'];
    $status{system_includedir} = ['/usr/include'];
  }
}

elsif($^O =~ /^(gnukfreebsd|linux)$/ && -r "/etc/debian_version")
{

  my $arch;
  if(-x "/usr/bin/dpkg-architecture")
  {
    # works if dpkg-dev is installed
    # rt96694
    ($arch) = map { chomp; (split /=/)[1] }
              grep /^DEB_HOST_MULTIARCH=/,
              `/usr/bin/dpkg-architecture`;
  }
  elsif(-x "/usr/bin/gcc")
  {
    # works if gcc is instaled
    $arch = `/usr/bin/gcc -dumpmachine`;
    chomp $arch;
  }
  else
  {
    my $deb_arch = `dpkg --print-architecture`;
    if($deb_arch =~ /^amd64/)
    {
      if($^O eq 'linux') {
        $arch = 'x86_64-linux-gnu';
      } elsif($^O eq 'gnukfreebsd') {
        $arch = 'x86_64-kfreebsd-gnu';
      }
    }
    elsif($deb_arch =~ /^i386/)
    {
      if($^O eq 'linux') {
        $arch = 'i386-linux-gnu';
      } elsif($^O eq 'gnukfreebsd') {
        $arch = 'i386-kfreebsd-gnu';
      }
    }
  }
    
  if($arch)
  {
    if(scalar grep /--print-foreign-architectures/, `dpkg --help`)
    {
      $status{pkg_config_dir}    = [
        "/usr/local/lib/$arch/pkgconfig",
        "/usr/local/lib/pkgconfig",
        "/usr/local/share/pkgconfig",
        "/usr/lib/$arch/pkgconfig",
        "/usr/lib/pkgconfig",
        "/usr/share/pkgconfig"
      ];
      $status{system_libdir}     = [
        "/usr/lib",
        "/usr/local/lib",
        "/usr/local/lib/$arch",
        "/usr/lib/$arch",
      ];
      $status{system_includedir} = [
        "/usr/include",
        "/usr/local/include",
      ];
    }
    else
    {
      $status{pkg_config_dir}    = [
        "/usr/local/lib/pkgconfig",
        "/usr/local/lib/pkgconfig/$arch",
        "/usr/local/share/pkgconfig",
        "/usr/lib/pkgconfig",
        "/usr/lib/pkgconfig/$arch",
        "/usr/share/pkgconfig"
      ];
      $status{system_libdir}     = [
        "/usr/lib",
        "/usr/local/lib",
      ];
      $status{system_includedir} = [
        "/usr/include",
        "/usr/local/include",
      ];
    }
  }
  else
  {
    $status{pkg_config_dir}    = [
      "/usr/local/lib/pkgconfig",
      "/usr/local/share/pkgconfig",
      "/usr/lib/pkgconfig",
      "/usr/share/pkgconfig"
    ];
    $status{system_libdir}     = [
      "/usr/lib",
      "/usr/local/lib",
    ];
    $status{system_includedir} = [
      "/usr/include",
      "/usr/local/include",
    ];
  }
}

elsif($^O eq 'freebsd')
{
  $status{pkg_config_dir} = [
    "/usr/local/libdata/pkgconfig",
    "/usr/libdata/pkgconfig",
  ];
  $status{system_libdir}     = [
    "/usr/lib",
  ];
  $status{system_includedir} = [
    "/usr/include",
  ];
}

else
{
  die "do not know enough about this OS to probe for correct paths";
}

unshift @{ $status{pkg_config_dir} }, File::Spec->catdir(@prefix, 'lib', 'pkgconfig');

mkdir '_alien' unless -d '_alien';
open my $fh, '>', $status_filename;
print $fh encode_json(\%status);
close $fh;
