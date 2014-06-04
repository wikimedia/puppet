# Service user to handle the post-merge hook on master
class puppetmaster::gitpuppet {

    generic::systemuser { 'gitpuppet':
        name          => 'gitpuppet',
        shell         => '/bin/sh',
        home          => '/home/gitpuppet',
        default_group => 'gitpuppet',
    }

    file { [ '/home/gitpuppet', '/home/gitpuppet/.ssh' ]:
        ensure  => directory,
        owner   => 'gitpuppet',
        group   => 'gitpuppet',
        mode    => '0700',
        require => User['gitpuppet'];
    }

    file {
        '/home/gitpuppet/.ssh/id_rsa':
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0400',
            source  => 'puppet:///private/ssh/gitpuppet/gitpuppet.key';
        '/home/gitpuppet/.ssh/gitpuppet-private-repo':
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0400',
            source  => 'puppet:///private/ssh/gitpuppet/gitpuppet-private.key';
        '/home/gitpuppet/.ssh/authorized_keys':
            owner   => 'gitpuppet',
            group   => 'gitpuppet',
            mode    => '0400',
            source  => 'puppet:///modules/puppetmaster/git/gitpuppet_authorized_keys';
    }
}

