#!/usr/bin/env python
"""Nagios/Icinga Event Handler for RAID checks"""

import argparse
import ConfigParser
import logging
import re
import subprocess
import sys
import time
import zlib

from logging.handlers import RotatingFileHandler

from phabricator import Phabricator

SERVICE_STATES = ('OK', 'UNKNOWN', 'WARNING', 'CRITICAL')
SERVICE_STATE_TYPES = ('SOFT', 'HARD')

RAID_TYPES = ('megacli', 'hpssacli', 'mpt', 'md', 'n/a')
COMPRESSED_RAID_TYPES = ('megacli', 'hpssacli')

SKIP_STRINGS = ('timeout', 'timed out', 'connection refused', 'out of bounds',
                'must have write cache policy', 'Could not complete SSL handshake',
                r'Command check_raid_[^ ]+ not defined')

LOG_PATH = '/var/log/icinga/raid_handler.log'
COMMAND_FILE = '/var/lib/nagios/rw/nagios.cmd'
CHECK_NRPE_PATH = '/usr/lib/nagios/plugins/check_nrpe'

NRPE_REMOTE_COMMAND = 'get_raid_status_{}'
ACK_MESSAGE = 'RAID handler auto-ack: {}'
ICINGA_URL = ('https://icinga.wikimedia.org/cgi-bin/icinga/extinfo.cgi?type=2&'
              'host={host}&service={service}')

PHABRICATOR_CONFIG_FILE = '/etc/phabricator_ops-monitoring-bot.conf'
PHABRICATOR_TAG_PREFIX = 'ops-'
PHABRICATOR_TASK_TITLE = "Degraded RAID on {host}"
PHABRICATOR_TASK_DESCRIPTION_PREFIX = (
    "TASK AUTO-GENERATED by Nagios/Icinga RAID event handler\n\n"
    "A degraded RAID ({type}) [[ {url} | was detected ]] on host `{host}`. "
    "An automatic snapshot of the current RAID status is attached below.\n\n"
    "Please **sync with the service owner** to find the appropriate time "
    "window before actually replacing any failed hardware."
)

logger = logging.getLogger('raid_handler')


def parse_args():
    """Parse command line arguments"""

    parser = argparse.ArgumentParser(
        description='Nagios/Icinga event handler for RAID checks')
    parser.add_argument(
        '-s', dest='service_state', required=True,
        choices=SERVICE_STATES, help='Nagios/Icinga service state')
    parser.add_argument(
        '-t', dest='service_state_type', required=True,
        choices=SERVICE_STATE_TYPES, help='Nagios/Icinga service state type')
    parser.add_argument(
        '-a', dest='service_attempts', required=True, type=int,
        help='Nagios/Icinga service retry attemp counter')
    parser.add_argument(
        '-H', dest='host_address', required=True,
        help='Hostname/address of the monitored host')
    parser.add_argument(
        '-r', dest='raid_type', required=True, choices=RAID_TYPES,
        help='The RAID type, if n/a behaves as --skip-nrpe was set')
    parser.add_argument(
        '-D', dest='service_description', required=True,
        help='The Nagios/Icinga service description')
    parser.add_argument(
        '-c', dest='datacenter', required=True,
        help='The name of the datacenter the host is located in')
    parser.add_argument(
        '-m', dest='message', required=True,
        help='The service Status information output (first line)')
    parser.add_argument(
        '--message-remain', default='',
        help='The service Status information output (remaining lines)')
    parser.add_argument(
        '--skip-nrpe', action='store_true',
        help='Do not get the RAID status via NRPE, rely only on the message')
    parser.add_argument(
        '-d', dest='debug', action='store_true', help='Debug level logging')

    return parser.parse_args()


def get_raid_status(host, raid_type):
    """ Get and return the RAID status of a remote host

        Arguments:
        host      -- hostname to be passed to the NRPE check
        raid_type -- the RAID type to check, see RAID_TYPES for accepted values
    """

    try:
        nrpe_command = [CHECK_NRPE_PATH, '-4', '-H', host,
                        '-c', NRPE_REMOTE_COMMAND.format(raid_type)]
        proc = subprocess.Popen(nrpe_command, stdout=subprocess.PIPE)
        stdout, stderr = proc.communicate()
        if proc.returncode != 0 or len(stdout) == 0:
            raise RuntimeError(
                'RETCODE: {code}\nSTDOUT:\n{out}\nSTDERR:\n{err}'.format(
                    code=proc.returncode, out=stdout, err=stderr))
    except Exception as e:
        status = "Failed to execute '{}': {}".format(nrpe_command, e)
        logger.error(status)
        return status

    if raid_type in COMPRESSED_RAID_TYPES:
        # NRPE doesn't handle NULL bytes, decoding them.
        # Given the specific domain there was no need of a full yEnc encoding.
        try:
            status = zlib.decompress(stdout.replace('###NULL###', '\x00'))
        except zlib.error as e:
            status = 'Failed to decompress Raid status: {err}'.format(err=e)
            logger.error(status)
    else:
        status = stdout

    logger.debug(status)
    return status


def get_phabricator_client():
    """Return a Phabricator client instance"""

    parser = ConfigParser.SafeConfigParser()
    parser_mode = 'phabricator_bot'
    parser.read(PHABRICATOR_CONFIG_FILE)

    client = Phabricator(
        username=parser.get(parser_mode, 'username'),
        token=parser.get(parser_mode, 'token'),
        host=parser.get(parser_mode, 'host'))

    return client


