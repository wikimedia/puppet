# == Class: trafficserver
# this class handles common stuff for every trafficserver instance
# === Parameters
#
# [*user*]
#   Run trafficserver as this user (default: 'trafficserver').
# [*packages*]
#   Array of required packages to run trafficserver (default: ['trafficserver', 'trafficserver-experimental-plugins']).
class trafficserver(
  String $user = 'trafficserver',
  Array[String] $packages = ['trafficserver', 'trafficserver-experimental-plugins'],
) {
    # ATS is built against libhwloc5 1.11.12 from stretch-backports. Ensure we
    # install that version and not the earlier one from stretch.
    apt::pin { 'libhwloc5':
        pin      => 'release a=stretch-backports',
        package  => 'libhwloc5',
        priority => '1001',
        before   => Package[$packages],
    }

    # Mask trafficserver.service if the package is not installed yet. The
    # unless is deplorable but there is no way in Puppet to execute a command
    # only if a package is being installed but before package installation.
    systemd::mask { 'trafficserver.service':
        unless => '/usr/bin/dpkg -s trafficserver | /bin/grep -q "^Status: install ok installed$"',
    }

    ## Packages
    package { $packages:
        ensure  => present,
        require => [ Exec['apt-get update'], Systemd::Mask['trafficserver.service'] ],
    }
}
