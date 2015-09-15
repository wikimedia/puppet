# Class: toollabs
#
# This is a "sub" role included by the actual tool labs roles and would
# normally not be included directly in node definitions.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs (
    $external_hostname = undef,
    $external_ip = undef,
    $proxies = ['tools-webproxy-01', 'tools-webproxy-02'],
    $active_proxy = 'tools-webproxy-01',
    $active_redis = 'tools-redis-01',
    $active_redis_ip = '10.68.18.70',
    $is_mail_relay = false,
    $active_mail_relay = 'tools-mail.eqiad.wmflabs',
    $mail_domain = 'tools.wmflabs.org',
) {

    include labs_lvm

    $sysdir = '/data/project/.system'
    $store  = "${sysdir}/store"
    $repo   = "${sysdir}/deb-${::lsbdistcodename}"

    #
    # The $store is an incredibly horrid workaround the fact that we cannot
    # use exported resources in our puppet setup: individual instances store
    # information in a shared filesystem that are collected locally into
    # files to finish up the configuration.
    #
    # Case in point here: SSH host keys distributed around the project for
    # known_hosts and HBA of the execution nodes.
    #

    file { $sysdir:
        ensure  => directory,
        owner   => 'root',
        group   => "${::labsproject}.admin",
        mode    => '2775',
        require => Mount['/data/project'],
    }

    file { $store:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => File[$sysdir],
    }

    file { "${store}/hostkey-${::fqdn}":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => File[$store],
        content => "${::fqdn},${::hostname},${::ipaddress} ssh-rsa ${::sshrsakey}\n${::fqdn},${::hostname},${::ipaddress} ecdsa-sha2-nistp256 ${::sshecdsakey}\n"
    }

    exec { 'make_known_hosts':
        command => "/bin/cat ${store}/hostkey-* >/etc/ssh/ssh_known_hosts~",
        require => File[$store],
        onlyif  => "/usr/bin/test -n \"\$(/usr/bin/find ${store} -maxdepth 1 \\( -type d -or -type f -name hostkey-\\* \\) -newer /etc/ssh/ssh_known_hosts~)\" -o ! -s /etc/ssh/ssh_known_hosts~",
    }

    file { '/etc/ssh/ssh_known_hosts':
        ensure  => file,
        require => Exec['make_known_hosts'],
        source  => '/etc/ssh/ssh_known_hosts~',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    # This is atrocious, but the only way to make certain
    # that the gridengine system directory is properly shared
    # between all grid nodes for proper access to accounting
    # and scheduling.  Yes, this uses before.

    $geconf     = "${sysdir}/gridengine"
    $collectors = "${geconf}/collectors"

    file { $geconf:
        ensure  => directory,
        require => File[$sysdir],
    }

    file { $collectors:
        ensure  => directory,
        require => File[$geconf],
    }

    file { '/var/lib/gridengine':
        ensure  => directory,
    }

    mount { '/var/lib/gridengine':
        ensure  => mounted,
        atboot  => False,
        device  => "${sysdir}/gridengine",
        fstype  => none,
        options => 'rw,bind',
        require => File["${sysdir}/gridengine",
                        '/var/lib/gridengine'],
        before  => Package['gridengine-common'],
    }

    # this is a link to shared folder
    file { '/shared':
        ensure => link,
        target => '/data/project/.shared'
    }

    file { '/root/.bashrc':
        ensure => file,
        source => 'puppet:///modules/toollabs/rootrc',
        mode   => '0750',
        owner  => 'root',
        group  => 'root',
    }

    # TODO: Remove after migration. from Aptly to Labsdebrepo
    file { ['/etc/apt/preferences.d/tools-project.pref',
            '/etc/apt/sources.list.d/tools-project.list']:
        ensure => absent,
        notify => Exec['apt-get update'],
    }

    # Enable backports for specific distributions and packages only.
    case $::lsbdistcodename {
        'trusty': {
            $packages_from_backports = ['python-socketio-client']
        }
    }
    case $::operatingsystem {
        'Debian': {
            apt::repository { "${::lsbdistcodename}-backports":
                uri        => 'http://mirrors.wikimedia.org/debian',
                dist       => "${::lsbdistcodename}-backports",
                components => 'main',
            }
        }
        'Ubuntu': {
            apt::repository { "${::lsbdistcodename}-backports":
                uri        => 'http://nova.clouds.archive.ubuntu.com/ubuntu/',
                dist       => "${::lsbdistcodename}-backports",
                components => 'main restricted universe multiverse',
            }
        }
        default: {
            fail("Unknown operating system '$::operatingsystem'.")
        }
    }
    # By default, mark packages from backports as ineligible for
    # installation.
    apt::pin { "${::lsbdistcodename}-backports":
        pin      => "release a=${::lsbdistcodename}-backports",
        priority => -1,
        package  => '*',
    }
    # Explicitly white-list the packages we want to install from
    # backports.
    apt::pin { "${::lsbdistcodename}-backports-whitelisted":
        ensure   => $packages_from_backports ? {
            undef   => absent,
            default => present,
        },
        pin      => "release a=${::lsbdistcodename}-backports",
        priority => 500,
        package  => $packages_from_backports ? {
            undef   => undef,
            default => join($packages_from_backports, ' '),
        },
    }

    # Trustworthy enough
    # Only necessary on precise hosts, trusty has its own mariadb package
    if $::lsbdistcodename == 'precise' {
        apt::repository { 'mariadb':
            uri        => 'http://ftp.osuosl.org/pub/mariadb/repo/5.5/ubuntu',
            dist       => $::lsbdistcodename,
            components => 'main',
            source     => false,
            keyfile    => 'puppet:///modules/toollabs/mariadb.gpg',
        }
        file { '/etc/apt/trusted.gpg.d/mariadb.gpg':
            ensure => absent,
        }
    }

    # Users can choose their shell accounts names freely, and some
    # choose ones that can be misleading to third parties inter alia
    # when they are used to send and receive mail at
    # "$user@tools.wmflabs.org".  The most common ones are already
    # addressed by the default system aliases for "abuse",
    # "postmaster", "webmaster", etc., so we only have to add aliases
    # here that have not been standardized per se, but still bear a
    # high risk of mimicry.
    mailalias { [ 'admin', 'administrator' ]:
        ensure => present,
        recipient => 'root',
    }

    if !$is_mail_relay {
        class { 'exim4':
            queuerunner => 'queueonly',
            config      => template('toollabs/route-to-mail-relay.exim4.conf.erb'),
            variant     => 'light',
        }
    }

    file { '/var/mail':
        ensure => link,
        force  => true,
        target => "${store}/mail",
    }

    # Install at on all hosts for maintenance tasks.
    package { 'at':
        ensure => latest,
    }

    # Link to currently active proxy
    file { '/etc/active-proxy':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $active_proxy,
    }

    # puppetized until we can setup proper DNS for .labsdb entries
    file { '/etc/hosts':
        content => template('toollabs/hosts.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644'
    }

    # Silence e-mails sent when regular users try to sudo (T95882)
    file { '/etc/sudoers.d/40-tools-sudoers-no-warning':
        ensure => file,
        mode   => '0440',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/40-tools-sudoers-no-warning',
    }

    file { '/etc/cron.daily/logrotate':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/toollabs/logrotate.crondaily',
    }

    diamond::collector::localcrontab { 'localcrontabcollector': }
}
