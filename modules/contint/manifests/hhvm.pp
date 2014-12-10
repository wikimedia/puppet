class contint::hhvm {

    class { '::hhvm':
        packages_ensure  => 'latest',

        common_settings => {
            hhvm => {
                log   => { use_syslog => false },
                debug => { core_dump_report => false },
            },
        },

        cli_settings => {
            hhvm => {
                repo => {
                    central => {
                        # Empty to have hhvm fallback to the env variable
                        # HHVM_REPO_CENTRAL_PATH set in Jenkins
                        path => '',
                    },
                    local => {
                        mode => 'rw',
                        # Empty to have hhvm fallback to the env variable
                        # HHVM_REPO_LOCAL_PATH set in Jenkins
                        path => '',
                    },
                    eval    => { mode => 'local' },
                    journal => 'memory',
                },
            },
        },

        # We will want to bypass the Repo since code keep changing?
        fcgi_settings => { },
    }

    alternatives::select { 'php':
        path    => '/usr/bin/hhvm',
        require => Package['hhvm'],
    }

}
