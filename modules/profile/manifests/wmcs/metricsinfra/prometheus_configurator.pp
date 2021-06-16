class profile::wmcs::metricsinfra::prometheus_configurator (
    Array[Hash]  $projects = lookup('profile::wmcs::metricsinfra::projects'),
) {
    group { 'prometheus-configurator':
        ensure => present,
        system => true,
    }

    user { 'prometheus-configurator':
        ensure => present,
        system => true,
        gid    => 'prometheus-configurator',
        home   => '/nonexistent',
        groups => ['prometheus'],
    }

    file { '/etc/prometheus-configurator':
        ensure => directory,
        owner  => 'prometheus-configurator',
        group  => 'prometheus-configurator',
    }

    $project_configs = $projects.reduce ({}) |Hash $agg, Hash $project| {
        $jobs = has_key($project, 'jobs') ? {
            true  => $project['jobs'],
            false => [],
        }
        $alerts = has_key($project, 'alerts') ? {
            true  => $project['alerts'],
            false => [],
        }

        $agg.merge({
            $project['name'] => {
                jobs   => $jobs,
                alerts => $alerts,
            },
        })
    }
    $config = {
        openstack => {
            credentials => '/etc/novaobserver.yaml',
        },
        alertmanager_hosts => [
            'localhost:9093',
        ],
        global_jobs => [
            {
                name => 'node',
                openstack_discovery => {
                    port => 9100,
                },
            },
        ],
        projects => $project_configs,
    }

    file { '/etc/prometheus-configurator/config.yaml':
        ensure  => present,
        owner   => 'prometheus-configurator',
        group   => 'prometheus-configurator',
        content => ordered_yaml($config),
        mode    => '0440',
        notify  => Exec['prometheus-configurator'],
    }

    sudo::user { 'prometheus-configurator':
        user       => 'prometheus-configurator',
        privileges => [
            'ALL = NOPASSWD: /usr/bin/systemctl reload prometheus@cloud.service',
        ]
    }

    exec { 'prometheus-configurator':
        command     => '/home/taavi/configurator/metricsinfra.sh',
        user        => 'prometheus-configurator',
        group       => 'prometheus-configurator',
        require     => [
            Sudo::User['prometheus-configurator'],
            File['/etc/prometheus-configurator/config.yaml'],
        ],
        refreshonly => true,
    }
}
