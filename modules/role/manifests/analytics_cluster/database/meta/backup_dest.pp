# == Class role::analytics_cluster::database::meta::backup_dest
#
class role::analytics_cluster::database::meta::backup_dest {

    file { '/srv/backup':
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics-admins',
        mode   => '0755',
    }

    file { [
            '/srv/backup/mysql',
            '/srv/backup/mysql/analytics-meta',
        ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'analytics-admins',
        mode   => '0750',
    }

    include ::rsync::server

    # These are probably the same host, but in case they
    # aren't, allow either use of this rsync server module.
    $hosts_allow = [
        hiera('cdh::hive::metastore_host'),
        hiera('cdh::oozie::oozie_host'),
    ]
    # This will allow $hosts_allow to host public data files
    # generated by the analytics cluster.
    # Note that this requires that cdh::hadoop::mount
    # be present and mounted at /mnt/hdfs
    rsync::server::module { 'backup':
        path        => '/srv/backup',
        read_only   => 'no',
        list        => 'no',
        hosts_allow => $hosts_allow,
    }

    $rsync_clients_ferm = join($hosts_allow, ' ')
    ferm::service { 'analytics_cluster-backup-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve((${rsync_clients_ferm}))",
    }
}
