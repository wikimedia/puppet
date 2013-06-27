# ishmael web app
#
# NOTE: this does not install ishmael.. it could be git deployed, but it hasn't been moved to a wmf repo. for now:
# cd /srv ; git clone https://github.com/asher/ishmael.git ; cd ishmael ; git clone https://github.com/asher/ishmael.git sample
#
class misc::ishmael {
	system_role { "misc::ishmael": description => "ishmael server" }

	include passwords::ldap::wmf_cluster
	$proxypass = $passwords::ldap::wmf_cluster::proxypass

	file { '/etc/apache2/sites-available/ishmael.wikimedia.org':
		ensure => present,
		owner  => 'root',
		group  => 'root',
		mode   => '0440',
		content => template('apache/sites/ishmael.wikimedia.org.erb');
	}

	define ishmael_config( file=$title, review_table='%query_review', history_table='%query_review_history' ) {
		include passwords::mysql::querydigest

		file { $file:
			owner => "root",
			group => "root",
			mode => 0444,
			content => template('ishmael/conf.php.erb');
		}
	}

	ishmael_config { '/srv/ishmael/conf.php': }
	ishmael_config { '/srv/ishmael/sample/conf.php':
		review_table => '%tcpquery_review', history_table => '%tcpquery_review_history' }
}
