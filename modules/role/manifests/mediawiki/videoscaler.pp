# filtertags: labs-project-deployment-prep
class role::mediawiki::videoscaler {
    system::role { 'role::mediawiki::videoscaler': }

    # Parent role
    include ::role::mediawiki::scaler

    $hhvm_threads = floor(0.7 * $facts['processorcount'])
    $prioritized_runners = floor(0.4 * $hhvm_threads)
    $runners = $hhvm_threads - $prioritized_runners
    # Profiles
    include ::role::prometheus::apache_exporter
    include ::role::prometheus::hhvm_exporter
    include ::profile::mediawiki::jobrunner
    include ::base::firewall

    # Change the apache2.conf Timeout setting
    augeas { 'apache timeout':
        incl    => '/etc/apache2/apache2.conf',
        lens    => 'Httpd.lns',
        changes => [
            'set /files/etc/apache2/apache2.conf/directive[self::directive="Timeout"]/arg 86400',
        ],
        notify  => Service['apache2'],
    }
}
