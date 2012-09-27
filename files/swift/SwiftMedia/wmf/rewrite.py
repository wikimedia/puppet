# Portions Copyright (c) 2010 OpenStack, LLC.
# Everything else Copyright (c) 2011 Wikimedia Foundation, Inc.
# all of it licensed under the Apache Software License, included by reference.

# unit test is in test_rewrite.py. Tests are referenced by numbered comments.

import webob
import webob.exc
import re
from eventlet.green import urllib2
import wmf.client
import time
import urlparse
from swift.common.utils import get_logger
from swift.common.wsgi import WSGIContext

# Copy2 is hairy. If we were only opening a URL, and returning it, we could
# just return the open file handle, and webob would take care of reading from
# the socket and returning the data to the client machine. If we were only
# opening a URL and writing its contents out to Swift, we could call
# put_object with the file handle and it would take care of reading from
# the socket and writing the data to the Swift proxy.
#     We have to do both at the same time. This requires that we hand over a class which
# is an iterable which reads, writes one copy to Swift (using put_object_chunked), and
# returns a copy to webob.  This is controlled by write_thumbs in /etc/swift/proxy.conf,

class Copy2(object):
    """
    Given an open file and a Swift object, we hand back an iterator which
    reads from the file, writes a copy into a Swift object, and returns
    what it read.
    """
    token = None

    def __init__(self, conn, app, url, container, obj, authurl, login, key,
            content_type=None, modified=None, content_length=None):
        self.app = app
        self.conn = conn
        if self.token is None:
            (account, self.token) = wmf.client.get_auth(authurl, login, key)
        if modified is not None:
            # The issue here is that we need to keep the timestamp between the
            # thumb server and us. The Migration-Timestamp header was in 1.2,
            # but was deprecated. They likely have a different solution for
            # setting the timestamp on an uploaded file.
            h = {'!Migration-Timestamp!': '%s' % modified}
        else:
            h = {}

        if content_length is not None:
            h['Content-Length'] = content_length

        full_headers = conn.info()
        etag = full_headers.getheader('ETag')
        self.copyconn = wmf.client.Put_object_chunked(url, self.token,
                container, obj, etag=etag, content_type=content_type, headers=h)

    def __iter__(self):
        # We're an iterator; we get passed back to wsgi as a consumer.
        return self

    def next(self):
        # We read from the thumb server, write out to Swift, and return it.
        data = self.conn.read(4096)
        if not data:
            # if we get a 401 error, it's okay, but we should re-auth.
            try:
                self.copyconn.close() #06 or #04 if it fails.
            except wmf.client.ClientException, err:
                if err.http_status == 401:
                    # not worth retrying the write. Thumb will get saved
                    # the next time.
                    self.token = None
                else:
                    raise
            raise StopIteration
        self.copyconn.write(data)
        return data

