
class role::mariadb::beta {

    $cluster = 'beta'

    system::role { 'role::mariadb::beta':
        description => 'beta cluster database server',
    }

    include mariadb::packages
    include mariadb::beta::config
    include mariadb::beta::datadir
}

class role::mariadb::beta_slave {

    $cluster = 'beta'

    system::role { 'role::mariadb::beta_slave':
        description => 'beta cluster slave database server',
    }

    include mariadb::packages
    include mariadb::beta::config_slave
    include mariadb::beta::datadir
}

class role::mariadb::tendril {

    $cluster = 'mysql'

    system::role { 'role::mariadb::tendril':
        description => 'tendril database server',
    }

    include mariadb::packages
    include mariadb::tendril::config
    include mariadb::tendril::datadir
}
