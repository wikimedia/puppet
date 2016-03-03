# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# - ensure: self explanatory
class elasticsearch::https (
    $ensure = 'absent',
){

    class { 'nginx::ssl':
        ensure   => $ensure,
    }

    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => $ensure,
        provide_private => true,
        ssldir          => '/var/lib/puppet/client/ssl',
    }

    ::nginx::site { 'elasticsearch-ssl-termination':
        ensure  => $ensure,
        content => template('elasticsearch/nginx/es-ssl-termination.nginx.conf.erb'),
    }

    ::ferm::service { 'elastic-https':
        proto  => 'tcp',
        port   => '9243',
        srange => '$INTERNAL',
    }

}