class WMFRewrite(WSGIContext):
    """
    Rewrite Media Store URLs so that swift knows how to deal.

    Mostly it's a question of inserting the AUTH_ string, and changing / to - in the container section.
    """

    def __init__(self, app, conf):
        def striplist(l):
            return([x.strip() for x in l])
        self.app = app
        self.account = conf['account'].strip()
        self.authurl = conf['url'].strip()
        self.login = conf['login'].strip()
        self.key = conf['key'].strip()
        self.thumbhost = conf['thumbhost'].strip()
        self.user_agent = conf['user_agent'].strip()
        self.bind_port = conf['bind_port'].strip()
        self.shard_containers = conf['shard_containers'].strip() #all, some, none
        if (self.shard_containers == 'some'):
            # if we're supposed to shard some containers, get a cleaned list of the containers to shard
            self.shard_container_list = striplist(conf['shard_container_list'].split(','))
        self.write_thumbs = conf['write_thumbs'].strip() #all, most, none
        if (self.write_thumbs == 'most'):
            # if we're supposed to write thumbs for most containers, get a cleaned list of the containers to which we DON'T write
            self.dont_write_thumb_list = striplist(conf['dont_write_thumb_list'].split(','))
        # this parameter controls whether URLs sent to the thumbhost are sent as is (eg. upload/proj/lang/) or with the site/lang
        # converted  and only the path sent back (eg en.wikipedia/thumb).
        self.backend_url_format = conf['backend_url_format'].strip() #'asis', 'sitelang'

        self.logger = get_logger(conf)

    def handle404(self, reqorig, url, container, obj):
        """
        Return a webob.Response which fetches the thumbnail from the thumb
        host, potentially writes it out to Swift so we don't 404 next time,
        and returns it. Note also that the thumb host might write it out
        to Swift so we don't have to.
        """
        # go to the thumb media store for unknown files
        reqorig.host = self.thumbhost
        # upload doesn't like our User-agent, otherwise we could call it
        # using urllib2.url()
        proxy_handler = urllib2.ProxyHandler({'http': self.thumbhost})
        opener = urllib2.build_opener(proxy_handler)
        # Pass on certain headers from the caller squid to the scalers
        opener.addheaders = []
        if reqorig.headers.get('User-Agent') != None:
            opener.addheaders.append(('User-Agent', reqorig.headers.get('User-Agent')))
        else:
            opener.addheaders.append(('User-Agent', self.user_agent))
        for header_to_pass in ['X-Forwarded-For', 'X-Original-URI']:
            if reqorig.headers.get( header_to_pass ) != None:
                opener.addheaders.append((header_to_pass, reqorig.headers.get( header_to_pass )))
        # At least in theory, we shouldn't be handing out links to originals
        # that we don't have (or in the case of thumbs, can't generate).
        # However, someone may have a formerly valid link to a file, so we
        # should do them the favor of giving them a 404.
        try:
            # break apach the url, url-encode it, and put it back together
            urlobj = list(urlparse.urlsplit(reqorig.url))
            # encode the URL but don't encode %s and /s
            urlobj[2] = urllib2.quote(urlobj[2], '%/')
            encodedurl = urlparse.urlunsplit(urlobj)

            # if sitelang, we're supposed to mangle the URL so that
            # http://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Little_kitten_.jpg/330px-Little_kitten_.jpg
            # changes to
            # http://commons.wikipedia.org/thumb/a/a2/Little_kitten_.jpg/330px-Little_kitten_.jpg
            if self.backend_url_format == 'sitelang':
                match = re.match(r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)', encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    # and here are all the legacy special cases, imported from thumb_handler.php
                    if(proj == 'wikipedia'):
                        if(lang in ['meta', 'commons', 'internal', 'grants', 'wikimania2006']):
                            proj = 'wikimedia'
                        if(lang in ['mediawiki']):
                            lang = 'www'
                            proj = 'mediawiki'
                    hostname = '%s.%s.org' % (lang, proj)
                    if(proj == 'wikipedia' and lang == 'sources'):
                        #yay special case
                        hostname = 'wikisource.org'
                    # ok, replace the URL with just the part starting with thumb/
                    # take off the first two parts of the path (eg /wikipedia/commons/); make sure the string starts with a /
                    encodedurl = 'http://%s/w/thumb_handler.php/%s' % (hostname, match.group('path'))
                    # add in the X-Original-URI with the swift got (minus the hostname)
                    opener.addheaders.append(('X-Original-URI', list(urlparse.urlsplit(reqorig.url))[2]))
                else:
                    # ASSERT this code should never be hit since only thumbs should call the 404 handler
                    self.logger.warn("non-thumb in 404 handler! encodedurl = %s" % encodedurl)
                    resp = webob.exc.HTTPNotFound('Unexpected error')
                    return resp
            else:
                # log the result of the match here to test and make sure it's sane before enabling the config
                match = re.match(r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)', encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    self.logger.warn("sitelang match has proj %s lang %s encodedurl %s" % (proj, lang, encodedurl))
                else:
                    self.logger.warn("no sitelang match on encodedurl: %s" % encodedurl)


            # ok, call the encoded url
            upcopy = opener.open(encodedurl)

        except urllib2.HTTPError,status:
            if status.code == 404:
                resp = webob.exc.HTTPNotFound('Expected original file not found')
                return resp
            else:
                resp = webob.exc.HTTPNotFound('Unexpected error %s' % status)
                resp.body = "".join(status.readlines())
                resp.status = status.code
                return resp

        # get the Content-Type.
        uinfo = upcopy.info()
        c_t = uinfo.gettype()
        content_length = uinfo.getheader('Content-Length', None)
        # sometimes Last-Modified isn't present; use now() when that happens.
        try:
            last_modified = time.mktime(uinfo.getdate('Last-Modified'))
        except TypeError:
            last_modified = time.mktime(time.localtime())

        # are we suposed to write thumbs for this container? (if most, is the container minus the shard in the list?)
        if ((self.write_thumbs == 'none') or (self.write_thumbs == 'most' and container.split('.',1)[0] in self.dont_write_thumb_list)):
            writethumb = False
        else:
            writethumb = True

        if writethumb and reqorig.method != 'HEAD':
            # Fetch from upload, write into the cluster, and return it
            upcopy = Copy2(upcopy, self.app, url,
                urllib2.quote(container), obj, self.authurl, self.login,
                self.key, content_type=c_t, modified=last_modified,
                content_length=content_length)


        resp = webob.Response(app_iter=upcopy, content_type=c_t)
        # add in the headers if we've got them
        for header in ['Content-Length', 'Content-Disposition', 'Last-Modified', 'Accept-Ranges']:
            if(uinfo.getheader(header)):
                resp.headers.add(header, uinfo.getheader(header))
        return resp

    def __call__(self, env, start_response):
        req = webob.Request(env)
        # End-users should only do GET/HEAD, nothing else needs a rewrite
        if req.method != 'GET' and req.method != 'HEAD':
            return self.app(env, start_response)

        # Double (or triple, etc.) slashes in the URL should be ignored; collapse them. fixes bug 32864
        req.path_info = re.sub( r'/{2,}', '/', req.path_info )

        # If it already has AUTH, presume that it's good. #07. (bug 33620)
        hasauth = re.search('/AUTH_[0-9a-fA-F-]{32,36}', req.path)
        if req.path.startswith('/auth') or hasauth:
            return self.app(env, start_response)

        # Keep a copy of the original request so we can ask the scalers for it
        reqorig = req.copy()

        # Containers have 5 components: project, language, repo, zone, and shard.
        # If there's no zone in the URL, the zone is assumed to be 'public' (for b/c).
        # Shard is optional (and configurable), and is only used for large containers.
        #
        # Projects are wikipedia, wikinews, etc.
        # Languages are en, de, fr, commons, etc.
        # Repos are local, timeline, etc.
        # Zones are public, thumb, temp, etc.
        # Shard is extracted from "hash paths" in the URL and is 2 hex digits.
        #
        # These attributes are mapped to container names in the form of either:
        # (a) proj-lang-repo-zone (if not sharded)
        # (b) proj-lang-repo-zone.shard (if sharded)
        # (c) global-data-repo-zone (if not sharded)
        # (d) global-data-repo-zone.shard (if sharded)
        #
        # Rewrite wiki-global URLs of these forms:
        # (a) http://upload.wikimedia.org/math/.*
        #         => http://msfe/v1/AUTH_<hash>/global-data-math-render/.*
        #
        # Rewrite wiki-relative URLs of these forms:
        # (a) http://upload.wikimedia.org/<proj>/<lang>/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/<relpath>
        # (b) http://upload.wikimedia.org/<proj>/<lang>/archive/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/archive/<relpath>
        # (c) http://upload.wikimedia.org/<proj>/<lang>/thumb/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/<relpath>
        # (d) http://upload.wikimedia.org/<proj>/<lang>/thumb/archive/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/archive/<relpath>
        # (e) http://upload.wikimedia.org/<proj>/<lang>/thumb/temp/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/temp/<relpath>
        # (f) http://upload.wikimedia.org/<proj>/<lang>/temp/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-temp/<relpath>
        # (g) http://upload.wikimedia.org/<proj>/<lang>/timeline/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-timeline-render/<relpath>

        # regular uploads
        match = re.match(r'^/(?P<proj>[^/]+)/(?P<lang>[^/]+)/((?P<zone>thumb|temp)/)?(?P<path>((temp|archive)/)?[0-9a-f]/(?P<shard>[0-9a-f]{2})/.+)$', req.path)
        if match:
            proj  = match.group('proj')
            lang  = match.group('lang')
            repo  = 'local' # the upload repo name is "local"
            # Get the repo zone (if not provided that means "public")
            zone  = (match.group('zone') if match.group('zone') else 'public')
            # Get the object path relative to the zone (and thus container)
            obj   = match.group('path') # e.g. "archive/a/ab/..."
            shard = match.group('shard')

        # timeline renderings
        if match is None:
            # /wikipedia/en/timeline/a876297c277d80dfd826e1f23dbfea3f.png
            match = re.match(r'^/(?P<proj>[^/]+)/(?P<lang>[^/]+)/(?P<repo>timeline)/(?P<path>.+)$', req.path)
            if match:
                proj = match.group('proj') # wikipedia
                lang = match.group('lang') # en
                repo = match.group('repo') # timeline
                zone = 'render'
                obj  = match.group('path') # a876297c277d80dfd826e1f23dbfea3f.png

        # math renderings
        if match is None:
            # /math/c/9/f/c9f2055dadfb49853eff822a453d9ceb.png
            match = re.match(r'^/(?P<repo>math)/(?P<path>(?P<shard1>[0-9a-f])/(?P<shard2>[0-9a-f])/.+)$', req.path)
            if match:
                proj  = 'global'
                lang  = 'data'
                repo  = match.group('repo') # math
                zone  = 'render'
                obj   = match.group('path') # c/9/f/c9f2055dadfb49853eff822a453d9ceb.png
                shard = match.group('shard1') + match.group('shard2') # c9

        # Internally rewrite the URL based on the regex it matched...
        if match:
            # Get the per-project "conceptual" container name, e.g. "<proj><lang><repo><zone>"
            container = "%s-%s-%s-%s" % (proj, lang, repo, zone) #02/#03
            # Add 2-digit shard to the container if it is supposed to be sharded.
            # We may thus have an "actual" container name like "<proj><lang><repo><zone>.<shard>"
            if ( (self.shard_containers == 'all') or \
                 ((self.shard_containers == 'some') and (container in self.shard_container_list)) ):
                container += ".%s" % shard

            # Save a url with just the account name in it.
            req.path_info = "/v1/%s" % (self.account)
            port = self.bind_port
            req.host = '127.0.0.1:%s' % port
            url = req.url[:]
            # Create a path to our object's name.
            req.path_info = "/v1/%s/%s/%s" % (self.account, container, urllib2.unquote(obj))
            #self.logger.warn("new path is %s" % req.path_info)

            # do_start_response just remembers what it got called with,
            # because our 404 handler will generate a different response.
            app_iter = self._app_call(env) #01
            status = self._get_status_int()
            headers = self._response_headers

            if 200 <= status < 300 or status == 304:
                # We have it! Just return it as usual.
                if 'etag' in headers:
                    del headers['etag']
                return webob.Response(status=status, headers=headers,
                        app_iter=app_iter)(env, start_response) #01a
            elif status == 404: #4
                # only send thumbs to the 404 handler; just return a 404 for everything else.
                if repo == 'local' and zone == 'thumb':
                    resp = self.handle404(reqorig, url, container, obj)
                    return resp(env, start_response)
                else:
                    resp = webob.exc.HTTPNotFound('File not found: %s' % req.path)
                    return resp(env, start_response)
            elif status == 401:
                # if the Storage URL is invalid or has expired we'll get this error.
                resp = webob.exc.HTTPUnauthorized('Token may have timed out') #05
                return resp(env, start_response)
            else:
                resp = webob.exc.HTTPNotImplemented('Unknown Status: %s' % (status)) #10
                return resp(env, start_response)
        else:
            resp = webob.exc.HTTPNotFound('Regexp failed to match URI: "%s"' % (req.path)) #11
            return resp(env, start_response)

def filter_factory(global_conf, **local_conf):
    conf = global_conf.copy()
    conf.update(local_conf)

    def wmfrewrite_filter(app):
        return WMFRewrite(app, conf)
    return wmfrewrite_filter

# vim: set expandtab tabstop=4 shiftwidth=4 autoindent:

