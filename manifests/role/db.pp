# role/db.pp
# db::core and db::es

# Virtual resource for the monitoring server
@monitor_group { "es_pmtpa": description => "pmtpa External Storage" }
@monitor_group { "es_eqiad": description => "eqiad External Storage" }
@monitor_group { "mysql_pmtpa": description => "pmtpa mysql core" }
@monitor_group { "mysql_eqiad": description => "eqiad mysql core" }

class role::db::core {
	$cluster = "mysql"

	system_role { "db::core": description => "Core Database server" }

	include standard,
		mysql
}

class role::db::es($mysql_role = "slave") {
	$cluster = "mysql"

	$nagios_group = "es_${::site}"

	system_role { "db::es": description => "External Storage server (${mysql_role})" }

	include	standard,
		mysql,
		mysql::mysqluser,
		mysql::datadirs,
		mysql::conf,
		mysql::mysqlpath,
		mysql::monitor::percona::es,
		mysql::packages,
		nrpe

}

class role::db::fundraising {

	$crit = $master
	$cluster = "mysql"

	system_role { "role::db::fundraising": description => "Fundraising Database (${mysql_role})" }

	if $mysql_role == "slave" {
		monitor_service {"mysql slave delay": description => "MySQL Slave Delay", check_command => "nrpe_check_mysql_slave_delay", critical => false }
	}

	monitor_service {
		"mysqld":
			description => "mysqld processes",
			check_command => "nrpe_check_mysqld",
			critical => $crit;	
	}

}

class role::db::fundraising::master {
	$mysql_role = "master"
	include role::db::fundraising
}

class role::db::fundraising::slave {
	$mysql_role = "slave"
	include role::db::fundraising
}

class role::db::fundraising::dump {

	system_role { "role::db::fundraising::dump": description => "Fundraising Database Dump/Backup" }

	file {
		'/usr/local/bin/dump_fundraisingdb':
			mode => 0755,
			owner => root,
			group => root,
			source => "puppet:///files/misc/scripts/dump_fundraisingdb";
		'/root/.dump_fundraisingdb':
			mode => 0400,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/dump_fundraisingdb-${hostname}";
	}

	cron { 'dump_fundraising_database':
		user => root,
		minute => '35',
		hour => '1',
		command => '/usr/local/bin/dump_fundraisingdb',
		ensure => present,
	}

}
