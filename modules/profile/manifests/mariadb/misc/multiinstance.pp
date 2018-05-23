class profile::mariadb::misc::multiinstance (
    $num_instances = hiera('profile::mariadb::misc::multiinstance::num_instances'),
    $m1            = hiera('profile::mariadb::misc::multiinstance::m1', false),
    $m2            = hiera('profile::mariadb::misc::multiinstance::m2', false),
    $m3            = hiera('profile::mariadb::misc::multiinstance::m3', false),
    $m4            = hiera('profile::mariadb::misc::multiinstance::m4', false),
) {
    class { 'mariadb::packages_wmf': }
    class { 'mariadb::service':
        override => "[Service]\nExecStartPre=/bin/sh -c \"echo 'mariadb main service is \
disabled, use mariadb@<instance_name> instead'; exit 1\"",
    }

    $basedir = '/opt/wmf-mariadb101'
    class { 'mariadb::config':
        datadir       => false,
        basedir       => $basedir,
        config        => 'role/mariadb/mysqld_config/misc_multiinstance.my.cnf.erb',
        p_s           => 'on',
        ssl           => 'puppet-cert',
        binlog_format => 'ROW',
    }

    file { '/etc/mysql/mysqld.conf.d':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    if $m1 {
        mariadb::instance { 'm1':
            port                    => 3321,
            innodb_buffer_pool_size => $m1,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::ferm { 'm1': port => '3321' }
        profile::prometheus::mysqld_exporter_instance { 'm1': port => 13321, }
    }
    if $m2 {
        mariadb::instance { 'm2':
            port                    => 3322,
            innodb_buffer_pool_size => $m2,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::ferm { 'm2': port => '3322' }
        profile::prometheus::mysqld_exporter_instance { 'm2': port => 13322, }
    }
    if $m3 {
        mariadb::instance { 'm3':
            port                    => 3323,
            innodb_buffer_pool_size => $m3,
            template                => 'profile/mariadb/mysqld_config/phabricator_instance.my.cnf.erb'
        }
        profile::mariadb::ferm { 'm3': port => '3323' }
        profile::prometheus::mysqld_exporter_instance { 'm3': port => 13323, }
        file { '/etc/mysql/phabricator-stopwords.txt':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('role/phabricator/stopwords.txt.erb'),
        }

        file { '/etc/mysql/phabricator-stopwords-update.sql':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('role/phabricator/stopwords-update.sql.erb'),
        }

        file { '/etc/mysql/phabricator-init.sql':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('role/phabricator/init.sql.erb'),
        }
    }
    if $m5 {
        mariadb::instance { 'm5':
            port                    => 3325,
            innodb_buffer_pool_size => $m5,
            # template                => 'profile/mariadb/mysqld_config/misc.my.cnf.erb'
        }
        profile::mariadb::ferm { 'm5': port => '3325' }
        class { 'profile::mariadb::ferm_wmcs':
            port => '3325',
        }
        profile::prometheus::mysqld_exporter_instance { 'm5': port => 13325, }
    }

    class { 'mariadb::monitor_disk':
        is_critical   => false,
        contact_group => 'admins',
    }

    class { 'mariadb::monitor_process':
        process_count => $num_instances,
        is_critical   => false,
        contact_group => 'admins',
    }
}
