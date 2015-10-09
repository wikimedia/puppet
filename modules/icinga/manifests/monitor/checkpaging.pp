# = Class: icinga::monitor::checkpaging
#
# Sets up a simple monitoring service to check if paging
# is working properly
class icinga::monitor::checkpaging {
    monitoring::service { 'check_to_check_nagios_paging':
        description           => 'check_to_check_nagios_paging',
        check_command         => 'check_to_check_nagios_paging',
        normal_check_interval => 1,
        retry_check_interval  => 1,
        critical              => false
    }
}
