# vim: set sw=4 ts=4 expandtab:

# == Class: role::beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class role::beta::autoupdater {
    system::role { 'role::beta::autoupdater':
        description => 'Server is autoupdating MediaWiki core and extension on beta.'
    }

    include beta::autoupdater
}

class role::beta::fatalmonitor {
    system::role { 'role::beta::fatalmonitor':
        description => 'Monitor fatal errors and mails qa list'
    }

    include beta::fatalmonitor
}

class role::beta::natfix {
    system::role { 'role::beta::natfix':
        description => 'Server has beta NAT fixup'
    }

    include beta::natfix
}

class role::beta::maintenance {
    class{ 'misc::maintenance::geodata': enabled => true }
}

class role::beta::syncsiteresources {
    system::role { 'role::beta::syncsiteresources':
        description => 'Sync material from production wikis to beta wikis'
    }

    include beta::syncsiteresources
}
