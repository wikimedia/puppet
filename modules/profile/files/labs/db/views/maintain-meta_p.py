#! /usr/bin/env python
# -*- encoding: utf-8 -*-

#  Based on work by Marc-André Pelletier, ported to Python by Alex Monk
#  Copyright © 2015 Alex Monk <krenair@gmail.com>
#  Copyright © 2013 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

import argparse
import logging
import os
import pymysql
import requests
import re
import simplejson as json
import sys
import yaml


class SchemaOperations():
    def __init__(self, db, cursor):
        self.db = db
        self.cursor = cursor

    def write_execute(self, query):
        """ Log and run a query
        :param query: str
        """
        logging.debug("SQL: {}".format(query.encode('utf-8')))
        self.cursor.execute(query)


class DrySchemaOperations():
    def write_execute(self, query):
        logging.debug("(dry-run) SQL: {}".format(query.encode('utf-8')))


def force_to_unicode(text):
    """ Ouput unicode or else
    :param text: str
    """
    return text if isinstance(text, unicode) else text.decode('utf8')


def parse_php_canonical(mfile):
    """ Given the 'initializesettings.php' file pull out the
    list of canonical urls the hard way
    :param mfile: str
    """

    with open(mfile, 'r') as f:
        fcontent = f.read()
        data_structures = re.split('\n],', fcontent)
        for d in data_structures:
            if "wgCanonicalServer' => [" in d:
                rawCanonicalServer = d

    canonical_servers = {}
    for line in rawCanonicalServer.split('\n'):
        if '=>' in line:
            key, value = line.split('=>')
            key = key.rstrip().lstrip().strip("'")
            if ',' in value:
                value = value.split(',')[0]
            value = value.strip().strip("'")
            canonical_servers[key] = value
    return canonical_servers


def seed_schema(ops):
    ops.write_execute("CREATE DATABASE IF NOT EXISTS meta_p DEFAULT CHARACTER SET utf8;")
    ops.write_execute("""CREATE TABLE IF NOT EXISTS meta_p.wiki (
            dbname varchar(32) PRIMARY KEY,
            lang varchar(12) NOT NULL DEFAULT 'en',
            name text,
            family text,
            url text,
            size numeric(1) NOT NULL DEFAULT 1,
            slice text NOT NULL,
            is_closed numeric(1) NOT NULL DEFAULT 0,
            has_echo numeric(1) NOT NULL DEFAULT 1,
            has_flaggedrevs numeric(1) NOT NULL DEFAULT 0,
            has_visualeditor numeric(1) NOT NULL DEFAULT 0,
            has_wikidata numeric(1) NOT NULL DEFAULT 0,
            is_sensitive numeric(1) NOT NULL DEFAULT 0);
            """)

    ops.write_execute("""CREATE OR REPLACE VIEW meta_p.legacy AS
        SELECT dbname, lang, family, NULL AS domain, size, 0 AS is_meta,
               is_closed, 0 AS is_multilang, (family='wiktionary') AS is_sensitive,
               NULL AS root_category, slice AS server, '/w/' AS script_path
            FROM meta_p.wiki;""")

    ops.write_execute("""CREATE TABLE IF NOT EXISTS meta_p.properties_anon_whitelist (
        pw_property varbinary(255) PRIMARY KEY);""")


def process(mediawiki_config_dir, include_databases, ops, purge):
    """
    Build meta_p database based on the WMF .dblist configuration files.

    :param mediawiki_config_dir: Directory containing .dblist configuration files.
    :param include_databases: List of databases (e.g. 'enwiki') to update/insert
                              into the meta_p database. Can be None to include all
                              databases available in all.dblist.
    :param ops: The Operations object to execute SQL statements on.
    :param purge: True to TRUNCATE the meta_p database before inserting.
    """
    db_metadata = collect_metadata(mediawiki_config_dir, include_databases)
    update_metadata_with_siteinfo(db_metadata, mediawiki_config_dir)

    build_database(ops, purge, db_metadata)


