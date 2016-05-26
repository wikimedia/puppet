class contint::browsers {

    package { [
        # Without xfonts-cyrillic Xvdb emits warning:
        # "[dix] Could not init font path element /usr/share/fonts/X11/cyrillic"
        'xfonts-cyrillic',
    ]:
        ensure => present,
    }

    if $::operatingsystem == 'Debian' {
        $latest_packages = [
            'chromium',
            'chromedriver',
            'iceweasel',  # rebranded firefox
            # phantomjs is not available on Jessie
        ]
    } elsif os_version('ubuntu >= trusty') {
        $latest_packages = [
            'chromium-browser',
            'chromium-chromedriver',
            'firefox',
            'phantomjs',
        ]
        # Chromium on hold T136188
        apt::pin { 'chromium-browser':
            pin      => 'version 49.0.2623.108-0ubuntu0.14.04.1.1113',
            priority => '1001',
            before   => Package['chromium-browser'],
        }
        apt::pin { 'chromium-chromedriver':
            pin      => 'version 49.0.2623.108-0ubuntu0.14.04.1.1113',
            priority => '1001',
            before   => Package['chromium-browser'],
        }
    } else {
        $latest_packages = [
            'chromium-browser',
            'firefox',
            'phantomjs',
        ]
    }

    package { $latest_packages:
        ensure => latest,
    }


    class { 'xvfb':
        display    => 94,
        resolution => '1280x1024x24',
    }
}
