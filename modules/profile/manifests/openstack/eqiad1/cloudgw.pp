class profile::openstack::eqiad1::cloudgw (
    Array[Stdlib::IP::Address::V4::Nosubnet] $dmz_cidr = lookup('profile::openstack::eqiad1::cloudgw::dmz_cidr',    {default_value => ['0.0.0.0']}),
    Stdlib::IP::Address           $routing_source = lookup('profile::openstack::eqiad1::cloudgw::routing_source_ip',{default_value => '185.15.57.1'}),
    Stdlib::IP::Address::V4::CIDR $virt_subnet    = lookup('profile::openstack::eqiad1::cloudgw::virt_subnet_cidr', {default_value => '172.16.128.0/24'}),
    Integer                       $virt_vlan      = lookup('profile::openstack::eqiad1::cloudgw::virt_vlan',        {default_value => 2107}),
    Stdlib::IP::Address           $virt_peer      = lookup('profile::openstack::eqiad1::cloudgw::virt_peer',        {default_value => '127.0.0.5'}),
    Stdlib::IP::Address::V4::CIDR $virt_floating  = lookup('profile::openstack::eqiad1::cloudgw::virt_floating',    {default_value => '127.0.0.5/24'}),
    Integer                       $wan_vlan       = lookup('profile::openstack::eqiad1::cloudgw::wan_vlan',         {default_value => 2120}),
    Stdlib::IP::Address           $wan_addr       = lookup('profile::openstack::eqiad1::cloudgw::wan_addr',         {default_value => '127.0.0.4'}),
    Integer                       $wan_netm       = lookup('profile::openstack::eqiad1::cloudgw::wan_netm',         {default_value => 8}),
    Stdlib::IP::Address           $wan_gw         = lookup('profile::openstack::eqiad1::cloudgw::wan_gw',           {default_value => '127.0.0.1'}),
    String                        $nic_sshplane   = lookup('profile::openstack::eqiad1::cloudgw::nic_controlplane', {default_value => 'eno1'}),
    String                        $nic_dataplane  = lookup('profile::openstack::eqiad1::cloudgw::nic_dataplane',    {default_value => 'eno2'}),
    Array[String]                 $vrrp_vips      = lookup('profile::openstack::eqiad1::cloudgw::vrrp_vips',        {default_value => ['127.0.0.1 dev eno2']}),
    Stdlib::IP::Address           $vrrp_peer      = lookup('profile::openstack::eqiad1::cloudgw::vrrp_peer',        {default_value => '127.0.0.1'}),
    Hash                          $conntrackd     = lookup('profile::openstack::eqiad1::cloudgw::conntrackd',       {default_value => {}}),
) {
    class { '::profile::openstack::base::cloudgw':
        dmz_cidr       => $dmz_cidr,
        routing_source => $routing_source,
        virt_subnet    => $virt_subnet,
        virt_vlan      => $virt_vlan,
        virt_peer      => $virt_peer,
        virt_floating  => $virt_floating,
        virt_cidr      => $virt_subnet,
        wan_vlan       => $wan_vlan,
        wan_addr       => $wan_addr,
        wan_netm       => $wan_netm,
        wan_gw         => $wan_gw,
        nic_dataplane  => $nic_dataplane,
        vrrp_vips      => $vrrp_vips,
        vrrp_peer      => $vrrp_peer,
        conntrackd     => $conntrackd,
    }
    contain '::profile::openstack::base::cloudgw'
}