def get_phabricator_project_ids(phab_client, datacenter):
    """ Return a list of Phabricator's projectPHID

        Find the project IDs of the datacenter's tag and add the one of
        Operations group.

        Arguments:
        phab_client -- a Phabricator client instance
        datacenter  -- the name of the datacenter the host is located in
    """

    project_name = '{}{}'.format(PHABRICATOR_TAG_PREFIX, datacenter)
    projects = phab_client.project.query(names=[project_name, 'Operations'])

    if len(projects.data.keys()) != 2:
        logger.error("Unable to find PHID for project '{}', found: {}".format(
            project_name, projects))
        raise RuntimeError("Unable to find PHID")

    logger.debug("Found PHIDs '{}' for project '{}' and Operations".format(
        projects.data.keys(), project_name))

    return projects.data.keys()


def open_phabricator_task(
        phab_client, project_ids, host, raid_type, raid_status, icinga_url):
    """ Open a task on Phabricator and return it

        Arguments:
        phab_client -- a Phabricator client instance
        project_ids -- the PHIDs to tag the task with
        host        -- the hostname of the affected host
        raid_type   -- the RAID type, one of RAID_TYPES
        raid_status -- the RAID status message to include in the task
        icinga_url  -- the URL of the Icinga alarm that triggered this handler
    """

    description_prefix = PHABRICATOR_TASK_DESCRIPTION_PREFIX.format(
        type=raid_type, host=host, url=icinga_url)
    description = '{description_prefix}\n```\n{raid_status}\n```'.format(
        description_prefix=description_prefix, raid_status=raid_status)

    task = phab_client.maniphest.createtask(
        title=PHABRICATOR_TASK_TITLE.format(host=host),
        projectPHIDs=project_ids, description=description)

    logger.debug('Opened Phabricator task: {}'.format(task))
    return task


def acknowledge_nagios_alert(host, service_description, task_uri):
    """ Acknowledge the Nagios/Icinga alert

        Arguments:
        host                -- the hostname of the affected host
        service_description -- the Nagios/Icinga service description
        task_uri            -- the URI of the related Phabricator task
    """

    message = (
        '[{time}] ACKNOWLEDGE_SVC_PROBLEM;{host};{service};2;1;0;'
        'nagiosadmin;{message}\n'
    ).format(time=int(time.time()), host=host, service=service_description,
             message=ACK_MESSAGE.format(task_uri))

    with open(COMMAND_FILE, 'w') as f:
        f.write(message)

    logger.debug('Acknowledged Nagios/Icinga alert: {}'.format(message))


def main():
    """Run the Nagios/Icinga Event Handler for RAID checks"""

    args = parse_args()

    log_formatter = logging.Formatter(
        fmt='%(asctime)s [%(levelname)s] %(name)s::%(funcName)s: %(message)s',
        datefmt='%F %T')
    log_handler = RotatingFileHandler(
        LOG_PATH, maxBytes=5*(1024**2), backupCount=10)
    log_handler.setFormatter(log_formatter)
    logger.addHandler(log_handler)
    logger.raiseExceptions = False
    logger.setLevel(logging.INFO)

    if args.debug:
        logger.setLevel(logging.DEBUG)

    logger.debug('RAID Handler called with args: {}'.format(args))

    if args.service_state != 'CRITICAL' or args.service_state_type != 'HARD':
        logger.debug('Nothing to do, exiting')
        return

    for skip_string in SKIP_STRINGS:
        if re.search(skip_string, args.message, flags=re.IGNORECASE) is not None:
            logger.info(
                ("Skipping RAID Handler execution for host '{host}' and RAID type "
                 "'{raid}', skip string '{pattern}' detected in '{str}'").format(
                    host=args.host_address, raid=args.raid_type, pattern=skip_string,
                    str=args.message))
            return

    raid_status = '{msg}\n{msg_remain}\n'.format(
        msg=args.message, msg_remain=args.message_remain)

    if args.skip_nrpe or args.raid_type == 'n/a':
        logger.debug('Skipping NRPE RAID status gathering')
    else:
        raid_status += '$ sudo /usr/local/lib/nagios/plugins/{command}\n{status}'.format(
            command=NRPE_REMOTE_COMMAND.format(args.raid_type),
            status=get_raid_status(args.host_address, args.raid_type))

    phab_client = get_phabricator_client()
    project_ids = get_phabricator_project_ids(phab_client, args.datacenter)

    icinga_url = ICINGA_URL.format(
        host=args.host_address, service=args.service_description)
    task = open_phabricator_task(phab_client, project_ids, args.host_address,
                                 args.raid_type, raid_status, icinga_url)

    acknowledge_nagios_alert(
        args.host_address, args.service_description, task['uri'])

    logger.info(
        ("RAID Handler executed for host '{}' and RAID type '{}'. "
         "Created task ID '{}'").format(
            args.host_address, args.raid_type, task['id']))

    logger.debug('RAID Handler completed')


if __name__ == '__main__':
    try:
        main()
    except Exception:
        logger.exception("Unable to handle RAID check alert")
        if sys.stdout.isatty():
            raise
