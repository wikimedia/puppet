# == Class: role::zotero
#
# Zotero is free and open-source reference management
# software to manage bibliographic data and related research materials.
# https://en.wikipedia.org/wiki/Zotero
#

@monitoring::group { 'zotero_eqiad': description => 'Zotero eqiad' }
@monitoring::group { 'zotero_codfw': description => 'Zotero codfw' }

class role::zotero {
    system::role { 'zotero': description => "Zotero ${::realm}" }

    ferm::service {
        proto => 'tcp',
        port  => '1969',
    }

    monitoring::service {
        description   => 'zotero',
        check_command => 'check_http_on_port!1969',
    }

    include ::zotero
    # include lvs::realserver
}
