# application server required cron jobs
class applicationserver::cron {
    cron { 'cleanupipc':
        ensure  => present,
        command => 'ipcs -s | grep apache | cut -f 2 -d \\  | xargs -rn 1 ipcrm -s',
        user    => 'root',
        minute  => 26,
    }
    cron { 'cleantmpphp':
        ensure  => present,
        command => 'find /tmp -name "php*" -type f -ctime +1 -exec rm -f {} \\;',
        user    => 'root',
        hour    => 5,
        minute  => 0,
    }
}
