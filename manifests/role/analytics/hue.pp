# == Class role::analytics::hue
# Installs Hue server.
#
class role::analytics::hue {
    # I have to require/include the oozie and hive roles
    # manually here.  I'd rather just make them dependencies
    # of this class, but for some reason, they are not evaluated
    # properly (at least in labs) before cdh4::hue gets evalutated,
    # which causes $cdh4::oozie::url to be undefined.
    require role::analytics::hive::client
    require role::analytics::oozie::client

    if ($::realm == 'production') {
        include passwords::ldap::production,
            passwords::analytics
        $ldap_bind_password = $passwords::ldap::production::proxypass
        $secret_key         = $passwords::analytics::hue_secret_key
    }
    elsif ($::realm == 'labs') {
        include passwords::ldap::labs
        $ldap_bind_password = $passwords::ldap::labs::proxypass
        $secret_key         = 'oVEAAG5dp02MAuIScIetX3NZlmBkhOpagK92wY0GhBbq6ooc0B3rosmcxDg2fJBM'
    }

    class { '::cdh4::hue':
        secret_key             => $secret_key,
        smtp_host              => 'mchenry.wikimedia.org',
        smtp_from_email        => "hue@$::fqdn",
        ldap_url               => 'ldaps://virt0.wikimedia.org ldaps://virt1000.wikimedia.org',
        ldap_bind_dn           => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_bind_password     => $ldap_bind_password,
        ldap_base_dn           => 'dc=wikimedia,dc=org',
        ldap_username_pattern  => 'uid=<username>,ou=people,dc=wikimedia,dc=org',
        ldap_user_filter       => 'objectclass=person',
        ldap_user_name_attr    => 'uid',
        ldap_group_filter      => 'objectclass=posixgroup',
        ldap_group_member_attr => 'member',
    }
}

# TODO: Hue SQLite database backup.
