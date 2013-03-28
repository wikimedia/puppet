# == Define misc::limn::instance
# Sets up a limn instance as well as a
# limn instance proxy.  This define
# uses $::realm to infer an appropriate
# default $server_name and $server_aliases.
#
# == Parameters:
# $port            - limn port
# $server_name     - ServerName for limn instance proxy.     Default it to infer from $name and $::realm.
# $server_aliases  - ServerAliases for limn instance proxy.  Default is to infer from $name and $::realm.
#
# == Example
# misc::limn::instance { 'reportcard': }
#
define misc::limn::instance($port = 8081, $server_name = undef, $server_aliases = undef) {
  limn::instance { $name:
    port => $port,
  }

  # If $server_name was not specified,
  # Pick $name.wikimedia.org for production,
  # $name.wmflabs.org for labs,
  # and just $name for anything else.
  $servername = $server_name ? {
    undef   => $::realm ? {
      'production' => "${name}.wikimedia.org",
      'labs'       => "${name}.wmflabs.org",
      default      => $name,
    },
    default => $server_name,
  }

  # If $server_aliases was not specified,
  # Pick ${name}.instance-proxy.wmflabs.org for labs,
  # and none for anything else.
  $serveraliases = $server_aliases ? {
    undef   => $::realm ? {
      'labs'       => "${name}.instance-proxy.wmflabs.org",
      default      => '',
    },
    default => $server_aliases,
  }

  limn::instance::proxy { $name:
    limn_port      => $port,
    server_name    => $servername,
    server_aliases => $serveraliases,
  }
}
