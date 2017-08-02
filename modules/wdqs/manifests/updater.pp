# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
class wdqs::updater(
    $options,
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
){

    # Blazegraph service
    systemd::unit { 'wdqs-updater':
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
        require => [
            File['/etc/wdqs/updater-logs.xml'],
            Service['wdqs-blazegraph']
        ],
    }
}
