# == Base::service_unit ==
#
# Allows defining services and their corresponding init scripts in a
# init-system agnostic way on Debian derivatives.
#
# We prefer convention over configuration, so this define will require
# you to respect those in order to work.
#
# === Parameters ===
#
#[*ensure*]
# Is the usual metaparameter, defaults to true
#
#[*provider*]
# This maps directly to the service type provider parameter
#
#[*has_initscripts*]
# Boolean - set it to true to make the resource include personalized
# init files. As this is used to You are expected to put them in a
# specific subdirectory of the current module, which is
# $module/initscripts/$name.systemd.erb for systemd, and similarly for
# other init systems
#
#[*service_params*]
# An hash of parameters that we want to apply to the service resource
#
# === Example ===
#
# A init-agnostic class that runs apache, with its own init scripts
# (please, don't do it at home!)
#
# class foo {
#     base::service_unit { 'apache2':
#         ensure          => true,
#         has_initscripts => true,
#         service_params  => {
#             hasrestart => true,
#             restart => '/usr/sbin/service apache2 restart'
#         }
#     }
# }
define base::service_unit (
    $ensure           = present,
    $has_initscripts  = false,
    $provider         = $::initsystem,
    $service_params   = {},
    ) {
    validate_ensure($ensure)
    $safe_name = regsubst($title, '[\W]', '-', 'G')
    # we assume init scripts are templated
    if $has_initscripts {
        $template = "${caller_module_name}/initscripts/${safe_name}.${::initsystem}.erb"
        $path = $::initsystem ? {
            'systemd'  => "/etc/systemd/system/${name}.service",
            'upstart'  => "/etc/init/${name}.conf",
            default    => "/etc/init.d/${name}"
        }

        file {$path:
            ensure  => $ensure,
            content => template($template),
            mode    => '0544',
            owner   => root,
            group   => root,
        }

        if $provider == 'systemd' {
                exec { "systemd reload for ${name}":
                    refreshonly => true,
                    command     => '/bin/systemctl daemon-reload',
                    subscribe   => File[$path],
                    before      => Service[$name]
                }

        }
    }

    $base_params = { ensure => ensure_service($ensure), provider => $provider}
    $params = merge($base_params, $service_params)
    ensure_resource('service',$name, $params)
}
