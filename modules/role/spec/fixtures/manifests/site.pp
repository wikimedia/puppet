# Lot of manifests do not explicitly require ::base and we mock it anyway
require_package('git')
require_package('openssh-server')

# Workaround for puppet on Mac OS X raising:
#
# NoMethodError: undefined method `groups' for nil:NilClass
# https://tickets.puppetlabs.com/browse/PUP-1547
User {
    provider => 'useradd',
}

# FIXME
class role::statsite {
}

class privateexim::aliases::private {
}

# From base monitoring. Required by role::cache::*
file { '/usr/lib/nagios/plugins/check-fresh-files-in-dir.py': }
