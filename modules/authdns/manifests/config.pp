class authdns::config {
    ## DATA

    $staging_root  = '/srv/authdns'
    $staging_dir   = "${staging_root}/staging-puppet" # managed, but not copied
    $staging_etc   = "${staging_dir}/etc"             # -> /etc/gdnsd/
    $staging_zones = "${staging_etc}/zones"           # -> /etc/gdnsd/zones/
    $staging_var   = "${staging_dir}/var"             # -> /var/lib/gdnsd/

    $managed_dirs = [
        $staging_dir,
        $staging_etc,
        $staging_zones,
        $staging_var,
    ]

    $config_templates = [
        'config',
        'discovery-geo-resources',
        'discovery-metafo-resources',
        'discovery-states',
    ]

    $config_files = [
        'discovery-map',
        'geo-map',
        'geo-resources',
    ]

    $var_files = [
        'admin_state'
    ]

    $zone_files = [
        '0.6.8.0.0.0.0.0.0.2.6.2.ip6.arpa',
        '0.8.c.e.2.0.a.2.ip6.arpa',
        '10.in-addr.arpa',
        '152.80.208.in-addr.arpa',
        '153.80.208.in-addr.arpa',
        '154.80.208.in-addr.arpa',
        '155.80.208.in-addr.arpa',
        '1.6.8.0.0.0.0.0.0.2.6.2.ip6.arpa',
        '174.198.91.in-addr.arpa',
        '26.35.198.in-addr.arpa',
        '2.6.8.0.0.0.0.0.0.2.6.2.ip6.arpa',
        '27.35.198.in-addr.arpa',
        '3.6.8.0.0.0.0.0.0.2.6.2.ip6.arpa',
        '56.15.185.in-addr.arpa',
        '57.15.185.in-addr.arpa',
        '58.15.185.in-addr.arpa',
        '59.15.185.in-addr.arpa',
        'border-wikipedia.de',
        'donatetowikipedia.com',
        'donatetowikipedia.org',
        'en-wp.com',
        'en-wp.org',
        'indiawikipedia.com',
        'mediawiki.com',
        'mediawiki.org',
        'parking',
        'softwarewikipedia.com',
        'softwarewikipedia.net',
        'softwarewikipedia.org',
        'toolserver.org',
        'vikipedia.com.tr',
        'vikipedi.com.tr',
        'visualwikipedia.com',
        'visualwikipedia.net',
        'voyagewiki.com',
        'voyagewiki.org',
        'webhostingwikipedia.com',
        'wekipedia.com',
        'wicipediacymraeg.org',
        'wiikipedia.com',
        'wikiartpedia.biz',
        'wikiartpedia.co',
        'wikiartpedia.info',
        'wikiartpedia.me',
        'wikiartpedia.mobi',
        'wikiartpedia.net',
        'wikiartpedia.org',
        'wikibook.com',
        'wikibooks.com',
        'wikibooks.cz',
        'wikibooks.org',
        'wikibooks.pt',
        'wikicitaty.cz',
        'wikidata.org',
        'wikidata.pt',
        'wikidisclosure.com',
        'wikidisclosure.org',
        'wikidpedia.org',
        'wikidruhy.cz',
        'wikiepdia.com',
        'wikiepdia.org',
        'wikifamily.com',
        'wikifamily.org',
        'wikiipedia.org',
        'wikijunior.com',
        'wikijunior.net',
        'wikijunior.org',
        'wikiknihy.cz',
        'wikimania.asia',
        'wikimania.com',
        'wikimania.org',
        'wikimaps.com',
        'wikimaps.net',
        'wikimaps.org',
        'wikimedia.biz',
        'wikimedia.com',
        'wikimediacommons.co.uk',
        'wikimediacommons.info',
        'wikimediacommons.jp.net',
        'wikimediacommons.mobi',
        'wikimediacommons.net',
        'wikimediacommons.org',
        'wikimedia.community',
        'wikimedia.com.pt',
        'wikimedia.ee',
        'wikimediafoundation.com',
        'wikimediafoundation.info',
        'wikimediafoundation.net',
        'wikimediafoundation.org',
        'wikimedia.is',
        'wikimedia.jp.net',
        'wikimedia.lt',
        'wikimedia.org',
        'wikimediastories.com',
        'wikimediastories.net',
        'wikimediastories.org',
        'wikimedia.us',
        'wikimedia.xyz',
        'wikimemory.net',
        'wikimemory.org',
        'wikimobipedia.com',
        'wikimobipedia.net',
        'wikinews.com',
        'wikinews.de',
        'wikinews.org',
        'wikinews.pt',
        'wikipaedia.net',
        'wikipedia.bg',
        'wikipedia.co.il',
        'wikipedia.com',
        'wikipedia.com.ar',
        'wikipedia.co.uk',
        'wikipedia.co.za',
        'wikipedia.cz',
        'wikipedia.ee',
        'wikipedia.es',
        'wikipedia.id',
        'wikipedia.in',
        'wikipedia.info',
        'wikipedia.is',
        'wikipedia.lol',
        'wikipedial.org',
        'wikipedia.lt',
        'wikipedia.net',
        'wiki-pedia.org',
        'wikipedia.org',
        'wikipedia.org.il',
        'wikipedia.sk',
        'wikipediastats.com',
        'wikipediastats.net',
        'wikipediastats.org',
        'wikipediastories.com',
        'wikipediastories.net',
        'wikipediastories.org',
        'wikipediavideos.com',
        'wikipediazero.org',
        'wikipedie.cz',
        'wikiquote.com',
        'wikiquote.cz',
        'wikiquote.net',
        'wikiquote.org',
        'wikiquote.pl',
        'wikiquote.pt',
        'wikiquotes.info',
        'wikislovnik.cz',
        'wikisource.com',
        'wikisource.org',
        'wikisource.pl',
        'wikisource.pt',
        'wikispecies.com',
        'wikispecies.cz',
        'wikispecies.net',
        'wikispecies.org',
        'wikiversity.com',
        'wikiversity.cz',
        'wikiversity.org',
        'wikiversity.pt',
        'wikiverzita.cz',
        'wiki.voyage',
        'wikivoyage.com',
        'wikivoyage.de',
        'wikivoyage.eu',
        'wikivoyage.net',
        'wikivoyage-old.org',
        'wikivoyage.org',
        'wikivoyager.de',
        'wikivoyager.org',
        'wikizdroje.cz',
        'wikizpravy.cz',
        'wikjpedia.org',
        'wikpedia.org',
        'wiktionary.com',
        'wiktionary.cz',
        'wiktionary.eu',
        'wiktionary.org',
        'wiktionary.pl',
        'wiktionary.pt',
        'wilkipedia.org',
        'wmftest.com',
        'wmftest.net',
        'wmftest.org',
        'wmfusercontent.org',
        'wmnet',
        'w.wiki',
        'xn--80adgdym4pbd.xn--j1amh',
        'xn--80adgfman1aa4l.xn--p1ai',
        'xn--b1aajamacm1dkmb.xn--p1ai',
    ]

    $langs = [
        'aa',
        'ab',
        'ace',
        'ady',
        'af',
        'ak',
        'als',
        'am',
        'an',
        'ang',
        'ar',
        'arc',
        'arz',
        'as',
        'ast',
        'av',
        'ay',
        'az',
        'azb',
        'ba',
        'bar',
        'bat-smg',
        'bcl',
        'be',
        'be-tarask',
        'be-x-old',
        'bg',
        'bh',
        'bi',
        'bjn',
        'bm',
        'bn',
        'bo',
        'bpy',
        'br',
        'bs',
        'bug',
        'bxr',
        'ca',
        'cbk-zam',
        'cdo',
        'ce',
        'ceb',
        'ch',
        'cho',
        'chr',
        'chy',
        'ckb',
        'co',
        'cr',
        'crh',
        'cs',
        'csb',
        'cu',
        'cv',
        'cy',
        'cz',
        'da',
        'de',
        'diq',
        'dk',
        'dsb',
        'dv',
        'dz',
        'ee',
        'el',
        'eml',
        'en',
        'eo',
        'epo',
        'es',
        'et',
        'eu',
        'ext',
        'fa',
        'ff',
        'fi',
        'fiu-vro',
        'fj',
        'fo',
        'fr',
        'frp',
        'frr',
        'fur',
        'fy',
        'ga',
        'gag',
        'gan',
        'gd',
        'gl',
        'glk',
        'gn',
        'gom',
        'got',
        'gu',
        'gv',
        'ha',
        'hak',
        'haw',
        'he',
        'hi',
        'hif',
        'ho',
        'hr',
        'hsb',
        'ht',
        'hu',
        'hy',
        'hz',
        'ia',
        'id',
        'ie',
        'ig',
        'ii',
        'ik',
        'ilo',
        'io',
        'is',
        'it',
        'iu',
        'ja',
        'jam',
        'jbo',
        'jp',
        'jv',
        'ka',
        'kaa',
        'kab',
        'kbd',
        'kg',
        'ki',
        'kj',
        'kk',
        'kl',
        'km',
        'kn',
        'ko',
        'koi',
        'kr',
        'krc',
        'ks',
        'ksh',
        'ku',
        'kv',
        'kw',
        'ky',
        'la',
        'lad',
        'lb',
        'lbe',
        'lez',
        'lg',
        'li',
        'lij',
        'lmo',
        'ln',
        'lo',
        'lrc',
        'lt',
        'ltg',
        'lv',
        'mai',
        'map-bms',
        'mdf',
        'mg',
        'mh',
        'mhr',
        'mi',
        'min',
        'minnan',
        'mk',
        'ml',
        'mn',
        'mo',
        'mr',
        'mrj',
        'ms',
        'mt',
        'mus',
        'mwl',
        'my',
        'myv',
        'mzn',
        'na',
        'nah',
        'nan',
        'nap',
        'nb',
        'nds',
        'nds-nl',
        'ne',
        'new',
        'ng',
        'nl',
        'nn',
        'no',
        'nov',
        'nrm',
        'nso',
        'nv',
        'ny',
        'oc',
        'olo',
        'om',
        'or',
        'os',
        'pa',
        'pag',
        'pam',
        'pap',
        'pcd',
        'pdc',
        'pfl',
        'pi',
        'pih',
        'pl',
        'pms',
        'pnt',
        'pnb',
        'ps',
        'pt',
        'qu',
        'rm',
        'rmy',
        'rn',
        'ro',
        'roa-rup',
        'roa-tara',
        'ru',
        'rue',
        'rw',
        'sa',
        'sah',
        'sc',
        'scn',
        'sco',
        'sd',
        'se',
        'sg',
        'sh',
        'si',
        'simple',
        'sk',
        'sl',
        'sm',
        'sn',
        'so',
        'sq',
        'sr',
        'srn',
        'ss',
        'st',
        'stq',
        'su',
        'sv',
        'sw',
        'szl',
        'ta',
        'tcy',
        'te',
        'tet',
        'tg',
        'th',
        'ti',
        'tk',
        'tl',
        'tn',
        'to',
        'tpi',
        'tr',
        'ts',
        'tt',
        'tum',
        'tw',
        'ty',
        'tyv',
        'udm',
        'ug',
        'uk',
        'ur',
        'uz',
        've',
        'vec',
        'vep',
        'vi',
        'vls',
        'vo',
        'wa',
        'war',
        'wo',
        'wuu',
        'xal',
        'xh',
        'xmf',
        'yi',
        'yo',
        'yue',
        'za',
        'zea',
        'zh',
        'zh-cfr',
        'zh-classical',
        'zh-min-nan',
        'zh-yue',
        'zu',
    ]

    $geolang = inline_template('<% @langs.each do |lang| -%>
<%= lang %>              600 IN DYNA    geoip!text-addrs
<%= lang %>.m            600 IN DYNA    geoip!text-addrs
<% done -%>')

    $geolang_zero = inline_template('<% @langs.each do |lang| -%>
<%= lang %>              600 IN DYNA    geoip!text-addrs
<%= lang %>.m            600 IN DYNA    geoip!text-addrs
<%= lang %>.zero         600 IN DYNA    geoip!text-addrs
<% done -%>')

    ## Resources

    file { $staging_root:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { $managed_dirs:
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    authdns::template { $config_templates: destdir => $staging_etc }
    authdns::file { $config_files: destdir => $staging_etc }
    authdns::file { $var_files: destdir => $staging_var }
    authdns::zonefile { $zone_files: destdir => $staging_zones }
}
