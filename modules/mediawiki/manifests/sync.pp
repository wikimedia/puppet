# mediawiki syncing class
class mediawiki::sync {

	include misc::deployment::vars

	require mediawiki::packages
	require mediawiki::users::l10nupdate

	git::clone { 'mediawiki/tools/scap':
		ensure    => 'latest',
		directory => '/srv/scap',
		owner     => 'root',
		group     => 'wikidev',
		shared    => true,
		origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/tools/scap.git',
	}

	deployment::target { 'scap': }

	$scriptpath = "/usr/local/bin"

	file { "${scriptpath}/mwversionsinuse":
		ensure  => link,
		target  => '/srv/scap/bin/mwversionsinuse',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { "${scriptpath}/scap-rebuild-cdbs":
		ensure  => link,
		target  => '/srv/scap/bin/scap-rebuild-cdbs',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { "${scriptpath}/scap-recompile":
		ensure  => link,
		target  => '/srv/scap/bin/scap-recompile',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { "${scriptpath}/sync-common":
		ensure  => link,
		target  => '/srv/scap/bin/sync-common',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { "${scriptpath}/mergeCdbFileUpdates":
		ensure  => link,
		target  => '/srv/scap/bin/mergeCdbFileUpdates',
		require => Git::Clone['mediawiki/tools/scap'],
	}
	file { "${scriptpath}/refreshCdbJsonFiles":
		ensure  => link,
		target  => '/srv/scap/bin/refreshCdbJsonFiles',
		require => Git::Clone['mediawiki/tools/scap'],
	}

	exec { 'mw-sync':
		command     => "${scriptpath}/sync-common",
		require     => File["${scriptpath}/sync-common"],
		cwd         => '/tmp',
		user        => root,
		group       => root,
		path        => "${scriptpath}:/usr/bin:/usr/sbin",
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure;
	}

	exec { 'mw-sync-rebuild-cdbs':
		command     => "${scriptpath}/scap-rebuild-cdbs",
		cwd         => '/tmp',
		user        => 'mwdeploy',
		group       => 'mwdeploy',
		path        => "${scriptpath}:/usr/bin:/usr/sbin",
		refreshonly => true,
		timeout     => 600,
		logoutput   => on_failure,
		require     => File["${scriptpath}/scap-rebuild-cdbs"],
		subscribe   => Exec['mw-sync'],
	}
}
