# == Class: role::grafana2
#
# grafana2 is a dashboarding webapp for Graphite.
# It powers <https://grafana2-test.wikimedia.org>.
#
class role::grafana2 {
    include ::apache::mod::authnz_ldap
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
    include ::apache::mod::rewrite

    include ::passwords::grafana
    include ::passwords::ldap::production

    class { '::grafana2':
        config => {
            # Configuration settings for /etc/grafana/grafana.ini.
            # See <http://docs.grafana.org/installation/configuration/>.

            # Only listen on loopback, because we'll have a local Apache
            # instance acting as a reverse-proxy.
            'server'     => {
                http_addr => '127.0.0.1',
                domain    => 'grafana-test.wikimedia.org',
                protocol  => 'http',
            },

            # Grafana needs a database to store users and dashboards.
            # sqlite3 is the default, and it's perfectly adequate.
            'database'   => {
                type => 'sqlite3',
                path => 'grafana.db',
            },

            'security'   => {
                secret_key     => $passwords::grafana::secret_key,
                admin_password => $passwords::grafana::admin_password,
            },

            # Automatically create an account for users and authenticate
            # them based on the REMOTE_USER env var set by mod_authnz_ldap.
            'auth.proxy' => {
                enabled      => true,
                header_name  => 'REMOTE_USER',
                auto_sign_up => true,
            },

            # Because we enable `auth.proxy` (see above), if session data
            # is lost, Grafana will simply create a new session on the next
            # request, so it's OK for session storage to be volatile.
            'session'    => {
                provider     => 'memory',
            },

            # Don't send anonymous usage stats to stats.grafana.org.
            # We don't like it when software phones home.
            'analytics'  => {
                reporting_enabled => false,
            },
        },
    }

    # LDAP configuration. Interpolated into the Apache site template
    # to provide mod_authnz_ldap-based user authentication.
    $auth_ldap = {
        name          => 'nda/ops/wmf',
        bind_dn       => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        bind_password => $passwords::ldap::production::proxypass,
        url           => 'ldaps://ldap-eqiad.wikimedia.org ldap-codfw.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        groups        => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

    apache::site { 'grafana-test.wikimedia.org':
        content => template('apache/sites/grafana-test.wikimedia.org.erb'),
        require => Class['::grafana'],
    }

    monitoring::service { 'grafana-test':
        description   => 'grafana-test.wikimedia.org',
        check_command => 'check_http_url!grafana-test.wikimedia.org!/',
    }
}
