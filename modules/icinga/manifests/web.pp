# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web {
    include icinga

    # Apparently required for the web interface
    package { 'icinga-doc':
        ensure => present
    }
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::headers
    include ::apache::mod::cgi
    # Disable access_compat module on Debian >= Jessie
    if os_version('debian >= jessie') {
        apache::mod_conf { 'access_compat': ensure => absent }
    }

    ferm::service { 'icinga-https':
      proto => 'tcp',
      port  => 443,
    }
    ferm::service { 'icinga-http':
      proto => 'tcp',
      port  => 80,
    }

    require_package('php5-gd')

    include passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0644',
    }

    # install the Icinga Apache site
    include ::apache::mod::rewrite
    include ::apache::mod::authnz_ldap

    apache::site { 'icinga.wikimedia.org':
        content => template('icinga/icinga.wikimedia.org.erb'),
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }

}
