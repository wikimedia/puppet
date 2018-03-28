class profile::openstack::base::neutron::l3_agent(
    $version = hiera('profile::openstack::base::version'),
    $network_flat_interface = hiera('profile::openstack::base::neutron::network_flat_interface'),
    $network_flat_tagged_base_interface = hiera('profile::openstack::base::neutron::network_flat_tagged_base_interface'),
    $network_flat_interface_vlan = hiera('profile::openstack::base::neutron::network_flat_interface_vlan'),
    $dmz_cidr = hiera('profile::openstack::base::neutron::dmz_cidr'),
    $network_public_ip = hiera('profile::openstack::base::neutron::network_public_ip'),
    ) {

    interface::tagged { $network_flat_interface:
        base_interface => $network_flat_tagged_base_interface,
        vlan_id        => $network_flat_interface_vlan,
        method         => 'manual',
        up             => 'ip link set $IFACE up',
        down           => 'ip link set $IFACE down',
    }

    class {'::openstack::neutron::l3_agent':
        version           => $version,
        dmz_cidr          => $dmz_cidr,
        network_public_ip => $network_public_ip,
    }
    contain '::openstack::neutron::l3_agent'
}
