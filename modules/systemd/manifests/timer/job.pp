# == Define: systemd::timer::job
#
# Generic wrapper around the basic timer definition that adds log handling
# and monitoring for defining recurring jobs, much like crons in non-systemd
# world
#
# [*description*]
#   Description to place in the systemd unit.
#
# [*command*]
#   Command to be executed periodically.
#
# [*interval*]
#   Systemd interval to use. See Systemd::Timer::Schedule for the format.
#   Several intervals can be provided as Array[See Systemd::Timer::Schedule]
#
# [*user*]
#   User that runs the Systemd unit.
#
#  [*environment*]
#   Hash containing 'Environment=' related values to insert in the
#   Systemd unit.
#
#  [*monitoring_enabled*]
#   Periodically check the last execution of the unit and alarm if it ended
#   up in a failed state.
#   Default: true
#
#  [*monitoring_contact_groups*]
#   The monitoring's contact group to send the alarm to.
#   Default: admins
#
#  [*logging_enabled*]
#   If true, log directories are created, rsyslog/logrotate rules are created.
#   Default: true
#
#  [*logfile_basedir*]
#   Base directory for log files, to which /$title will be appended.
#   Logs will be saved at $logfile_basedir/$title/$logfile_name
#   Default: "/var/log"
#
#  [*logfile_name*]
#   The filename of the file storing the syslog output of
#   the running unit.
#   Default: syslog.log
#
#  [*logfile_owner*]
#   The user that owns the logfile. If undef, the value of $user will be used.
#   Default: undef
#
#  [*logfile_group*]
#   The group that owns the logfile.
#   Default:  root''
#
#  [*logfile_perms*]
#   The UNIX file permissions to set on the log file.
#   Check systemd::syslog for more info about the available options.
#   Default: 'all'
#
#  [*syslog_force_stop*]
#   Force logs to be written into the logfile but not in
#   syslog/daemon.log. This is particularly useful for units that
#   need to log a lot of information, since it prevents a duplication
#   of space consumed on disk.
#   Default: true
#
#  [*syslog_match_startswith*]
#   If true, all syslog programnames that start with the service_name
#   will be logged to the output log file.  Else, only service_names
#   that match exactly will be logged.
#   Default: true
#
#  [*syslog_identifier*]
#   Adds the SyslogIdentifier parameter to the systemd unit to
#   override the default behavior, namely using the program name.
#   This is particularly useful when multiple timers are scheduled
#   using the same program but with different parameters. Without
#   an explicit SyslogIdentifier in fact they would end up sharing
#   the same identifier and rsyslog rules wouldn't work anymore.
#   Default: undef
#
#  [*max_runtime_seconds*]
#   Add a RuntimeMaxSec=... stanza to the systemd unit triggered by the timer.
#   This can be useful when setting a timer to run some code every N minutes
#   and the process run by the unit has a potential for deadlocking rather
#   than exiting under some internal error condition. See
#   <https://www.freedesktop.org/software/systemd/man/systemd.service.html#RuntimeMaxSec=>
#   for more details.
#   Default: undef (do not add stanza)
#
#  [*slice*]
#    Run the systemd timer's service unit under a specific slice.
#    By default the service unit will run under the system.slice.
#    Default: undef (do not add any Slice setting to the unit)
#
#  [*environment_file*]
#   String containing a file path to be used as 'EnvironmentFile=' in the Systemd unit.
#
define systemd::timer::job(
    Variant[
        Systemd::Timer::Schedule,
        Array[Systemd::Timer::Schedule, 1]] $interval,
    String                                  $description,
    String                                  $command,
    String                                  $user,
    Wmflib::Ensure                          $ensure                    = 'present',
    Hash[String, String]                    $environment               = {},
    Boolean                                 $monitoring_enabled        = false,
    String                                  $monitoring_contact_groups = 'admins',
    Boolean                                 $logging_enabled           = true,
    String                                  $logfile_basedir           = '/var/log',
    String                                  $logfile_name              = 'syslog.log',
    String                                  $logfile_group             = 'root',
    Enum['user', 'group', 'all']            $logfile_perms             = 'all',
    Boolean                                 $syslog_force_stop         = true,
    Boolean                                 $syslog_match_startswith   = true,
    Optional[String]                        $logfile_owner             = undef,
    Optional[String]                        $syslog_identifier         = undef,
    Optional[Integer]                       $max_runtime_seconds       = undef,
    Optional[Pattern[/\w+\.slice/]]         $slice                     = undef,
    Optional[Stdlib::Unixpath]              $environment_file          = undef,
) {
    # Sanitize the title for use on the filesystem
    $safe_title = regsubst($title, '[^\w\-]', '_', 'G')


    $input_intervals = $interval ? {
        Systemd::Timer::Schedule => [$interval],
        default                  => $interval,
    }

    # If we were provided with only OnUnitActive/OnUnitInactive intervals, which are times relative
    # to when the service unit was last activated or deactivated, we need to add an additional
    # interval to get systemd to DTRT with this timer: an OnActiveSec that will start the service
    # for the first time after the timer and service are installed (or after a reboot).
    #
    # This activation gives meaning to the OnUnit intervals, as a null value for the timestamp of
    # last service activation/deactivation acts like NaN, making the comparison always false.
    $mangled_intervals = $input_intervals.all |$iv| {$iv['start'] =~ /OnUnit(In)?[Aa]ctive/} ? {
        false => $input_intervals,
        true  => $input_intervals + [{
            'interval' => '1s',
            'start'    => 'OnActiveSec'
        }],
    }

    systemd::unit { "${title}.service":
        ensure  => $ensure,
        content => template('systemd/timer_service.erb'),
    }

    systemd::timer { $title:
        ensure          => $ensure,
        timer_intervals => $mangled_intervals,
        unit_name       => "${title}.service",
    }

    if $logging_enabled {
        # The owner of the log files
        $log_owner = $logfile_owner ? {
            undef   => $user,
            default => $logfile_owner
        }

        # If syslog_match_startswith is false, use equality when matching
        # the programname to output to the log file, else use startswith.
        $syslog_programname_comparison = $syslog_match_startswith ? {
            false => 'isequal',
            true  => 'startswith',
        }

        systemd::syslog { $safe_title:
            ensure                 => $ensure,
            base_dir               => $logfile_basedir,
            log_filename           => $logfile_name,
            owner                  => $log_owner,
            group                  => $logfile_group,
            readable_by            => $logfile_perms,
            force_stop             => $syslog_force_stop,
            programname_comparison => $syslog_programname_comparison
        }
    }


    if $monitoring_enabled {
        # T225268 - always provision NRPE plugin script
        require systemd::timer::nrpe_plugin

        nrpe::monitor_service { "check_${title}_status":
            ensure         => $ensure,
            description    => "Check the last execution of ${title}",
            nrpe_command   => "/usr/local/lib/nagios/plugins/check_systemd_unit_status ${title}",
            check_interval => 10,
            retries        => 2,
            contact_group  => $monitoring_contact_groups,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Managing_systemd_timers',
        }
    }
}
