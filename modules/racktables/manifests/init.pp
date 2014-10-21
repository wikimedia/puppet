# https://racktables.wikimedia.org
## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables
class racktables (
    $racktables_db_host = 'db1001.eqiad.wmnet',
    $racktables_db      = 'racktables',
) {

    include mysql
    include standard-noexim
    include passwords::racktables
    include webserver::php5-gd
    include webserver::php5-mysql
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    file { '/srv/org/wikimedia/racktables/wwwroot/inc/secret.php':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('racktables/racktables.config.erb'),
    }


    if ! defined(Class['webserver::php5']) {
        class {'webserver::php5': ssl => true; }
    }

    apache::site { 'racktables.wikimedia.org':
        content => template('racktables/apache/racktables.wikimedia.org.erb'),
    }

    apache::conf { 'namevirtualhost':
        source => 'puppet:///files/apache/conf.d/namevirtualhost',
    }


}

