# == Define: trafficserver::instance
#
# This module provisions Apache Traffic Server -- a fast, scalable caching
# proxy.
#
# === Logging
#
# ATS event logs can be written to ASCII files, binary files, or named pipes.
# Event logs are described here:
# https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/understanding.en.html#event-logs
#
# === Parameters
#
# [*paths*]
#   Mapping of trafficserver paths. See Trafficserver::Paths and trafficserver::get_paths()
#
# [*default_instance*]
#  Setup ATS default instance. (default: false)
#  Setting this value to true must be only done in one ATS instance per server. This will trigger the usage of
#  the main trafficserver instance, instead of one sandboxed using traffic_layout. More information about
#  traffic_layout can be found in https://wikitech.wikimedia.org/wiki/Apache_Traffic_Server#Additional_ATS_instances
#  and https://docs.trafficserver.apache.org/en/8.0.x/appendices/command-line/traffic_layout.en.html
#
# [*port*]
#   Bind trafficserver to this port (default: 8080).
#
# [*inbound_socket_options*]
#   Socket options for incoming connections. The provided value is a bitmask:
#     TCP_NODELAY  = 0x1
#     SO_KEEPALIVE = 0x2
#     SO_LINGER    = 0x4
#     TCP_FASTOPEN = 0x8
#   Default value: TCP_NODELAY | SO_LINGER = 0x5
#
# [*origin_ttfb_timeout*]
#   The timeout value (in seconds) for time to first byte for an origin server connection. (default: 30 secs)
#
# [*origin_post_ttfb_timeout*]
#   The timeout value (in seconds) for time to first byte for an origin server connection when the client request
#   is a POST or PUT request. (default: 1800 secs)
#
# [*inbound_tls_settings*]
#   Inbound TLS settings. (default: undef).
#   for example:
#   {
#       common => {
#           cipher_suite   => '-ALL:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384',
#           enable_tlsv1   => 0,
#           enable_tlsv1_1 => 0,
#           enable_tlsv1_2 => 1,
#           enable_tlsv1_3 => 1,
#       },
#       cert_path         => '/etc/ssl/localcerts',
#       cert_files        => ['globalsign-2018-ecdsa-unified.chained.crt','globalsign-2018-rsa-unified.chained.crt'],
#       private_key_path  => '/etc/ssl/private',
#       private_key_files => ['globalsign-2018-ecdsa-unified.key','globalsign-2018-rsa-unified.key'],
#       dhparams_file     => '/etc/ssl/dhparam.pem',
#       max_record_size   => 16383,
#   }
#
# [*outbound_tls_settings*]
#   Outbound TLS settings. (default: undef).
#   for example:
#   {
#       common => {
#           cipher_suite   => '-ALL:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384',
#           enable_tlsv1   => 0,
#           enable_tlsv1_1 => 0,
#           enable_tlsv1_2 => 1,
#           enable_tlsv1_3 => 1,
#       },
#       verify_origin   => true,
#       cacert_dirname  => '/etc/ssl/certs',
#       cacert_filename => 'Puppet_Internal_CA.pem',
#   }
# check the type definitions for more detailed information
#
# [*enable_xdebug*]
#   Enable the XDebug plugin. (default: false)
#   https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/xdebug.en.html
#
# [*enable_compress*]
#   Enable the compress plugin. (default: false)
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/compress.en.html
#
# [*collapsed_forwarding*]
#   Enable the Collapsed Forwarding plugin. (default: false)
#   https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/collapsed_forwarding.en.html
#
# [*global_lua_script*]
#   The name of the global Lua script to define in plugin.config. (default: '').
#
# [*mapping_rules*]
#   An array of Trafficserver::Mapping_rules, each representing a mapping rule. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/remap.config.en.html
#
# [*enable_caching*]
#   Enable caching of HTTP requests. (default: true)
#
# [*required_headers*]
#   The type of headers required in a request for the request to be cacheable.
#   (default: 2)
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html
#
# [*caching_rules*]
#   An array of Trafficserver::Caching_rules, each representing a caching rule. (default: undef).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/cache.config.en.html
#
# [*negative_caching*]
#   Settings controlling whether or not Negative Response Caching should be
#   enabled, for which status codes, and the lifetime to apply to objects
#   without explicit Cache-Control or Expires. (default: undef).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html#negative-response-caching
#
# [*storage*]
#   An array of Trafficserver::Storage_elements. (default: undef).
#
#   Partitions can be specified by setting the 'devname' key, while files or
#   directories use 'pathname'. For example:
#
#     { 'devname'  => 'sda3' }
#     { 'pathname' => '/srv/storage/', 'size' => '10G' }
#
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/storage.config.en.html
#
# [*ram_cache_size*]
#   The amount of memory in bytes to reserve for RAM cache. Traffic Server
#   automatically determines the RAM cache size if this value is not specified
#   or set to -1. (default: -1)
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html
#
# [*log_formats*]
#   An array of Trafficserver::Log_formats. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*log_filters*]
#   An array of Trafficserver::Log_filters. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*logs*]
#   An array of Trafficserver::Logs. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*parent_rules*]
#   An optional array of Trafficserver::Parent_Rule.
#   See https://docs.trafficserver.apache.org/en/8.0.x/admin-guide/files/parent.config.en.html and
#   the type definition (modules/trafficserver/types/parent_rule.pp) cause only a partial implementation
#   of parent rules is provided.
#
# [*error_page*]
#   A string containing the error page to deliver to clients when there are
#   problems with the HTTP transactions. (default: '<html><head><title>Error</title></head><body><p>Something went wrong</p></body></html>').
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/monitoring/error-messages.en.html#body-factory
#
# [*x_forwarded_for*]
#   When enabled (1), Traffic Server adds the client IP address to the X-Forwarded-For header. (default: 0).
#
# [*systemd_hardening*]
#   Whether or not to enable systemd unit security features. (default: true).
# === Examples
#
#  trafficserver::instance { 'backend':
#    user          => 'trafficserver',
#    port          => 80,
#    log_mode      => 'ascii',
#    log_format    => 'squid',
#    log_filename  => 'access',
#    mapping_rules => [ { 'type'        => 'map',
#                         'target'      => 'http://grafana.wikimedia.org/',
#                         'replacement' => 'http://krypton.eqiad.wmnet/', },
#                       { 'type'        => 'map',
#                         'target'      => '/',
#                         'replacement' => 'http://deployment-mediawiki05.deployment-prep.eqiad.wmflabs/' }, ],
#    caching_rules => [ { 'primary_destination' => 'dest_domain',
#                         'value'               => 'grafana.wikimedia.org',
#                         'action'              => 'never-cache' }, ],
#    storage       => [ { 'pathname' => '/srv/storage/', 'size' => '10G' },
#                       { 'devname'  => 'sda3', 'volume' => 1 },
#                       { 'devname'  => 'sdb3', 'volume' => 2, 'id' => 'cache.disk.1' }, ],
#  }
#
define trafficserver::instance(
    Trafficserver::Paths $paths,
    Boolean $default_instance = false,
    Stdlib::Port $port = 8080,
    Integer[0, 0xF] $inbound_socket_options = 0x5,
    Integer[0] $origin_ttfb_timeout = 30,
    Integer[0] $origin_post_ttfb_timeout = 1800,
    Optional[Trafficserver::Inbound_TLS_settings] $inbound_tls_settings = undef,
    Optional[Trafficserver::Outbound_TLS_settings] $outbound_tls_settings = undef,
    Boolean $enable_xdebug = false,
    Boolean $enable_compress = false,
    Boolean $collapsed_forwarding = false,
    String $global_lua_script = '',
    Array[Trafficserver::Mapping_rule] $mapping_rules = [],
    Boolean $enable_caching = true,
    Optional[Integer[0,2]] $required_headers = undef,
    Optional[Array[Trafficserver::Caching_rule]] $caching_rules = undef,
    Optional[Trafficserver::Negative_Caching] $negative_caching = undef,
    Optional[Array[Trafficserver::Storage_element]] $storage = undef,
    Optional[Integer] $ram_cache_size = -1,
    Array[Trafficserver::Log_format] $log_formats = [],
    Array[Trafficserver::Log_filter] $log_filters = [],
    Array[Trafficserver::Log] $logs = [],
    Optional[Array[Trafficserver::Parent_rule]] $parent_rules = undef,
    String $error_page = '<html><head><title>Error</title></head><body><p>Something went wrong</p></body></html>',
    Integer[0,1] $x_forwarded_for = 0,
    Boolean $systemd_hardening = true,
) {

    require ::trafficserver
    $user = $trafficserver::user  # needed by udev_storage.rules.erb and records.config.erb

    if $inbound_socket_options >= 0x8 { # TCP_FASTOPEN is enabled
        if !defined(Sysctl::Parameters['TCP Fast Open']) {  # TODO: Get rid of this as soon as nginx
                                                            # is not deployed in the cache cluster
            sysctl::parameters { 'TCP Fast Open':
                values => {
                    'net.ipv4.tcp_fastopen' => 3,
                },
            }
        }
    }

    if !$default_instance {
        trafficserver::layout { $title:
            paths => $paths,
        }
        $config_requires = Trafficserver::Layout[$title]
        $service_name = "trafficserver-${title}"
        $service_override = false
    } else {
        $config_requires = Package['trafficserver']
        $service_name = 'trafficserver'
        $service_override = true
    }

    # Change the ownership of all raw devices so that the trafficserver user
    # has read/write access to them
    if $enable_caching and $storage {
      $storage.each |Trafficserver::Storage_element $element| {
          if has_key($element, 'devname') {
              udev::rule { $element['devname']:
                  content => template('trafficserver/udev_storage.rules.erb'),
              }
          }
      }
    }

    $error_template_path = "${paths['sysconfdir']}/error_template"
    file {
      [$error_template_path, "${error_template_path}/default"]:
        ensure  => directory,
        owner   => $trafficserver::user,
        mode    => '0755',
        require => $config_requires,
    }

    # needed by plugin.config.erb
    $healthchecks_config_path = "${paths['sysconfdir']}/healthchecks.config"
    $compress_config_path = "${paths['sysconfdir']}/compress.config"

    ## Config files
    file {
        default:
          * => {
              owner   => $trafficserver::user,
              mode    => '0400',
              require => $config_requires,
              notify  => Service[$service_name],
          };

        $paths['records']:
          content => template('trafficserver/records.config.erb'),;

        "${paths['sysconfdir']}/remap.config":
          content => template('trafficserver/remap.config.erb'),;

        "${paths['sysconfdir']}/cache.config":
          content => template('trafficserver/cache.config.erb'),;

        "${paths['sysconfdir']}/ip_allow.config":
          content => template('trafficserver/ip_allow.config.erb'),;

        "${paths['sysconfdir']}/storage.config":
          content => template('trafficserver/storage.config.erb'),;

        "${paths['sysconfdir']}/plugin.config":
          content => template('trafficserver/plugin.config.erb'),;

        $paths['ssl_multicert']:
          content => template('trafficserver/ssl_multicert.config.erb'),;

        "${paths['sysconfdir']}/parent.config":
          content => template('trafficserver/parent.config.erb'),;

        "${paths['sysconfdir']}/logging.yaml":
          content => template('trafficserver/logging.yaml.erb');

        $healthchecks_config_path:
          # Response body can be changed by pointing to a text file with actual
          # contents instead of /dev/null
          content => '/check /dev/null text/plain 200 403',;

        "${error_template_path}/default/.body_factory_info":
          # This file just needs to be there or ATS will refuse loading any
          # template
          content => '',
          require => File[$error_template_path];

        "${error_template_path}/default/default":
          content => $error_page,
          require => File[$error_template_path];
    }

    if $enable_compress {
        file { $compress_config_path:
            owner   => $trafficserver::user,
            mode    => '0400',
            require => $config_requires,
            notify  => Service[$service_name],
            content => template('trafficserver/compress.config.erb'),
        }
    }

    ## Service
    $do_ocsp = !empty($inbound_tls_settings) and num2bool($inbound_tls_settings['do_ocsp']) # used in the systemd template
    if $do_ocsp {
      $acme_chief = defined(Acme_chief::Cert['unified'])  # if acme_chief unified cert is there, update-ocsp may try to
                                                          # write on /etc/acmecerts and we need to allow it
                                                          # this can be triggered by tlsproxy::localssl configuration
                                                          # and we can get rid of this as soon as we don't need
                                                          # ats-tls and nginx living on the same instance
    } else {
      $acme_chief = false
    }

    systemd::service { $service_name:
        content        => init_template('trafficserver', 'systemd_override'),
        override       => $service_override,
        restart        => true,
        service_params => {
            restart    => "systemctl reload ${service_name}",
        },
        subscribe      => Package[$trafficserver::packages],
    }
}
