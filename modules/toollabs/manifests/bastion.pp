# Class: toollabs::bastion
#
# This role sets up an bastion/dev instance in the Tool Labs model.
#
# Parameters:
#       gridmaster => FQDN of the gridengine master
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::bastion($gridmaster) inherits toollabs {
  include ssh::bastion,
    toollabs::exec_environ,
    toollabs::dev_environ

  class { 'gridengine::submit_host':
    gridmaster => $gridmaster,
  }

  file { "/etc/update-motd.d/40-bastion-banner":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/40-${instanceproject}-bastion-banner",
  }

  file { "$store/submithost-$fqdn":
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0444',
    require => File[$store],
    content => "$ipaddress\n",
  }

  file { "/usr/bin/sql":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/sql",
  }

  # Display tips.
  package { 'grep':
    ensure => present,
  }

  file { "/etc/profile.d/tips.sh":
    ensure => file,
    mode => "0755",
    owner => "root",
    group => "root",
    source => "puppet:///modules/toollabs/tips.sh",
    require => Package['grep'],
  }

  file { [ '/data/project/.system/tips.sh',
           '/data/project/.system/bin/tips.sh',
           '/data/project/.system/bin/tips2.sh' ]:
    ensure => absent,
  }

  package { [ 'jobutils', 'misctools' ]:
    ensure => latest,
  }

  # TODO: cron setup
}

