class role::cache::ssl::unified {
    include role::protoproxy::ssl::common

    role::cache::ssl::local { 'unified':
        certname => 'uni.wikimedia.org',
        default_server => true,
        do_ocsp => true,
    }

    monitoring::service { 'https':
        description   => 'HTTPS',
        check_command => 'check_sslxNN',
    }

    # ordering ensures nginx/varnish config/service-start are
    #  not intermingled during initial install where they could
    #  have temporary conflicts on binding port 80
    Service['nginx'] -> Service<| tag == 'varnish_instance' |>
}
