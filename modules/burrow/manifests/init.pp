# == Define: burrow
#
# Burrow is a consumer offset lag monitoring tool for Kafka
# This module helps set up a burrow service that provides a
# http endpoint to query, and will email notifications on
# consumer groups statuses.
# This module supports only Burrow >= 1.0, since older versions are based
# on completely different configurations.
#
# == Parameters
#
# [*client_id*]
#   The client ID string to provide to Kafka when consuming
#
# [*httpserver_port*]
#   Port at which to make the burrow http endpoint available
#
# [*lagcheck_intervals*]
#   Length of window of offsets used to monitor lag
#   See: https://github.com/linkedin/Burrow/wiki/Configuration#lagcheck
#
# [*zookeeper_hosts*]
#   Array of zookeeper host and their ports.
#
# [*zookeeper_path*]
#   The full path to the znode that is the root for the Kafka cluster.
#
# [*kafka_cluster_name*]
#   Name of the Kafka cluster to monitor.
#
# [*kafka_brokers*]
#   Array of kafka brokers in the Kafka cluster.
#
# [*kafka_api_version*]
#   Kafka api version to use with the cluster.
#   Current maximum supported one is 0.11.0
#   Default: '0.11.0'
#
# [*consumer_groups*]
#   Consumer groups to be monitored to get email notifications
#
# [*smtp_server*]
#   SMTP server to send emails from
#
# [*from_email*]
#   From email address for notification
#
# [*to_email*]
#   Email address to send email notification to
#
# [*email_template*]
#   The name of the email template to use for Burrow's alerts
#
# [*consumer_groups_blacklist*]
#   Regex used to filter out temporary/not-relevant consumer groups.
#   Default: '^(console-consumer-|python-kafka-consumer-|test_).*$'
#
define burrow (
    $zookeeper_hosts,
    $zookeeper_path,
    $kafka_cluster_name,
    $kafka_brokers,
    $consumer_groups,
    $smtp_server,
    $from_email,
    $to_email,
    $kafka_api_version='0.11.0',
    $client_id = 'burrow-client',
    $httpserver_port = 8000,
    $lagcheck_intervals = 10,
    $email_template = 'burrow/email.tmpl.erb',
    $consumer_groups_blacklist = '^(console-consumer-|python-kafka-consumer-|test_).*$',
)
{
    require_package('burrow')

    if !defined(File['/etc/burrow.d']) {
        file { '/etc/burrow.d':
            ensure  => 'directory',
        }
    }

    # Burrow 1.0 accepts one parameter named '--config-dir' that
    # expects a directory containing a file named 'burrow.toml'.
    # Since multiple instances of Burrow can run on the same hosts,
    # it is necessary to create the appropriate etc hierarchy.
    file { "/etc/burrow.d/${title}":
        ensure  => 'directory',
    }

    file { "/etc/burrow.d/${title}/burrow.toml":
        content => template('burrow/burrow.toml.erb'),
    }

    $email_template_path = "/etc/burrow.d/${title}/email.tmpl"
    file { $email_template_path:
        content => template($email_template),
    }

    systemd::service { "burrow-${title}":
        ensure    => present,
        content   => systemd_template('burrow'),
        restart   => true,
        subscribe => File["/etc/burrow.d/${title}/burrow.toml"],
        require   => Package['burrow'],
    }

    if ! defined(Service['burrow']) {
        service { 'burrow':
            ensure  => stopped,
            require => Package['burrow'],
        }
    }
}
