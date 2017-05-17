# role/dns.pp

class role::dnsrecursor {
    system::role { 'dnsrecursor': description => 'Recursive DNS server' }

    include ::standard
    include ::lvs::configuration
    include ::network::constants
    include ::base::firewall

    class {
        '::lvs::realserver':
            realserver_ips   => $lvs::configuration::service_ips['dns_rec'][$::site];
        '::dnsrecursor':
            require          => Class['::lvs::realserver'],
            listen_addresses => [
                $facts['ipaddress'],
                $facts['ipaddress6'],
                $lvs::configuration::service_ips['dns_rec'][$::site],
            ],
            allow_from       => $network::constants::all_networks;
    }

    ::dnsrecursor::monitor { [ $facts['ipaddress'], $facts['ipaddress6'] ]: }

    ferm::service { 'udp_dns_rec':
        proto => 'udp',
        port  => '53',
    }

    ferm::service { 'tcp_dns_rec':
        proto => 'tcp',
        port  => '53',
    }

    ferm::rule { 'skip_dns_conntrack-out':
        desc  => 'Skip DNS outgoing connection tracking',
        table => 'raw',
        chain => 'OUTPUT',
        rule  => 'proto udp sport 53 NOTRACK;',
    }

    ferm::rule { 'skip_dns_conntrack-in':
        desc  => 'Skip DNS incoming connection tracking',
        table => 'raw',
        chain => 'PREROUTING',
        rule  => 'proto udp dport 53 NOTRACK;',
    }
}
