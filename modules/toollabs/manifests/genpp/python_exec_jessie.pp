# Class: toollabs::genpp::python_exec_jessie
#
# This file was auto-generated by genpp.py using the following command:
# ./python.py
#
# Please do not edit manually!

class toollabs::genpp::python_exec_jessie {
    package { [
        'python-babel',
        'python-beautifulsoup',
        'python-bottle',
        'python-celery',
        'python-egenix-mxdatetime',
        'python-egenix-mxtools',
        'python-flask',
        'python-flask-login',
        'python-flickrapi',
        'python-flup',
        'python-gdal',
        'python-gdbm',
        'python-genshi',
        'python-genshi-doc',
        'python-geoip',
        'python-gevent',
        'python-gi',
        'python-greenlet',
        'python-httplib2',
        'python-imaging',
        'python-ipaddr',
        'python-keyring',
        'python-launchpadlib',
        'python-lxml',
        'python-magic',
        'python-matplotlib',
        'python-mysql.connector',
        'python-mysqldb',
        'python-newt',
        'python-nose',
        'python-opencv',
        'python-pycountry',
        'python-pydot',
        'python-pyexiv2',
        'python-pygments',
        'python-pyinotify',
        'python-requests',
        'python-rsvg',
        'python-scipy',
        'python-socketio-client',
        'python-sqlalchemy',
        'python-svn',
        'python-twisted',
        'python-twitter',
        'python-unicodecsv',
        'python-unittest2',
        'python-virtualenv',
        'python-wadllib',
        'python-webpy',
        'python-werkzeug',
        'python-yaml',
        'python-zbar',
        'python-zmq',
        'python3-babel',
        'python3-bottle',
        'python3-celery',
        'python3-flask',
        'python3-gdal',
        'python3-gdbm',
        'python3-genshi',
        'python3-geoip',
        'python3-gi',
        'python3-greenlet',
        'python3-httplib2',
        'python3-keyring',
        'python3-lxml',
        'python3-magic',
        'python3-matplotlib',
        'python3-mysql.connector',
        'python3-newt',
        'python3-nose',
        'python3-pycountry',
        'python3-pydot',
        'python3-pygments',
        'python3-pyinotify',
        'python3-requests',
        'python3-scipy',
        'python3-sqlalchemy',
        'python3-virtualenv',
        'python3-wadllib',
        'python3-werkzeug',
        'python3-yaml',
        'python3-zmq',
    ]:
        ensure => latest,
    }
}