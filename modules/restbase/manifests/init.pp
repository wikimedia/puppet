# == Class: restbase
#
# restbase is a REST API & storage service
# http://restbase.org
#
# === Parameters
#
# [*cassandra_user*]
#   Cassandra user name.
#
# [*cassandra_password*]
#   Cassandra password.
#
# [*seeds*]
#   Array of cassandra hosts (IP or host names) to contact.
#   Default: ['localhost']
#
# [*cassandra_local_dc*]
#   Which DC should be considered local. Default: 'datacenter1'.
#
# [*cassandra_datacenters*]
#   The full list of member datacenters.
#
# [*cassandra_tls*]
#   An associative array of TLS options for the Cassandra driver.
#   See: https://nodejs.org/api/tls.html#tls_tls_createsecurecontext_options
#
# [*port*]
#   Port where to run the restbase service. Default: 7231
#
# [*parsoid_uri*]
#   URI to reach Parsoid. Default: http://parsoid.svc.eqiad.wmnet:8000
#
# [*logging_name*]
#   The logging name. Default: restbase
#
# [*statsd_prefix*]
#   statsd metric prefix. Default: restbase
#
# [*graphoid_uri*]
#   graphoid host + port. Default: http://graphoid.svc.eqiad.wmnet:19000
#
# [*mobileapps_uri*]
#   MobileApps service URI. Default: http://mobileapps.svc.eqiad.wmnet:8888
#
# [*mathoid_uri*]
#   Mathoid service URI. Default: http://mathoid.svc.eqiad.wmnet:10042
#
# [*aqs_uri*]
#   Analytics Query Service URI. Default:
#   http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1
#
# [*eventlogging_service_uri*]
#   Eventlogging service URI. Default: http://eventbus.svc.eqiad.wmnet:8085/v1/events
#
# [*pdfrender_uri*]
#   PDF Render service URI. Default: http://pdfrender.svc.eqiad.wmnet:5252
#
# [*citoid_uri*]
#   Citoid service URI. Default: http://citoid.svc.eqiad.wmnet:1970
#
# [*trendingedits_uri*]
#   Trending edits service URI. Default:
#   http://trendingedits.svc.eqiad.wmnet:6699
#
# [*cxserver_uri*]
#   CXServer service uri. Default: http://cxserver.discovery.wmnet:8080
#
# [*monitor_domain*]
#   The domain to monitor during the service's operation.
#   Default: en.wikipedia.org
#
# [*hosts*]
#   The list of RESTBase hosts used for setting up the rate-limiting DHT.
#   Default: [$::ipaddress]
#
class restbase(
    $cassandra_user = 'cassandra',
    $cassandra_password = 'cassandra',
    $seeds          = [$::ipaddress],
    $cassandra_local_dc = 'datacenter1',
    $cassandra_datacenters = [ 'datacenter1' ],
    $cassandra_tls  = {},
    $port           = 7231,
    $salt_key       = 'secretkey',
    $page_size      = 250,
    $parsoid_uri    = 'http://parsoid.svc.eqiad.wmnet:8000',
    $logging_name   = 'restbase',
    $statsd_prefix  = 'restbase',
    $graphoid_uri   = 'http://graphoid.svc.eqiad.wmnet:19000',
    $mobileapps_uri = 'http://mobileapps.svc.eqiad.wmnet:8888',
    $mathoid_uri    = 'http://mathoid.svc.eqiad.wmnet:10042',
    $aqs_uri        =
    'http://aqs.svc.eqiad.wmnet:7232/analytics.wikimedia.org/v1',
    $eventlogging_service_uri =
    'http://eventbus.svc.eqiad.wmnet:8085/v1/events',
    $pdfrender_uri  = 'http://pdfrender.svc.eqiad.wmnet:5252',
    $citoid_uri     = 'http://citoid.svc.eqiad.wmnet:1970',
    $trendingedits_uri = 'http://trendingedits.svc.eqiad.wmnet:6699',
    $cxserver_uri   = 'http://cxserver.discovery.wmnet:8080',
    $monitor_domain = 'en.wikipedia.org',
    $hosts          = [$::ipaddress],
) {

    require ::service::configuration
    $pdfrender_key = $::service::configuration::pdfrender_key
    $local_logfile = "${service::configuration::log_dir}/${title}/main.log"

    service::node { 'restbase':
        port              => $port,
        no_file           => 200000,
        healthcheck_url   => "/${monitor_domain}/v1",
        has_spec          => true,
        starter_script    => 'restbase/server.js',
        auto_refresh      => false,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            ipaddress                => $::ipaddress,
            rl_seeds                 => reject(reject($hosts, $::hostname), $::ipaddress),
            seeds                    => $seeds,
            cassandra_local_dc       => $cassandra_local_dc,
            cassandra_datacenters    => $cassandra_datacenters,
            cassandra_user           => $cassandra_user,
            cassandra_password       => $cassandra_password,
            cassandra_tls            => $cassandra_tls,
            parsoid_uri              => $parsoid_uri,
            graphoid_uri             => $graphoid_uri,
            mathoid_uri              => $mathoid_uri,
            mobileapps_uri           => $mobileapps_uri,
            citoid_uri               => $citoid_uri,
            eventlogging_service_uri => $eventlogging_service_uri,
            pdfrender_uri            => $pdfrender_uri,
            pdfrender_key            => $pdfrender_key,
            trendingedits_uri        => $trendingedits_uri,
            cxserver_uri             => $cxserver_uri,
            aqs_uri                  => $aqs_uri,
            salt_key                 => $salt_key,
            page_size                => $page_size,
        },
        logging_name      => $logging_name,
        statsd_prefix     => $statsd_prefix,
    }

}
