# == Define: sudo::user
#
# Manages a sudo specification in /etc/sudoers.d.
#
# === Parameters
#
# [*privileges*]
#   Array of sudo privileges.
#
# [*user*]
#   User to which privileges should be assigned.
#   Defaults to the resource title.
#
# [*sudo_flavor*]
#   sudo flavor to require. Options are sudo or sudoldap.
#   Defaults to 'sudo'.
#
# === Examples
#
#  sudo::user { 'nagios_check_raid':
#    user       => 'nagios',
#    privileges => [
#      'ALL = NOPASSWD: /usr/local/lib/nagios/plugins/check-raid'
#    ],
#  }
#
define sudo::user(
    $privileges,
    $ensure                              = present,
    $user                                = $title,
    # lint:ignore:wmf_styleguide
    Enum['sudo','sudoldap'] $sudo_flavor = lookup('sudo_flavor', {default_value => 'sudo'}),
    # lint:endignore
) {
    if $sudo_flavor == 'sudo' or os_version('debian >= buster') {
        require sudo
    } else {
        require sudo::sudoldap
    }

    validate_ensure($ensure)

    $title_safe = regsubst($title, '\W', '-', 'G')
    $filename = "/etc/sudoers.d/${title_safe}"

    if $ensure == 'present' {
        file { $filename:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => template('sudo/sudoers.erb'),
        }

        exec { "sudo_user_${title}_linting":
            command     => "/bin/rm -f ${filename} && /bin/false",
            unless      => "/usr/sbin/visudo -cqf ${filename}",
            refreshonly => true,
            subscribe   => File[$filename],
        }
    } else {
        file { $filename:
            ensure => $ensure,
        }
    }
}
