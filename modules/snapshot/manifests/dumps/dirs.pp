class snapshot::dumps::dirs(
    $user = undef,
) {
    $dumpsdir = '/etc/dumps'
    file { $dumpsdir:
      ensure => 'directory',
      path   => $dumpsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $datadir = '/mnt/data/xmldatadumps'
    $apachedir = '/srv/mediawiki'
    $confsdir = "${dumpsdir}/confs"

    file { $confsdir:
      ensure => 'directory',
      path   => $confsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $dblistsdir = "${dumpsdir}/dblists"
    file { $dblistsdir:
      ensure => 'directory',
      path   => $dblistsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $stagesdir = "${dumpsdir}/stages"
    file { $stagesdir:
      ensure => 'directory',
      path   => $stagesdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    $cachedir = "${dumpsdir}/cache"
    file { $cachedir:
      ensure => 'directory',
      path   => $cachedir,
      mode   => '0755',
      owner  => $user,
      group  => 'root',
    }

    $templsdir = "${dumpsdir}/templs"
    file { $templsdir:
      ensure => 'directory',
      path   => $templsdir,
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    # maintained on the NFS fileserver, not here
    # but we need to know the path, used for
    # dumps and datasets other than the main
    # xml/sql dumps
    # make this explicit for now
    $otherdir = '/mnt/data/xmldatadumps/public/other'

    $repodir = '/srv/deployment/dumps/dumps/xmldumps-backup'

    file { '/usr/local/etc/set_dump_dirs.sh':
        ensure  => 'present',
        path    => '/usr/local/etc/set_dump_dirs.sh',
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/set_dump_dirs.sh.erb'),
    }

}
