# = Class: role::elasticsearch::server
#
# This class sets up Elasticsearch in a WMF-specific way.
#

@monitoring::group { 'elasticsearch_eqiad': description => 'eqiad elasticsearch servers' }
@monitoring::group { 'elasticsearch_codfw': description => 'codfw elasticsearch servers' }
@monitoring::group { 'elasticsearch_esams': description => 'esams elasticsearch servers' }
@monitoring::group { 'elasticsearch_ulsfo': description => 'ulsfo elasticsearch servers' }

class role::elasticsearch::server{

    if ($::realm == 'production' and hiera('elasticsearch::rack', undef) == undef) {
        fail("Don't know rack for ${::hostname} and rack awareness should be turned on")
    }

    if ($::realm == 'labs' and hiera('elasticsearch::cluster_name', undef) == undef) {
        $msg = '\$::elasticsearch::cluster_name must be set to something unique to the labs project.'
        $msg2 = 'You can set it in the hiera config of the project'
        fail("${msg}\n${msg2}")
    }

    include standard

    if hiera('has_lvs', true) {
        include lvs::realserver
    }

    ferm::service { 'elastic-http':
        proto => 'tcp',
        port  => '9200',
        srange => '$INTERNAL',
    }

    $elastic_nodes = hiera('elasticsearch::cluster_hosts::eqiad')
    $elastic_nodes_ferm = join($elastic_nodes, ' ')

    ferm::service { 'elastic-inter-node':
        proto => 'tcp',
        port  => '9300',
        srange  => "@resolve(($elastic_nodes_ferm))",
    }

    ferm::service { 'elastic-zen-discovery':
        proto => 'udp',
        port  => '54328',
        srange => '$INTERNAL',
    }

    system::role { 'role::elasticsearch::server':
        ensure      => 'present',
        description => 'elasticsearch server',
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    # Install
    class { '::elasticsearch':
        plugins_dir       => '/srv/deployment/elasticsearch/plugins',
        require           => Package['elasticsearch/plugins'],
        auto_create_index => '+apifeatureusage-*,-*',
        merge_threads     => 1,
    }

    if hiera('has_ganglia', true) {
        include ::elasticsearch::ganglia
    }

    include ::elasticsearch::log::hot_threads
    include ::elasticsearch::nagios::check
}
