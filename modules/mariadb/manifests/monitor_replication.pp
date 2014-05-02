# MariaDB 10 multi-source replication

class mariadb::monitor_replication(
    $is_critical   = true,
    $contact_group = 'dba',
    $channel       = 's1',
    $lag_warn      = 60,
    $lag_crit      = 300,
    $socket        = '/tmp/mysql.sock',
    ) {

    file { '/usr/lib/nagios/plugins/check_mariadb.pl':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///files/icinga/check_mariadb.pl',
    }

    include passwords::nagios::mysql
    $password = $passwords::nagios::mysql::mysql_check_pass

    $check_mariadb = "/usr/lib/nagios/plugins/check_mariadb.pl --sock=${socket} --user=nagios --pass=${password} --set=default_master_connection=${channel}"

    nrpe::monitor_service { "mariadb_slave_io_state_${channel}":
        description   => "MariaDB Slave IO: ${channel}",
        nrpe_command  => "${check_mariadb} --check=slave_io_state",
        critical      => true,
        contact_group => $contact_group,
    }

    nrpe::monitor_service { "mariadb_slave_sql_state_${channel}":
        description   => "MariaDB Slave SQL: ${channel}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_state",
        critical      => true,
        contact_group => $contact_group,
    }

    nrpe::monitor_service { "mariadb_slave_sql_lag_${channel}":
        description   => "MariaDB Slave Lag: ${channel}",
        nrpe_command  => "${check_mariadb} --check=slave_sql_lag --sql-lag-warn=${lag_warn} --sql-lag-crit=${lag_crit}",
        critical      => true,
        contact_group => $contact_group,
    }
}