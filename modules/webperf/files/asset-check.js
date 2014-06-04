/**
 * asset-check.js
 *
 * This is a PhantomJS script. It connects to a page specified as a
 * command-line argument and prints a JSON object containing information
 * about the number of resources requested by the page and their size.
 *
 * Requires PhantomJS <http://phantomjs.org/>.
 *
 * Usage: phantomjs asset-check.js URL
 *
 * Optional arguments:
 *   --timeout=N       specifies timeout, in seconds.
 *   --ua=USER_AGENT   set this User-Agent header.
 *   --debug           enable verbose output and avoid minification.
 *
 * Copyright (C) 2013, Ori Livneh <ori@wikimedia.org>
 * Licensed under the terms of the GPL, version 2 or later.
 */
/*global phantom */
var system = require( 'system' ),
    webpage = require( 'webpage' ),
    options = {
        debug: false,
        timeout: 30,
        ua: null
    };

function parseArgument( arg ) {
    if ( arg === '-h' || arg === '--help' ) {
        usage();
        return;
    }

    if ( arg === '--debug' ) {
        options.debug = true;
        return;
    }

    var match = /^--([^=]+)=(.*)/.exec( arg );
    if ( match ) {
        options[ match[1] ] = match[2];
    } else {
        options.url = arg;
    }
}

function usage() {
    console.error( 'Usage: phantomjs ' + system.args[ 0 ] +
        ' URL [--timeout=N] [--ua=USER_AGENT_STRING] [--debug]'
    );
    phantom.exit( 1 );
}

function countCssRules() {
    return Array.prototype.reduce.call( document.styleSheets, function ( total, styleSheet ) {
        return styleSheet.cssRules ? total + styleSheet.cssRules.length : total;
    }, 0 );
}

function checkAssets( url ) {
    var payload = {
        javascript: { requests: 0, bytes: 0 },
        html: { requests: 0, bytes: 0 },
        css: { requests: 0, bytes: 0, rules: 0 },
        image: { requests: 0, bytes: 0 },
        other: { requests: 0, bytes: 0 },
        cookies: { set: 0 },
    };

    var page = webpage.create();

    if ( options.ua ) {
        page.settings.userAgent = options.ua;
    }

    /**
     * Analyze incoming resource
     *
     * Called two or more times for every requested resource (e.g. urls and
     * resolved data uris). Once with stage="start", once with stage="end", and
     * potentially zero or more times for individual chunks if the server
     * sent data in multiple chunks.
     *
     * @param {Object} res
     */
    page.onResourceReceived = function ( res ) {
        var match = /javascript|html|css|image/i.exec( res.contentType ) || [ 'other' ],
            type = match[0],
            resource = payload[ type ];

        if ( res.stage == 'end' && !/^data:/.test( res.url ) ) {
            resource.requests++;
            if ( res.bodySize ) {
                resource.bytes += res.bodySize;
            }
        }
    };

    // Print network report
    page.onLoadFinished = function () {
        payload.cookies.set = page.cookies.length;
        payload.css.rules = page.evaluate( countCssRules );
        if ( options.debug ) {
            console.log( JSON.stringify( payload, null, '\t' ) );
        } else {
            console.log( JSON.stringify( payload ) );
        }
        phantom.exit( 0 );
    };

    // Abort if 30 seconds elapsed and the page hasn't finished loading
    setTimeout( function () {
        console.error( 'Timed out after ' + options.timeout + ' seconds.' );
        phantom.exit( 1 );
    }, ( options.timeout * 1000 ) );

    page.open( url );

    // Page is locked to the specified URL
    page.navigationLocked = true;
}

system.args.slice( 1 ).forEach( parseArgument );
if ( Object.keys( options ).sort().join(' ') !== 'debug timeout ua url' ) {
    usage();
} else {
    checkAssets( options.url );
}
