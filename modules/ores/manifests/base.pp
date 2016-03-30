class ores::base(
    $branch = 'deploy',
    $config_path = '/srv/ores/deploy',
    $venv_path = '/srv/ores/venv',
    $public_key_path = 'puppet:///private/ssh/tin/servicedeploy_rsa.pub',
) {
    # Let's use a virtualenv for maximum flexibility - we can convert
    # this to deb packages in the future if needed. We also install build tools
    # because they are needed by pip to install scikit.
    # FIXME: Use debian packages for all the packages needing compilation
    require_package('virtualenv', 'python3-dev', 'build-essential',
                    'gfortran', 'libopenblas-dev', 'liblapack-dev')

    # Install scipy via debian package so we don't need to build it via pip
    # takes forever and is quite buggy
    require_package('python3-scipy')

    # It requires the enchant debian package
    require_package('enchant')

    # Spellcheck packages for supported languages
    require_package('aspell-ar', 'aspell-id', 'aspell-pl',
                    'hunspell-vi',
                    'myspell-de-at', 'myspell-de-ch', 'myspell-de-de',
                    'myspell-en-au', 'myspell-en-gb', 'myspell-en-us',
                    'myspell-es',
                    'myspell-et',
                    'myspell-fa',
                    'myspell-fr',
                    'myspell-he',
                    'myspell-it',
                    'myspell-nl',
                    'myspell-pt',
                    'myspell-uk')

    # Deployment configurations
    include scap
    scap::target { 'ores/deploy':
        deploy_user       => 'deploy-service',
        public_key_source => $public_key_path,
        sudo_rules        => [
            'ALL=(root) NOPASSWD: /usr/sbin/service uwsgi-ores-web *',
            'ALL=(root) NOPASSWD: /usr/sbin/service celery-ores-worker *',
        ],
    }

    file { '/srv/ores/deploy-cache':
        ensure  => directory,
        owner   => 'deploy-service',
        group   => 'deploy-service',
        mode    => '0775',
        recurse => true,
    }

    file { '/srv/ores':
        ensure  => directory,
        owner   => 'deploy-service',
        group   => 'deploy-service',
        mode    => '0775',
        recurse => true,
    }


    file { '/srv/deployment/ores':
        ensure  => directory,
        owner   => 'deploy-service',
        group   => 'deploy-service',
        mode    => '0775',
        recurse => true,
    }

}
