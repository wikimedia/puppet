# == Class contint::packages::javascript
#
# Install npm/grunt-cli from npmjs.com with pinned versions
#
class contint::packages::javascript {

    requires_realm('labs')

    package { 'npm':
        ensure => present,
        notify => Exec['pin npm'],
    }

    # DO NOT CHANGE VERSIONS
    #
    # https://wikitech.wikimedia.org/wiki/Nova_Resource:Integration/Setup
    $versions = {
        'npm'       => '2.7.6',
        'grunt-cli' => '0.1.13',
    }

    $npm_options = $::lsbdistcodename ? {
        # npm is terribly outdated
        'precise' => '--ca=null',
        default   => '',
    }

    exec { 'pin npm':
        command => "/usr/bin/npm install ${npm_options} -g npm@${versions['npm']}",
        onlyif  => "/usr/bin/test \"`/usr/bin/npm --version`\" != \"${versions['npm']}\"",
        require => Package['npm'],
    }

    exec { 'pin grunt-cli':
        command => "/usr/bin/npm install -g grunt-cli@${versions['grunt-cli']}",
        onlyif  => "/usr/bin/test \"`/usr/bin/grunt --version`\" != \"grunt-cli v${versions['grunt-cli']}\"",
    }

}