def build_database(ops, purge, db_metadata):
    """
    Send SQL commands to build meta_p database using data from the `db_metadata` dict.

    :param ops: The Operations object to execute SQL statements on.
    :param purge: True to TRUNCATE the meta_p database before inserting.
    :param db_metadata: Dictionary with metadata, in the format
                        {'dbname': {'metadata key': 'metadata value'}}
    """
    seed_schema(ops)
    ops.write_execute("START TRANSACTION;")
    if purge:
        ops.write_execute("TRUNCATE meta_p.wiki;")
    for db, dbInfo in db_metadata.items():
        logging.debug("update meta_p for {}".format(db))
        if 'deleted' in dbInfo and dbInfo['deleted']:
            continue
        elif 'private' in dbInfo and dbInfo['private']:
            continue
        # TODO: wikitech breaks here
        elif 'slice' not in dbInfo:
            continue

        fields = {
            'has_flaggedrevs': int('has_flaggedrevs' in dbInfo and dbInfo['has_flaggedrevs']),
            'has_visualeditor': int('has_visualeditor' in dbInfo and dbInfo['has_visualeditor']),
            'has_wikidata': int('has_wikidata' in dbInfo and dbInfo['has_wikidata']),
            'is_closed': int('closed' in dbInfo and dbInfo['closed']),
            'is_sensitive': int('sensitive' in dbInfo and dbInfo['sensitive']),
            'lang': 'en',
            'size': 1,
            'dbname': db,
            'slice': dbInfo['slice'] + '.labsdb',
            'url': None,
            'family': None,
            'name': None
        }

        if 'url' in dbInfo:
            fields['url'] = dbInfo['url']
        if 'family' in dbInfo:
            fields['family'] = dbInfo['family']
        if 'lang' in dbInfo:
            fields['lang'] = dbInfo['lang']
        if 'name' in dbInfo:
            fields['name'] = force_to_unicode(dbInfo['name'])
        if 'size' in dbInfo:
            fields['size'] = dbInfo['size']

        ops.write_execute("""INSERT INTO meta_p.wiki
             (dbname, lang, name, family,
              url, size, slice, is_closed,
              has_flaggedrevs, has_visualeditor, has_wikidata,
              is_sensitive)
              VALUES
              ('%(dbname)s',
              '%(lang)s',
              '%(name)s',
              '%(family)s',
              '%(url)s',
              %(size)s,
              '%(slice)s',
              %(is_closed)s,
              %(has_flaggedrevs)s,
              %(has_visualeditor)s,
              %(has_wikidata)s,
              %(is_sensitive)s)
              ON DUPLICATE KEY UPDATE
              dbname='%(dbname)s',
              lang='%(lang)s',
              name='%(name)s',
              family='%(family)s',
              url='%(url)s',
              size=%(size)s,
              slice='%(slice)s',
              is_closed=%(is_closed)s,
              has_flaggedrevs=%(has_flaggedrevs)s,
              has_visualeditor=%(has_visualeditor)s,
              has_wikidata=%(has_wikidata)s,
              is_sensitive=%(is_sensitive)s;""" % fields)
    ops.write_execute("COMMIT;")
    ops.write_execute("START TRANSACTION;")
    ops.write_execute("DELETE FROM meta_p.properties_anon_whitelist;")
    # This is hardcoded for now
    ops.write_execute("""INSERT INTO meta_p.properties_anon_whitelist
        VALUES ('gadget-%'), ('language'), ('skin'), ('variant');""")
    ops.write_execute("COMMIT;")


def update_metadata_with_siteinfo(dbs, mediawiki_config_dir):
    initialise_settings = '{}/wmf-config/InitialiseSettings.php'.format(mediawiki_config_dir)
    canonical = parse_php_canonical(initialise_settings)
    for db, dbInfo in dbs.items():
        logging.debug("collecting action api info for {}".format(db))
        if 'private' in dbInfo and dbInfo['private']:
            continue

        elif 'deleted' in dbInfo and dbInfo['deleted']:
            continue

        if db in canonical:
            url = canonical[db]
        else:
            matches = re.match("^(.*)(wik[it].*)", db)
            lang = matches.group(1)
            url = canonical[dbInfo['family']].replace('$lang', lang)

        if url:
            canon = url.replace('_', '-')
            dbInfo['url'] = canon
            try:
                url_tail = "/w/api.php?action=query&meta=siteinfo&siprop=general&format=json"
                header = {"User-Agent": "Labsdb maintain-meta_p.py"}
                r = requests.get(canon + url_tail, headers=header)
                request = r.content
                siteinfo = json.loads(request)
                name = force_to_unicode(siteinfo['query']['general']['sitename'])
                lang = force_to_unicode(siteinfo['query']['general']['lang'])
                dbInfo['name'] = name
                dbInfo['lang'] = lang
            except Exception as e:
                logging.warning('failed request for {}: {}'.format(canon, e))


