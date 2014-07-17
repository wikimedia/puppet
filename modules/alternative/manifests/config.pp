define alternatives::config ($path){

    $path_safe =  regsubst($path, '[\W]', '_', 'G')

    # We want puppet to fail if a configured alternative is not installed
    exec { "check_alternative_${title}_${path_safe}":
        command     => "/usr/bin/update-alternatives --query ${name} | /bin/grep -q '^Alternative: ${path}\$'",
        refreshonly => true,
        notify      => Exec["set_alternative_${title}_${path_safe}"]
    }

    exec { "set_alternative_${title}_${path_safe}":
        command     => "/usr/bin/update-alternatives --set ${title} ${path}",
        refreshonly => true,
        unless      => "/usr/bin/update-alternatives --query ${name} | /bin/grep -q '^Value: ${path}\$'"
    }
}
