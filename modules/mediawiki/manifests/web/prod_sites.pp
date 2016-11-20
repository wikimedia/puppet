class mediawiki::web::prod_sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'redirects':
        source   => 'puppet:///mediawiki/apache/sites/redirects.conf',
        priority => 2,
    }

    apache::site { 'main':
        content  => template('mediawiki/apache/sites/main.conf.erb'),
        priority => 3,
    }

    apache::site { 'remnant':
        content  => template('mediawiki/apache/sites/remnant.conf.erb'),
        priority => 4,
    }

    apache::site { 'search.wikimedia':
        source   => 'puppet:///mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    apache::site { 'secure.wikimedia':
        source   => 'puppet:///mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    apache::site { 'wikimania':
        content  => template('mediawiki/apache/sites/wikimania.conf.erb'),
        priority => 7,
    }

    apache::site { 'wikimedia':
        content   => template('mediawiki/apache/sites/wikimedia.conf.erb'),
        priority => 8,
    }

    apache::site { 'foundation':
        source   => 'puppet:///mediawiki/apache/sites/foundation.conf',
        priority => 9,
    }
}
