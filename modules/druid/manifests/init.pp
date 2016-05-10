# == Class druid
#
# Installs druid-common and configures common runtime properties.
#
# == Properties
# Note that the properties listed here are only the defaults.
# See http://druid.io/docs/latest/configuration/ for a
# list of available properties.
#
#
# [*druid.extensions.directory*]
#   Druid extensions are installed here.  Only extensions listed in
#   druid.extensions.loadList will be automatically loaded into the classpath.
#   Default: /usr/share/druid/extensions
#
# [*druid.extensions.loadList*]
#   List extensions to load.  Directories matching these names must exist
#   in druid.extensions.directory.
#   Default: ["druid-histogram", "druid-datasketches", "druid-namespace-lookup"]
#
# [*druid.extensions.hadoopDependenciesDir*]
#   If you have a different version of Hadoop, place your Hadoop client jar
#   files in your hadoop-dependencies directory and uncomment the line below to
#   point to your directory.  Or you may manually include them in
#   DRUID_CLASSPATH.
#   Default: /usr/share/druid/hadoop-dependencies
#
# [*druid.startup.logging.logProperties*]
#   Log all runtime properties on startup. Disable to avoid logging properties
#   on startup. Default: true
#
# [*druid.zk.service.host*]
#   Zookeeper hostnames. Default: localhost:2181
#
# [*druid.zk.paths.base*]
#   Chroot to druid in zookeeper. Default: /druid
#
# [*druid.metadata.storage.type*]
#   For Derby server on your Druid Coordinator (only viable in a cluster with
#   single Coordinator, no fail-over).  Default: derby
#
# [*druid.metadata.storage.connector.connectURI*]
#   Default: jdbc:derby://localhost:1527/var/lib/druid/metadata.db;create=true
#
# [*druid.metadata.storage.connector.host*]
#   Default: localhost
#
# [*druid.metadata.storage.connector.port*]
#   Default: 1527
#
# [*druid.storage.type*]
#   Default: noop
#
# [*druid.indexer.logs.type*]
#   This property must be set for both overlord and middlemanager, hence
#   it is present in common.runtime.properties.
#   Default: file
#
# [*druid.indexer.logs.directory*]
#   This property must be set for both overlord and middlemanager, hence
#   it is present in common.runtime.properties.
#   Default: /var/lib/druid/indexing-logs
#
# [*druid.monitoring.monitors*]
#   Default: ["com.metamx.metrics.JvmMonitor"]
#
# [*druid.emitter*]
#   Default: logging
#
# [*druid.emitter.logging.logLevel*]
#   Default: info
#
class druid(
    $properties = {},
)
{
    $default_properties = {
        'druid.extensions.directory'                        => '/usr/share/druid/extensions',
        'druid.extensions.loadList'                         => [
            'druid-histogram',
            'druid-datasketches',
            'druid-namespace-lookup'
        ],
        'druid.extensions.hadoopDependenciesDir'            => '/usr/share/druid/hadoop-dependencies',
        'druid.startup.logging.logProperties'               => true,
        'druid.zk.service.host'                             => 'localhost:2181',
        'druid.zk.paths.base'                               => '/druid',
        'druid.metadata.storage.type'                       => 'derby',
        'druid.metadata.storage.connector.connectURI'       => 'jdbc:derby://localhost:1527/var/lib/druid/metadata.db;create=true',
        'druid.metadata.storage.connector.host'             => 'localhost',
        'druid.metadata.storage.connector.port'             => 1527,
        'druid.storage.type'                                => 'noop',
        'druid.monitoring.monitors'                         => ['com.metamx.metrics.JvmMonitor'],
        'druid.emitter'                                     => 'logging',
        'druid.emitter.logging.logLevel'                    => 'info'
    }
    $runtime_properties = merge($default_properties, $properties)

    require_package('druid-common')

    file { '/etc/druid/common.runtime.properties':
        content => template('druid/runtime.properties.erb')
    }
}

# # TODO: This won't work from manifests/service.pp on mediawiki vagrant, hmmm.
# # == Define druid::service
# # == Parameters
# # arguments
# #
# define druid::service(
#     $runtime_properties,
#     $service = $title,
#     $env     = undef,
#     $enable  = true,
# )
# {
#     file { "/etc/druid/${service}/runtime.properties":
#         content => template('druid/runtime.properties.erb'),
#     }
#
#     $env_ensure = $env ? {
#         undef   => 'absent',
#         default => 'present',
#     }
#
#     file { "/etc/druid/${service}/env.sh":
#         ensure => $env_ensure,
#         content => template('druid/env.sh.erb'),
#     }
#
#     file { "/etc/druid/${service}/log4j2.xml":
#         content => template('druid/log4j2.xml.erb'),
#     }
#
#     $service_ensure = $enabled ? {
#         false   => 'stopped',
#         default => 'running',
#     }
#     service { "druid-${service}":
#         ensure      => $service_ensure,
#         enable      => $enabled,
#         hasrestart  => true,
#         require     => [
#             File["/etc/druid/${service}/runtime.properties"],
#             File["/etc/druid/${service}/env.sh"],
#             File["/etc/druid/${service}/log4j2.xml"],
#         ]
#     }
# }