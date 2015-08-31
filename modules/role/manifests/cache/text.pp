class role::cache::text (
    $bits_domain = 'bits.wikimedia.org',
    $top_domain = 'org'
) {
    system::role { 'role::cache::text':
        description => 'text Varnish cache server',
    }

    class { 'varnish::htcppurger': varnish_instances => [ '127.0.0.1:80', '127.0.0.1:3128' ] }

    include role::cache::2layer

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::service_ips['text'][$::site],
    }

    $text_nodes = hiera('cache::text::nodes')
    $site_text_nodes = $text_nodes[$::site]

    # 1/8 of total mem
    $memory_storage_size = ceiling(0.125 * $::memorysize_mb / 1024.0)

    include role::cache::ssl::unified

    require geoip
    require geoip::dev # for VCL compilation using libGeoIP

    $varnish_be_directors = {
        'one' => {
            'backend'          => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['appservers'][$::mw_primary],
            },
            'api'              => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['api'][$::mw_primary],
            },
            'rendering'        => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['rendering'][$::mw_primary],
            },
            'security_audit'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['security_audit'][$::mw_primary],
            },
            'test_wikipedia'   => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['test_appservers'][$::mw_primary],
            },
            'restbase_backend' => {
                'dynamic'  => 'no',
                'type'     => 'random',
                'backends' => $role::cache::configuration::backends[$::realm]['restbase'][$::mw_primary],
            },
        },
        'two' => {
            'backend'        => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $text_nodes['eqiad'],
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $text_nodes['eqiad'],
                'service'  => 'varnish-be-rand',
            },
        },
    }

    if $::role::cache::configuration::has_ganglia {
        include varnish::monitoring::ganglia::vhtcpd
    }

    $common_vcl_config = {
        'cache4xx'           => '1m',
        'purge_host_regex'   => $::role::cache::base::purge_host_not_upload_re,
        'bits_domain'        => $bits_domain,
        'top_domain'         => $top_domain,
        'do_gzip'            => true,
    }

    $be_vcl_config = merge($common_vcl_config, {
        'layer'              => 'backend',
    })

    $fe_vcl_config = merge($common_vcl_config, {
        'layer'              => 'frontend',
        'retry503'           => 1,
        'enable_geoiplookup' => true,
        'https_redirects'    => true,
    })

    varnish::instance { 'text-backend':
        name               => '',
        vcl                => 'text-backend',
        extra_vcl          => ['text-common'],
        port               => 3128,
        admin_port         => 6083,
        runtime_parameters => ['default_ttl=2592000'],
        storage            => $::role::cache::2layer::persistent_storage_args,
        directors          => $varnish_be_directors[$::site_tier],
        vcl_config         => $be_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'backend_match' => '^cp[0-9]+\.eqiad\.wmnet$',
                'port'          => 3128,
                'probe'         => 'varnish',
            },
            {
                'backend_match'   => '^mw1017\.eqiad\.wmnet$',
                'max_connections' => 20,
            },
            {
                'backend_match'   => '^restbase\.svc\.|^deployment-restbase',
                'port'            => 7231,
                'max_connections' => 5000,
            },
            {
                'port'                  => 80,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '180s',
                'between_bytes_timeout' => '4s',
                'max_connections'       => 1000,
            },
        ]),
    }

    varnish::instance { 'text-frontend':
        name               => 'frontend',
        vcl                => 'text-frontend',
        extra_vcl          => ['text-common'],
        port               => 80,
        admin_port         => 6082,
        runtime_parameters => ['default_ttl=2592000'],
        storage            => "-s malloc,${memory_storage_size}G",
        directors          => {
            'backend' => {
                'dynamic'  => 'yes',
                'type'     => 'chash',
                'backends' => $site_text_nodes,
            },
            'backend_random' => {
                'dynamic'  => 'yes',
                'type'     => 'random',
                'backends' => $site_text_nodes,
                'service'  => 'varnish-be-rand',
            },
        },
        vcl_config         => $fe_vcl_config,
        backend_options    => array_concat($::role::cache::2layer::backend_scaled_weights, [
            {
                'port'                  => 3128,
                'connect_timeout'       => '5s',
                'first_byte_timeout'    => '185s',
                'between_bytes_timeout' => '2s',
                'max_connections'       => 100000,
                'probe'                 => 'varnish',
            },
        ]),
    }

    include role::cache::logging

    class { '::role::cache::kafka::statsv':
        varnish_name => 'frontend',
    }

    # role::cache::logging::eventlistener will soon be fully
    # replaced by role::cache::kafka::eventlogging.
    class { '::role::cache::logging::eventlistener':
        instance_name => 'frontend',
    }
    class { '::role::cache::kafka::eventlogging':
        varnish_name => 'frontend',
    }

    # ToDo: Remove production conditional once this works
    # is verified to work in labs.
    if $::realm == 'production' {
        # Install a varnishkafka producer to send
        # varnish webrequest logs to Kafka.
        class { 'role::cache::kafka::webrequest':
            topic => 'webrequest_text',
        }
    }

    # Test rollout of varnish reqstats diamond collector.
    if $::hostname == 'cp1052' {
        varnish::monitoring::varnishreqstats { 'TextFrontend':
            instance_name => 'frontend',
            metric_path   => "varnish.${::site}.text.frontend.request",
        }
    }
}
