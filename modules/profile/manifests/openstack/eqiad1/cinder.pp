class profile::openstack::eqiad1::cinder(
    String $version = lookup('profile::openstack::eqiad1::version'),
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::eqiad1::openstack_controllers'),
    Stdlib::Fqdn $keystone_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String $db_pass = lookup('profile::openstack::eqiad1::cinder::db_pass'),
    Stdlib::Fqdn $db_host = lookup('profile::openstack::eqiad1::cinder::db_host'),
    Stdlib::Port $api_bind_port = lookup('profile::openstack::eqiad1::cinder::api_bind_port'),
    String $ceph_pool = lookup('profile::openstack::eqiad1::cinder::ceph_pool'),
    String $rabbit_pass = lookup('profile::openstack::eqiad1::nova::rabbit_pass'),
    String $ldap_user_pass = lookup('profile::openstack::eqiad1::cinder::ldap_user_pass'),
    ) {

    class {'::profile::openstack::base::cinder':
        version               => $version,
        openstack_controllers => $openstack_controllers,
        keystone_fqdn         => $keystone_fqdn,
        db_pass               => $db_pass,
        db_host               => $db_host,
        api_bind_port         => $api_bind_port,
        ceph_pool             => $ceph_pool,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_pass           => $rabbit_pass,
        active                => true,
    }
}
