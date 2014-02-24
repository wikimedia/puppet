class mediawiki::packages {

    package { 'wikimedia-task-appserver':
      ensure => latest,
    }

    # wikimedia-task-appserver depends on timidity, which recommends
    # timidity-daemon.
    package { 'timidity-daemon':
      ensure => absent,
    }

    package { [
        'apache2-mpm-prefork',
        'imagemagick',
        'libapache2-mod-php5',
        'libmemcached10',       # XXX still needed?
        'libmemcached11',
        'php-apc',
        'php-pear',
        'php5-cli',
        'php5-common',
    ]:
        ensure => present,
    }

    # Standard PHP extensions
    package { [
        'php5-curl',
        'php5-geoip',
        'php5-intl',
        'php5-memcached',
        'php5-mysql',
        'php5-redis',
        'php5-xmlrpc',
    ]:
        ensure => present,
    }

    # Wikimedia-specific PHP extensions
    package { [
        'php-luasandbox',
        'php-wikidiff2',
        'php5-wmerrors',
        'php5-fss',
    ]:
        ensure => present,
    }

    # Pear modules
    package { [
        'php-mail',
        'php-mail-mime',
    ]:
        ensure => present,
    }

    # Math
    package { [
        'dvipng',
        'gsfonts',
        'make',
        'ocaml',
        'ploticus',
    ]:
        ensure => present,
    }
    include mediawiki::packages::math


    # PDF and DjVu
    package { [
        'djvulibre-bin',
        'librsvg2-bin',
        'libtiff-tools',
        'poppler-utils',
    ]:
        ensure => present,
    }

    # Score
    package { 'lilypond':
        ensure => present,
    }

    # Tidy
    package { [
        'libtidy-0.99-0',
        'tidy',
    ]:
        ensure => present,
    }

    package { 'wikimedia-task-appserver':
        ensure => latest;
    }
}
