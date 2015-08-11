class role::cache::upload(
    $upload_domain = 'upload.wikimedia.org',
    $top_domain = 'org'
) {
    system::role { 'role::cache::upload':
        description => 'upload Varnish cache server',
    }

    class { 'varnish::htcppurger': varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ] }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['upload'][$::site],
    }

    $upload_nodes = hiera('cache::upload::nodes')
    $site_upload_nodes = $upload_nodes[$::site]

    # 1/12 of total mem
    $memory_storage_size = ceiling(0.08333 * $::memorysize_mb / 1024.0)

    include role::cache::ssl::unified

    $varnish_be_directors = {
        'one' => {
            'backend'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['swift'][$::mw_primary],
            },
            'rendering'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            },
        },
        'two' => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $upload_nodes['eqiad'],
            },
        }
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    $cluster_options = {
        'upload_domain'   => $upload_domain,
        'top_domain'      => $top_domain,
        'do_gzip'         => true,
        'https_redirects' => true,
    }

    $storage_size_bigobj = floor($::role::cache::2layer::storage_size / 6)
    $storage_size_up = $::role::cache::2layer::storage_size - $storage_size_bigobj
    $upload_storage_args = join([
        "-s main1=persistent,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.main1,${storage_size_up}G,${::role::cache::2layer::mma[0]}",
        "-s main2=persistent,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.main2,${storage_size_up}G,${::role::cache::2layer::mma[1]}",
        "-s bigobj1=file,/srv/${::role::cache::2layer::storage_parts[0]}/varnish.bigobj1,${storage_size_bigobj}G",
        "-s bigobj2=file,/srv/${::role::cache::2layer::storage_parts[1]}/varnish.bigobj2,${storage_size_bigobj}G",
    ], ' ')

    varnish::instance { 'upload-backend':
        name               => '',
        vcl                => 'upload-backend',
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => ['default_ttl=2592000'],
        storage            => $upload_storage_args,
        directors          => $varnish_be_directors[$::site_tier],
        vcl_config         => {
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
            'layer'            => 'backend',
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match' => '^cp[0-9]+\.eqiad.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 1000,
            },
        ]),
        cluster_options    => $cluster_options,
    }

    varnish::instance { 'upload-frontend':
        name               => 'frontend',
        vcl                => 'upload-frontend',
        port               => 80,
        admin_port         => 6082,
        runtime_parameters => ['default_ttl=2592000'],
        storage            => "-s malloc,${memory_storage_size}G",
        directors          => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_upload_nodes,
            },
        },
        vcl_config         => {
            'retry503'         => 1,
            'cache4xx'         => '1m',
            'purge_host_regex' => $::role::cache::base::purge_host_only_upload_re,
            'layer'            => 'frontend',
        },
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '35s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
        cluster_options    => $cluster_options,
    }

    include role::cache::logging

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic => 'webrequest_upload',
        }
    }
}
