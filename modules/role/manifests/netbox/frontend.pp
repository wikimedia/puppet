# Class: role::netbox::frontend
#
# This role installs all the Netbox web frontend related parts as WMF requires it
#
# Actions:
#       Deploy Netbox web frontend
#
# Requires:
#
# Sample Usage:
#       role(netbox::frontend)
#

class role::netbox::frontend {
    system::role { 'netbox::frontend': description => 'Netbox frontend server' }

    include ::profile::netbox
}
