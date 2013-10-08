class mysql_wmf::coredb::monitoring( $crit = false, $no_slave = false ) {

        include passwords::nagios::mysql
        $mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

        # this is for checks from the percona-nagios-checks project
        # http://percona-nagios-checks.googlecode.com
        file {
            "/etc/nagios/nrpe.d/nrpe_percona.cfg":
                owner => root,
                group => nagios,
                mode => 0440,
                content => template("mysql_wmf/icinga/nrpe_coredb_percona.cfg.erb"),
                notify => Service[nagios-nrpe-server];
            "/usr/lib/nagios/plugins/percona":
                ensure => directory,
                recurse => true,
                owner => root,
                group => root,
                mode => 0555,
                source => "puppet:///modules/mysql_wmf/icinga/percona";
        }

    monitor_service { "mysql disk space": description => "MySQL disk space", check_command => "nrpe_check_disk_6_3", critical => true }
    monitor_service { "mysqld": description => "mysqld processes", check_command => "nrpe_check_mysqld", critical => $crit }
    monitor_service { "mysql recent restart": description => "MySQL Recent Restart", check_command => "nrpe_check_mysql_recent_restart", critical => $crit }
    monitor_service { "mysql processlist": description => "MySQL Processlist", check_command => "nrpe_pmp_check_mysql_processlist", critical => false }

    if $no_slave == false {
        monitor_service { "full lvs snapshot": description => "Full LVS Snapshot", check_command => "nrpe_check_lvs", critical => false }
        monitor_service { "mysql idle transaction": description => "MySQL Idle Transactions", check_command => "nrpe_check_mysql_idle_transactions", critical => false }
        monitor_service { "mysql replication heartbeat": description => "MySQL Replication Heartbeat", check_command => "nrpe_check_mysql_slave_heartbeat", critical => false }
        monitor_service { "mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => false }
        monitor_service { "mysql slave running": description => "MySQL Slave Running", check_command => "nrpe_check_mysql_slave_running", critical => false }
    }
}
