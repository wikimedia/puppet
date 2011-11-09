# this section from old exim.pp

class exim::packages {
	if ! $exim_install_type {
		$exim_install_type = 'light'
	}

	package { [ "exim4-config" ]:
		ensure => latest;
	}

	if ( $exim_install_type == 'light' ) {
		package { [ "exim4-daemon-light" ]:
			ensure => latest;
		}
	}
	if ( $exim_install_type == 'heavy' ) {
		package { [ "exim4-daemon-heavy" ]:
			ensure => latest;
		}
	}
}

class exim::config {

	if ! $exim_queuerunner {
		$exim_queuerunner = 'queueonly'
	}

	file {
		"/etc/default/exim4":
			owner => root,
			group => root,
			mode => 0444,
			content => template("exim/exim4.default.erb");
	}
}

class exim::service {

	if ( $exim_install_type == 'light' ) {
		service {
			"exim4":
				require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-light] ],
				subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
				ensure => running;
		}
	}
	if ( $exim_install_type == 'heavy' ) {
		service {
			"exim4":
				require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-heavy] ],
				subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
				ensure => running;
		}
	}
}

class exim::simple-mail-sender {
	$exim_queuerunner = 'queueonly'
	$exim_install_type = 'light'

	require exim::packages
	include exim::config
	include exim::service


	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.minimal.conf";
	}
}

class exim::rt {
	$exim_queuerunner = 'combined'
	$exim_install_type = 'light'

	require exim::packages
	include exim::config
	include exim::service

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.rt.conf";
	}

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}

class exim::smtp {

	$smtp_ldap_password = $passwords::exim4::smtp_ldap_password
}

class exim::listserve {
	$exim_install_type = 'heavy'
	$exim_queuerunner = 'combined'
	$exim_conf_type = 'mailman'

	include exim::packages
	include exim::config
	include exim::service

	file {
		# TODO: Might want to make this a puppet list instead of a fixed file
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///templates/exim/exim4.conf.listserve";
		"/etc/exim4/relay_domains":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.listserver_relay_domains.conf";
		"/etc/exim4/aliases/":
			require => Package[exim4-config],
			mode => 0755,
			owner => root,
			group => root,
			path => "/etc/exim4/aliases/",
			ensure => directory;
		"/etc/exim4/aliases/lists.wikimedia.org":
			require => [ File["/etc/exim4/aliases"], Package[exim4-config] ],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.listserver_aliases.conf";
		"/etc/exim4/system_filter":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///private/exim/exim4.listserver_system_filter.conf.listserve";
	}

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}


# SpamAssassin http://spamassassin.apache.org/

class spamassassin {

	package { [ "spamassassin" ]:
		ensure => latest;
	}

	file {
		"/etc/spamassassin/local.cf":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/spamassassin/local.cf";
		"/etc/default/spamassassin":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/spamassassin/spamassassin.default";
	}

	service { "spamassassin":
			require => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"], Package[spamassassin] ],
			subscribe => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"],
			ensure => running;
	}

	user { "spamd":
		ensure => present;
	}

	file { "/var/spamd":
		ensure => directory,
		owner => spamd,
		group => spamd,
		mode => 0700;
	}

	monitor_service { "spamd": description => "spamassassin", check_command => "check_procs_spamd" }
}

# this section from old mailman.pp

# basic mailman
class mailman::base {

	package { [ "mailman" ]:
		ensure => latest;
	}
	
	monitor_service { "procs_mailman": description => "mailman", check_command => "check_procs_mailman" }

}


# mailman for a list server
class mailman::listserve {

	require mailman::base
	require lighttpd::mailman

	file {
		"/etc/mailman/mm_cfg.py":
			require => Package[mailman],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/mailman/mm_cfg.py";

	}
}


# FIXME: this should not be in mailman.pp
# Create or use a generic lighttpd installer (may already
# exist in generic-definitions), and then put mailman specific
# config bits in conf.d/ directory files. Those can be installed
# here.

# lighttpd setup as used by the mailman UI (lists.wm)
class lighttpd::mailman {

	package { [ "lighttpd" ]:
			ensure => latest;
	}

	file {
		"/etc/lighttpd":
			ensure => directory,
			# puppet will automatically set +x for directories
			mode => 0644,
			owner => root,
			group => root;
		"lighttpd.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/lighttpd.conf",
			source => "puppet:///files/lighttpd/list-server.conf";
		"mailman-private-archives.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/mailman-private-archives.conf",
			source => "puppet:///files/lighttpd/mailman-private-archives.conf";
		"/etc/lighttpd/ssl":
			ensure => directory,
			mode => 0644,
			owner => root,
			group => root;
	}
	
	# if we have this we dont need the lists. cert, right? we had them both before
	install_certificate{ "star.wikimedia.org": }

	service { "lighttpd":
			require => [ File["lighttpd.conf"], File["mailman-private-archives.conf"], Package[lighttpd] ],
			subscribe => [ File["lighttpd.conf"], File["mailman-private-archives.conf"] ],
			ensure => running;
	}

	# monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http" }
	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
}
