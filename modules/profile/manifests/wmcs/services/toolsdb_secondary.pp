# = Class: profile::wmcs::services::toolsdb_secondary
#
# This class sets up MariaDB for a secondary tools database.
#
class profile::wmcs::services::toolsdb_secondary (
    Stdlib::Unixpath $socket = lookup('profile::wmcs::services::toolsdb::socket', {default_value => '/var/run/mysqld/mysqld.sock'})
) {
    require profile::wmcs::services::toolsdb_apt_pinning

    require profile::mariadb::packages_wmf
    include profile::mariadb::wmfmariadbpy
    class { '::mariadb::service': }

    # This should depend on labs_lvm::srv but the /srv/ vols were hand built
    # on the first two toolsdb VMs to exactly match the physical servers.
    # New ones should directly use that profile so we can add it here.
    file { '/srv/labsdb':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    file { '/srv/labsdb/binlogs':
        ensure => directory,
        mode   => '0755',
        owner  => 'mysql',
        group  => 'mysql',
    }

    class { 'mariadb::config':
        config        => 'role/mariadb/mysqld_config/tools.my.cnf.erb',
        datadir       => '/srv/labsdb/data',
        tmpdir        => '/srv/labsdb/tmp',
        basedir       => $profile::mariadb::packages_wmf::basedir,
        read_only     => 'ON',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
        socket        => $socket,
    }

    class { 'profile::mariadb::monitor::prometheus':
        socket => $socket,
    }
}
