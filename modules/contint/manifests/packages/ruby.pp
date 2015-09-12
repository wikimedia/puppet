# === Class contint::packages::ruby
#
# This class sets up packages needed for general ruby testing
#
class contint::packages::ruby {
    package { [
        'ruby2.0',
        # bundle/gem compile ruby modules:
        'ruby2.0-dev',
        ]: ensure => present,
    }
}
