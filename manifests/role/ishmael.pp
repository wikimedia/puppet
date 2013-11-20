# manifests/role/ishmael.pp
# ishmael: A UI for mk-query-digest
class role::ishmael {

    system::role { 'role::ishmael': description => 'ishmael server' }

    class { 'ishmael':
        site_name => 'ishmael.wikimedia.org',
        sslcert => 'star.wikimedia.org',
    }

}
