class mediawiki::maintenance::readinglists( $ensure = present ) {
    require ::mediawiki::users

    cron { 'readinglists_purge':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 42,
        hour    => 2,
        command => 'PHP=php7.2 /usr/local/bin/mwscript extensions/ReadingLists/maintenance/purge.php --wiki=metawiki > /var/log/mediawiki/readinglists_purge.log',
    }
}
