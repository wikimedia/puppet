# === Class contint::packages::python
#
# This class sets up packages needed for general python testing
#
class contint::packages::python {
    require_package( # Let us compile python modules:
        'build-essential',
        'python-dev',
        'python-pip',  # Needed to install pip from pypi
        'libmysqlclient-dev',  # For python SQLAlchemy
        'libxml2-dev',   # For python lxml
        'libxslt1-dev',  # For python lxml
        'libffi-dev', # For python requests[security]
    )

    # Bring in fresh pip. The Trusty package does not provide wheels cache
    # https://pip.pypa.io/en/latest/news.html
    package { 'pip':
        ensure   => '7.1.0',
        provider => 'pip',
        require  => Package['python-pip'],  # eggs and chicken
    }

    # Bring tox/virtualenv... from pip  T46443
    package { 'tox':
        ensure   => '1.9.2',
        provider => 'pip',
        require  => Package['pip'],  # Fresh pip version
    }

    # Python 3
    require_package(
        'python3',
        'python3-dev',
        'python3-tk',  # For pywikibot/core running tox-doc-trusty
    )
}
