# @summary configure WMF pki client
# @param ensure whether to ensure the resource
# @param signer_host The signer host
# @param signer_port The signer port
# @param use_stunnel use an stunnel encrypt
# @param auth_key the cfssl sha256 hmax key
class profile::pki::client (
    Wmflib::Ensure             $ensure                 = lookup('profile::pki::client::ensure'),
    Stdlib::Host               $signer_host            = lookup('profile::pki::client::signer_host'),
    Stdlib::Port               $signer_port            = lookup('profile::pki::client::signer_port'),
    Sensitive[String[1]]       $auth_key               = lookup('profile::pki::client::auth_key'),
    Boolean                    $enable_proxy           = lookup('profile::pki::client::enable_proxy'),
    Stdlib::IP::Address        $listen_addr            = lookup('profile::pki::client::listen_addr'),
    Stdlib::Port               $listen_port            = lookup('profile::pki::client::listen_port'),
    Optional[Stdlib::Unixpath] $mutual_tls_client_cert = lookup('profile::pki::client::mutual_tls_client_cert'),
    Optional[Stdlib::Unixpath] $mutual_tls_client_key  = lookup('profile::pki::client::mutual_tls_client_key'),
    Optional[Stdlib::Unixpath] $tls_remote_ca          = lookup('profile::pki::client::tls_remote_ca'),
    Hash                       $certs                  = lookup('profile::pki::client::certs'),
) {
    $signer = "https://${signer_host}:${signer_port}"
    $bundles_source = "http://${signer_host}/bundles"
    class {'cfssl::client':
        ensure                 => $ensure,
        signer                 => $signer,
        bundles_source         => $bundles_source,
        auth_key               => $auth_key,
        enable_proxy           => $enable_proxy,
        listen_addr            => $listen_addr,
        listen_port            => $listen_port,
        mutual_tls_client_cert => $mutual_tls_client_cert,
        mutual_tls_client_key  => $mutual_tls_client_key,

    }
    $certs.each |$title, $cert| {
        cfssl::cert{$title:
            *        => $cert,
        }
    }
}
