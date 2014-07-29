class quarry::web {
    $clone_path = "$base_path/web"
    $result_path = "/data/project/quarry/results"
    $venv_path = "$base_path/venv"

    include quarry::base

    uwsgi::app { 'quarry-web':
        require              => Git::Clone['analytics/quarry/web'],
        settings             => {
            uwsgi            => {
                'socket'     => '/run/uwsgi/quarry-web.sock',
                'wsgi-file'  => "$clone_path/quarry.wsgi",
                'master'     => true,
                'processes'  => 8,
                'venv'       => $venv_path,
            }
        }
    }

    nginx::site { 'quarry-web-nginx':
        require => Uwsgi::App['quarry-web'],
        content => template('quarry/quarry-web.nginx.erb')
    }
}

