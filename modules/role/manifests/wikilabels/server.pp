# filtertags: labs-project-wikilabels
class role::wikilabels::server {

    system::role { $name: }

    include ::profile::standard
    include ::wikilabels::session

    class { '::profile::wikilabels':
        branch => 'deploy',
    }
}
