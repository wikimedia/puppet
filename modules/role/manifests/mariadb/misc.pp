# miscellaneous services clusters
class role::mariadb::misc(
    $shard  = 'm1',
    $master = false,
    ) {

    system::role { 'role::mariadb::misc':
        description => "Misc Services Database ${shard}",
    }

    $read_only = $master ? {
        true  => 0,
        false => 1,
    }

    $mysql_role = $master ? {
        true  => 'master',
        false => 'slave',
    }

    include standard
    include role::mariadb::monitor
    include passwords::misc::scripts
    include role::mariadb::ferm
    class { 'role::mariadb::groups':
        mysql_group => 'misc',
        mysql_shard => $shard,
        mysql_role  => $mysql_role,
    }

    class { 'mariadb::packages_wmf':
        mariadb10 => true,
    }

    class { 'mariadb::config':
        config    => 'mariadb/misc.my.cnf.erb',
        datadir   => '/srv/sqldata',
        tmpdir    => '/srv/tmp',
        read_only => $read_only,
    }

    class { 'role::mariadb::grants::production':
        shard    => $shard,
        prompt   => "MISC ${shard}",
        password => $passwords::misc::scripts::mysql_root_pass,
    }

    class { 'mariadb::heartbeat':
        shard      => $shard,
        datacenter => $::site,
        enabled    => $master,
    }
}

