class profile::dumps::generation::worker::monitor {
    class { '::snapshot::dumps::monitor':
        xmldumpsuser => 'dumpsgen',
        xmldumpsgroup => 'dumpsgen',
    }
}
