# Create LV needed by swift and instruct udev to symlink it to its expected
# location to simulate a disk partition.
class profile::swift::storage::labs {
  include ::lvm

  lvm::logical_volume { 'lv-a1':
    volume_group => 'vd',
    createfs     => false,
    mounted      => false,
    extents      => '80%FREE',
  }

  file { '/etc/udev/rules.d/90-swift-lvm.rules':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => 'ENV{DM_LV_NAME}=="lv-a1", ENV{DM_VG_NAME}=="vd", SYMLINK+="swift/lv-a1"',
    notify  => Exec['swift_labs_udev_reload'],
    require => Lvm::Logical_volume['lv-a1'],
  }

  exec { 'swift_labs_udev_reload':
    command     => '/sbin/udevadm control --reload && /sbin/udevadm trigger',
    refreshonly => true,
  }
}