def collect_metadata(mediawiki_config_dir, include_databases):
    alldbs = '{}/dblists/all.dblist'.format(mediawiki_config_dir)
    dbs = {db: {"has_visualeditor": True}
           for db in open(alldbs).read().splitlines()}

    if include_databases:
        dbs = {k: v for k, v in dbs.iteritems() if k in include_databases}

    def read_list(fname, prop, val):
        fpath = os.path.join(
            mediawiki_config_dir, 'dblists', '{}.dblist'.format(fname))
        if os.path.isfile(fpath):
            for db in open(fpath).read().splitlines():
                if db in dbs:
                    dbs[db][prop] = val
        else:
            logging.warning('DBList "%s" not found', fpath)

    read_list("closed", "closed", True)
    read_list("deleted", "deleted", True)
    read_list("small", "size", 1)
    read_list("medium", "size", 2)
    read_list("large", "size", 3)
    read_list("private", "private", True)
    read_list("special", "family", "special")
    read_list("flaggedrevs", "has_flaggedrevs", True)
    read_list("visualeditor-nondefault", "has_visualeditor", False)
    read_list("wikidataclient", "has_wikidata", True)
    # TODO: labtestweb2001
    for slice in ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8']:
        read_list(slice, "slice", slice)
    for family in [
        "wikibooks",
        "wikidata",
        "wikinews",
        "wikiquote",
        "wikisource",
        "wikiversity",
        "wikivoyage",
        "wiktionary",
        "wikimania",
        "wikimedia",
        "wikipedia",
    ]:
        read_list(family, "family", family)
    # case sensitivity of titles isn't in a .dblist, nor is it
    # exposed through the API so we have to hardcode it here to match
    # what is in InitialiseSettings.php
    read_list("wiktionary", "sensitive", True)
    if 'jbowiki' in dbs:
        dbs['jbowiki']['sensitive'] = True
    return dbs


def parse_args(argv):
    argparser = argparse.ArgumentParser(
        "maintain-meta_p",
        description="Maintain metadatabase of wiki's"
    )
    group = argparser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        '--databases',
        help=("Specify database(s) to work on, instead of all. Multiple"
              " values can be given space-separated."),
        nargs="+"
    )
    group.add_argument(
        '--all-databases',
        help='Flag to run through all possible databases',
        action='store_true',
    )
    argparser.add_argument(
        "--purge",
        help=("Truncate wiki table before updating"),
        action="store_true"
    )
    argparser.add_argument(
        "--dry-run",
        help=("Give this parameter if you don't want the script to actually"
              " make changes."),
        action="store_true"
    )
    # piggyback on maintain-views for now
    argparser.add_argument(
        "--config-location",
        help="Path to find the configuration file",
        default="/etc/maintain-views.yaml"
    )
    argparser.add_argument(
        "--mediawiki-config",
        help=("Specify path to mediawiki-config checkout"
              " values can be given space-separated."),
        default="/usr/local/lib/mediawiki-config"
    )
    argparser.add_argument(
        "--mysql-socket",
        help=("Path to MySQL socket file"),
        default="/run/mysqld/mysqld.sock"
    )
    argparser.add_argument(
        '--debug',
        help='Turn on debug logging',
        action='store_true'
    )
    args = argparser.parse_args(argv)
    logging.basicConfig(
        format='%(asctime)s %(levelname)s %(message)s',
        level=logging.DEBUG if args.debug or args.dry_run else logging.INFO,
    )
    logging.debug(args)
    return args


def load_mysql_config(config_location):
    with open(config_location, 'r') as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as exc:
            logging.critical(exc)
            sys.exit(1)


def build_mysql_ops(config, mysql_socket):
    dbh = pymysql.connect(
        user=config["mysql_user"],
        passwd=config["mysql_password"],
        unix_socket=mysql_socket,
        charset="utf8"
    )
    return SchemaOperations(dbh, dbh.cursor())


def main(process=process):
    args = parse_args(sys.argv[1:])

    if args.dry_run:
        ops = DrySchemaOperations()
    else:
        ops = build_mysql_ops(
            load_mysql_config(args.config_location),
            args.mysql_socket)

    process(
        mediawiki_config_dir=args.mediawiki_config,
        include_databases=args.databases,
        ops=ops,
        purge=args.purge
    )


if __name__ == '__main__':
    main()
