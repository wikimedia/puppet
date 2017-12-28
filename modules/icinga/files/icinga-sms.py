#!/usr/bin/python3
# icinga_sms.py
#
# send SMS to Icinga contacts
#
# https://phabricator.wikimedia.org/T82937
# 2017 - Daniel Zahn - Wikimedia Foundation
#
import argparse
import re
import smtplib
import sys

# full path to an Icinga contacts.cfg file
# this script is intended to run on an Icinga server
CONTACTS_FILE = '/etc/icinga/contacts.cfg'

# mail sent from einsteinium.wikimedia.org (icinga server) uses these
MAIL_FROM = 'icinga@wikimedia.org'
MAIL_SERVER = 'mx1001.wikimedia.org'


# get address for a user from an Icinga contacts file
#
# In the Wikimedia setup, 'address1' is used in Icinga contact
# definitions for an email address (containing a phone number)
# to be used with an Email2SMS gateway.
# Therefore e-mailing that address means sending SMS to users.
def get_address(contact_name):
    with open(CONTACTS_FILE, 'r') as contacts_data:
        contact_data = contacts_data.read()
        contact_data = contact_data.split('contact_name')
        for contact in contact_data:
            if contact_name+'\n' in contact:
                regex = re.compile('address1\s+\d+@.*(.*?)')
                address1 = regex.search(contact).group(0).split('address1')
                return address1[1].strip()


# send an e-mail
def send_email(mail_to,
               mail_msg,
               MAIL_SERVER,
               MAIL_FROM):
    server = smtplib.SMTP(MAIL_SERVER)
    server.sendmail(MAIL_FROM, mail_to, mail_msg)
    server.quit()


# list all contact names found in the contacts file
def list_contacts_all(CONTACTS_FILE):
    contact_list = []
    with open(CONTACTS_FILE, 'r') as contacts_data:
        for line in contacts_data:
            if 'contact_name' in line:
                contact_name = line.split('contact_name')
                contact_list.append(contact_name[1].strip())
        return sorted(contact_list, key=str.lower)


# list all contact names who can receive SMS (have an address1 set)
def list_contacts_sms(CONTACTS_FILE):
    contact_list = []
    with open(CONTACTS_FILE, 'r') as contacts_data:
        contact_data = contacts_data.read()
        contact_data = contact_data.split('define contact')
        for contact in contact_data:
            regex = re.compile('address1\s+\d+@.*(.*?)')
            if regex.search(contact):
                contact_name = contact.split('contact_name')
                contact_name = contact_name[1].split('\n')
                contact_list.append(contact_name[0].strip())

        return sorted(contact_list, key=str.lower)


# parse command-line arguments
parser = argparse.ArgumentParser()
parser.add_argument('-l', '--list', action='store_true',
                    help='List all contacts who can receive SMS.')
parser.add_argument('-lf', '--listfull', action='store_true',
                    help='List all contacts who can receive SMS,\
                    along with their addresses.')
parser.add_argument('-la', '--listall', action='store_true',
                    help='list all contacts found in contact file')
parser.add_argument('-a', '--address', nargs=1,
                    help='Get the address for a contact name.\
                    expects 1 parameter, contact_name')
parser.add_argument('-s', '--send', nargs=2,
                    help='Send SMS to a contact name.\
                    expects 2 parameters, contact_name and message')
parser.add_argument('-sa', '--sendall', nargs=1,
                    help='Send SMS to ALL contacts who can receive SMS.\
                    expects 1 parameter, message')

if len(sys.argv) == 1:
    parser.print_help()
    sys.exit(1)

args = parser.parse_args()

# list all contacts in the Icinga contacts file who can be sent SMS
# usage: -l | --list
if args.list:
    print('\n'.join(list_contacts_sms(CONTACTS_FILE)))

# list all contacts in the Icinga contacts file (usage: -la | --listall)
if args.listall:
    print('\n'.join(list_contacts_all(CONTACTS_FILE)))

# list all possible (SMS'able) contacts along with their address1
if args.listfull:
    contact_list = list_contacts_sms(CONTACTS_FILE)
    for contact_name in contact_list:
        contact_addr = get_address(contact_name)
        print('%s %s' % (contact_name, contact_addr))

# get the address for an Icinga contact name
# usage: -a | --address <contact_name>
if args.address:
    contact_name = sys.argv[2]
    # print 'looking up address for '%s'' % contact_name
    contact_addr = get_address(contact_name)
    print(contact_addr)

# send SMS (via E-mail gateway) to an Icinga contact
if args.send:
    contact_name = sys.argv[2]
    mail_msg = sys.argv[3]
    contact_addr = get_address(contact_name)
    print('sending message for %s at %s | content: \'%s\' (from: %s via %s)') \
        % (contact_name, contact_addr, mail_msg, MAIL_FROM, MAIL_SERVER)
    send_email(contact_addr, mail_msg)

# send SMS (via E-mail gateway) to ALL SMS'able Icinga contacts
if args.sendall:
    contact_list = list_contacts_sms(CONTACTS_FILE)
    mail_msg = sys.argv[2]
    for contact_name in contact_list:
        contact_addr = get_address(contact_name)
        print('sending message for %s at %s |\
                content: \'%s\' (from: %s via %s)') \
            % (contact_name, contact_addr,
               mail_msg, MAIL_FROM, MAIL_SERVER)
        send_email(contact_addr, mail_msg)
