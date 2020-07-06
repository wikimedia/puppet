class profile::openstack::eqiad1::horizon::dashboard_source_deploy(
    String        $horizon_version = lookup('profile::openstack::eqiad1::horizon_version'),
    String        $openstack_version = lookup('profile::openstack::eqiad1::version'),
    Stdlib::Fqdn  $keystone_api_fqdn = lookup('profile::openstack::eqiad1::keystone_api_fqdn'),
    String        $wmflabsdotorg_admin = lookup('profile::openstack::eqiad1::designate::wmflabsdotorg_admin'),
    String        $wmflabsdotorg_pass = lookup('profile::openstack::eqiad1::designate::wmflabsdotorg_pass'),
    String        $dhcp_domain = lookup('profile::openstack::eqiad1::nova::dhcp_domain'),
    String        $instance_network_id = lookup('profile::openstack::eqiad1::horizon::instance_network_id'),
    String        $ldap_user_pass = lookup('profile::openstack::eqiad1::ldap_user_pass'),
    Stdlib::Fqdn  $webserver_hostname = lookup('profile::openstack::eqiad1::horizon::webserver_hostname'),
    Array[String] $all_regions = lookup('profile::openstack::eqiad1::all_regions'),
    String        $puppet_git_repo_name = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_name'),
    String        $puppet_git_repo_user = lookup('profile::openstack::eqiad1::horizon::puppet_git_repo_user'),
    Boolean       $maintenance_mode = lookup('profile::openstack::eqiad1::horizon::maintenance_mode'),
    String        $secret_key = lookup('profile::openstack::eqiad1::horizon::secret_key'),
    Hash          $proxy_zone_dict = lookup('profile::openstack::eqiad1::horizon::proxy_zone_dict'),
    Hash          $proxy_zone_passwords = lookup('profile::openstack::eqiad1::horizon::proxy_zone_passwords'),
    ) {

    require ::profile::openstack::eqiad1::clientpackages
    class {'::profile::openstack::base::horizon::dashboard_source_deploy':
        horizon_version      => $horizon_version,
        openstack_version    => $openstack_version,
        keystone_api_fqdn    => $keystone_api_fqdn,
        wmflabsdotorg_admin  => $wmflabsdotorg_admin,
        wmflabsdotorg_pass   => $wmflabsdotorg_pass,
        dhcp_domain          => $dhcp_domain,
        instance_network_id  => $instance_network_id,
        ldap_user_pass       => $ldap_user_pass,
        webserver_hostname   => $webserver_hostname,
        all_regions          => $all_regions,
        puppet_git_repo_name => $puppet_git_repo_name,
        puppet_git_repo_user => $puppet_git_repo_user,
        maintenance_mode     => $maintenance_mode,
        secret_key           => $secret_key,
        proxy_zone_dict      => $proxy_zone_dict,
        proxy_zone_passwords => $proxy_zone_passwords,
    }
}
