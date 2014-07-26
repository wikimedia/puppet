class role::labs::extdist {

    include role::labs::lvm::srv

    user { 'extdist':
        ensure => present,
        system => true,
    }

    exec { 'make-srv-usable-by-everyone':
        command => '/bin/chmod 077 /srv',
        unless  => "/bin/sh -c '[ $(/usr/bin/stat -c %a /srv) == 0777'",
        require => Mount['/srv']
    }

    git::clone {'labs/tools/extdist':
        directory => '/srv/extdist',
        ensure    => latest,
        branch    => 'master',
        require   => [Exec['make-srv-usable-by-everyone'], User['extdist']],
        owner     => 'extdist',
        group     => 'extdist',
    }

    package{'python-flask':
        ensure => latest,
    }

    uwsgi::app { 'extdist':
        require              => [Git::Clone['labs/tools/extdist'], Package['python-flask']],
        settings             => {
            uwsgi            => {
                'socket'     => '/run/uwsgi/extdist.sock',
                'wsgi-file'  => '/srv/extdist/extdist.wsgi',
                'master'     => true,
                'processes' => 4,
                'chdir'      => '/srv/extdist',
            },
        },
    }

    cron { 'extdist-generate-tarballs':
        command => '/usr/bin/python /srv/extdist/nightly.py',
        user    => 'extdist',
        hour    => '0',
        require => [Git::Clone['labs/tools/extdist'], User['extdist']]
    }

    nginx::site { 'extdist':
        require => Uwsgi::App['extdist'],
        content => template('extdist.nginx.erb'),
    }
}
