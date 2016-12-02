# == Class: citoid
#
# This class installs and configures citoid
#
# While only being a thin wrapper around service::node, this class exists to
# accomodate future citoid needs that are not suited for the service module
# classes as well as conform to a de-facto standard of having a module for every
# service
#
# === Parameters
#
# [*zotero_host*]
#   The DNS/IP address of the zotero host
#
# [*zotero_port*]
#   The zotero host's TCP port
#
# [*wskey*]
#   The WorldCat Search API key to use. Default:
#   SzH9M2MhDgFmp0nyi8xKGI62A2Ll3cB4j8krnON0ZJPQqzqm0uo1Du3CNYk7mVllOcujIsWWwLumboHj
#
class citoid(
    $zotero_host,
    $zotero_port,
    $wskey = 'SzH9M2MhDgFmp0nyi8xKGI62A2Ll3cB4j8krnON0ZJPQqzqm0uo1Du3CNYk7mVllOcujIsWWwLumboHj',
) {
    service::node { 'citoid':
        port              => 1970,
        healthcheck_url   => '',
        has_spec          => true,
        deployment        => 'scap3',
        deployment_config => true,
        deployment_vars   => {
            zotero_host => $zotero_host,
            zotero_port => $zotero_port,
            wskey       => $wskey,
        },
    }
}
