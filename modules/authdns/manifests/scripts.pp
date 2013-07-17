# == Class authdns::monitoring
# Scripts used by the authdns system. These used to be in a package,
# but we don't do that anymore and provisioning them here instead.
#
class authdns::scripts {
    if ! defined(Package['python-jinja2']){
        package { 'python-jinja2':
            ensure => present,
        }
    }

    if ! defined(Package['git-core']){
        package { 'git-core':
            ensure => present,
        }
    }

    file { '/usr/local/bin/authdns-gen-zones':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/authdns/authdns-gen-zones.py',
    }
    file { '/usr/local/sbin/authdns-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/authdns/authdns-update',
    }

    file { '/usr/local/sbin/authdns-local-update':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/authdns/authdns-local-update',
    }

    file { '/usr/local/sbin/authdns-git-pull':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/authdns/authdns-git-pull',
    }
}
