# == Class role::analytics_cluster::rsyncd
# Set up an rsync module at certain paths to
# allow read only rsync access to analytics generated data.
#
class role::analytics_cluster::rsyncd {
    # TODO: Use hiera('statistics_servers') for this
    # instead of hardcoding here.
    $hosts_allow = [
        'stat1001.eqiad.wmnet',
        'stat1002.eqiad.wmnet',
        'stat1003.eqiad.wmnet',
        'analytics1027.eqiad.wmnet',
        'dataset1001.wikimedia.org',
    ]

    # This will allow $hosts_allow to host public data files
    # generated by the analytics cluster.
    # Note that this requires that cdh::hadoop::mount
    # be present and mounted at /mnt/hdfs
    rsync::server::module { 'hdfs-archive':
        path        => "${::cdh::hadoop::mount::mount_point}/wmf/data/archive",
        read_only   => 'yes',
        list        => 'yes',
        hosts_allow => $hosts_allow,
        require     => Class['cdh::hadoop::mount']
    }

    $hosts_allow_ferm = join($hosts_allow, ' ')
    ferm::service {'analytics_rsyncd_hdfs_archive':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${hosts_allow_ferm}))",
    }
}
