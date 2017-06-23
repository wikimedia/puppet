# defined type: index.html and css theme for a planet-venus or rawdog language
define planet::theme {

    # file permission defaults
    File {
        owner => 'planet',
        group => 'planet',
        mode  => '0644',
    }

    # use different CSS for Arabic (right-to-left)
    $css_file = $title ? {
        'ar'    => 'planet-ar.css',
        default => 'planet.css',
    }

    # theme directory
    file { "${theme_path}/${title}":
        ensure  => 'directory',
    }

    if os_version('debian == stretch') {
        $theme_path = '/etc/rawdog/theme/wikimedia'
        # style sheet for rawdog
        file { "/var/www/planet/${title}/style.css":
            ensure => 'present',
            source => 'puppet:///modules/planet/theme/rawdog_style.css';
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_page.tmpl":
            ensure => 'present',
            source => 'template('planet/html/rd_page.html.tmpl.erb');
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_item.tmpl":
            ensure => 'present',
            source => 'template('planet/html/rd_item.html.tmpl.erb');
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_feedlist.tmpl":
            ensure => 'present',
            source => 'template('planet/html/rd_feedlist.html.tmpl.erb');
        }
        file { "/etc/rawdog/theme/wikimedia/${title}/rd_feeditem.tmpl":
            ensure => 'present',
            source => 'template('planet/html/rd_feeditem.html.tmpl.erb');
        }
    } else {
        $theme_path = '/usr/share/planet-venus/theme/wikimedia'
        # index.html template
        file { "${theme_path}/${title}/index.html.tmpl":
            ensure  => 'present',
            content => template('planet/html/index.html.tmpl.erb');
        }
        # theme config file
        file { "${theme_path}/${title}/config.ini":
            source  => 'puppet:///modules/planet/theme/config.ini';
        }
        # style sheet for planet-venus
        file { "${theme_path}/${title}/planet.css":
            source  => "puppet:///modules/planet/theme/${css_file}";
        }
    }
}
