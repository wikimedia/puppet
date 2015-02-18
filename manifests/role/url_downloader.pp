# Class: role::url_downloader
#
# A role class for assigning the url_downloader role to a host. The host needs
# to have the $url_downloader_ip variable set at node level (or via hiera)
#
# Parameters:
#
# Actions:
#       Use the url_downloader module class to configure a squid service
#       Setup firewall rules
#       Setup monitoring rules
#       Pin our packages
#
# Requires:
#       Module url_downloader
#       ferm
#       nagios definitions for wmf
#
# Sample Usage:
#       node /test.wikimedia.org/ {
#           include role::url_downloader
#       }
# And hiera updated with url_downloader_ip as needed
class role::url_downloader {
    system::role { 'url_downloader':
        description => 'Upload-by-URL proxy'
    }

    $url_downloader_ip = hiera('url_downloader_ip')
    $url_downloader_port = hiera('url_downloader_port', 8080)

    if os_version('ubuntu >= trusty') {
        $config_content = template('url_downloader/squid.conf.erb')
    } else {
        $config_content = template('url_downloader/precise_acls_conf.erb', 'url_downloader/squid.conf.erb')
    }

    class { 'squid3':
        config_content => $config_content,
    }

    # Firewall
    ferm::service { 'url_downloader':
        proto => 'tcp',
        port  => $url_downloader_port,
    }

    # Monitoring
    monitoring::service { 'url_downloader':
        description   => 'url_downloader',
        check_command => "check_tcp_ip!url-downloader.wikimedia.org!${url_downloader_port}",
    }
}
