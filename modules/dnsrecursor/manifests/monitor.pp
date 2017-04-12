# icinga monitoring for DNS recursors
define dnsrecursor::monitor() {
    # Monitoring
    monitoring::host { $title:
        ip_address => $title,
        parent     => $::fqdn,
    }
    monitoring::service { "recursive dns ${title}":
        host          => $title,
        description   => 'Recursive DNS',
        check_command => 'check_dns!www.wikipedia.org',
    }
}
