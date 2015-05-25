# = Class: role::limesurvey
#
# This class sets up a LimeSurvey instance
#
class role::limesurvey {

    class { '::limesurvey':
        hostname     => 'limesurvey.wikimedia.org',
        deploy_dir   => '/srv/deployment/limesurvey/limesurvey',
        cache_dir    => '/var/cache/limesurvey',
        # Send logs to fluorine
        udp2log_dest => '10.64.0.21:8420',
        serveradmin  => 'noc@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => 'm2-master.eqiad.wmnet',
        mysql_db     => 'limesurvey',
        smtp_host    => $::mail_smarthost[0],
    }

    ferm::service { 'limesurvey_http':
        proto => 'tcp',
        port  => '80',
    }

}
# vim:sw=4 ts=4 sts=4 et:
