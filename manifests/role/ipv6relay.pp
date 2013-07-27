# vim: set sw=4 ts=4 expandtab:

class role::ipv6relay {
    system_role { 'role::ipv6relay': description => 'IPv6 tunnel relay (6to4/Teredo)' }

    include sysctlfile::advanced-routing-ipv6

    # Teredo
    include misc::miredo

    # 6to4
    interface_tun6to4 { 'tun6to4': }
}
