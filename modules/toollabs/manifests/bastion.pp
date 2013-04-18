# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::bastion {
    include gridengine::submit_host
    include ssh::bastion
    include toollabs::exec_environ
    include toollabs::dev_environ
}

