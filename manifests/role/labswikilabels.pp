class role::labs::wikilabels::staging {
    class { 'wikilabels::web':
        branch => 'master',
    }
    
    include ::wikilabels::db
    include ::wikilabels::session

    class { '::wikilabels::db_proxy':
        server => 'localhost',
    }
}