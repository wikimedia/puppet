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

    # Real zones mapping 1:1 to the same file in templates/zones/
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
        'mediawiki.org',
        'toolserver.org',
        'wikibooks.org',
        'wikidata.org',
        'wikimania.org',
        'wikimedia.com',
        'wikimedia.community',
        'wikimedia.ee',
        'wikimediafoundation.org',
        'wikimedia.org',
        'wikinews.org',
        'wikipedia.org',
        'wikiquote.org',
        'wikisource.org',
        'wikiversity.org',
        'wikivoyage-old.org',
        'wikivoyage.org',
        'wiktionary.org',
        'wmftest.org',
        'wmfusercontent.org',
        'wmnet',
        'w.wiki',
    ]

    # templates re-used for aliased zones.  The template-name can be one of the
    # real $zone_files above, (no alias-to-self should be listed here).
    $zone_aliases = {
        'mediawiki.org' => {
            aliases => [
                'mediawiki.com',
            ],
        },
        'parking' => {
            aliases => [
                'border-wikipedia.de',
                'donatetowikipedia.com',
                'donatetowikipedia.org',
                'indiawikipedia.com',
                'softwarewikipedia.com',
                'softwarewikipedia.net',
                'softwarewikipedia.org',
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
                'wikidata.pt',
                'wikidisclosure.com',
                'wikidisclosure.org',
                'wikidpedia.org',
                'wikiepdia.com',
                'wikiepdia.org',
                'wikifamily.com',
                'wikifamily.org',
                'wikimania.asia',
                'wikimaps.com',
                'wikimaps.net',
                'wikimaps.org',
                'wikimedia.biz',
                'wikimediacommons.co.uk',
                'wikimediacommons.info',
                'wikimediacommons.jp.net',
                'wikimediacommons.mobi',
                'wikimediacommons.net',
                'wikimediacommons.org',
                'wikimediastories.com',
                'wikimediastories.net',
                'wikimediastories.org',
                'wikimedia.xyz',
                'wikimemory.net',
                'wikimemory.org',
                'wikimobipedia.com',
                'wikimobipedia.net',
                'wikipaedia.net',
                'wikipedia.com.ar',
                'wikipedia.co.uk',
                'wikipedia.es',
                'wikipedia.lol',
                'wikipedial.org',
                'wiki-pedia.org',
                'wikipedia.sk',
                'wikipediastats.com',
                'wikipediastats.net',
                'wikipediastats.org',
                'wikipediastories.com',
                'wikipediastories.net',
                'wikipediastories.org',
                'wikipediavideos.com',
                'wikiquote.pl',
                'wikiquotes.info',
                'wiki.voyage',
                'wikjpedia.org',
                'wiktionary.pl',
                'wilkipedia.org',
                'xn--80adgdym4pbd.xn--j1amh',
                'xn--80adgfman1aa4l.xn--p1ai',
                'xn--b1aajamacm1dkmb.xn--p1ai',
            ],
        },
        'wikibooks.org' => {
            aliases => [
                'wikibook.com',
                'wikibooks.com',
                'wikibooks.cz',
                'wikibooks.pt',
            ],
        },
        'wikimania.org' => {
            aliases => [
                'wikimania.com',
            ],
        },
        'wikimedia.com' => {
            aliases => [
                'wikicitaty.cz',
                'wikidruhy.cz',
                'wikijunior.com',
                'wikijunior.net',
                'wikijunior.org',
                'wikiknihy.cz',
                'wikimedia.com.pt',
                'wikimedia.is',
                'wikimedia.jp.net',
                'wikimedia.lt',
                'wikimedia.us',
                'wikislovnik.cz',
                'wikispecies.com',
                'wikispecies.cz',
                'wikispecies.net',
                'wikispecies.org',
                'wikizdroje.cz',
                'wikizpravy.cz',
            ],
        },
        'wikimediafoundation.org' => {
            aliases => [
                'wikimediafoundation.com',
                'wikimediafoundation.info',
                'wikimediafoundation.net',
                'wikipediazero.org',
            ],
        },
        'wikinews.org' => {
            aliases => [
                'wikinews.com',
                'wikinews.de',
                'wikinews.pt',
            ],
        },
        'wikipedia.org' => {
            aliases => [
                'en-wp.com',
                'en-wp.org',
                'wikiipedia.org',
                'wikipedia.bg',
                'wikipedia.co.il',
                'wikipedia.com',
                'wikipedia.co.za',
                'wikipedia.cz',
                'wikipedia.ee',
                'wikipedia.id',
                'wikipedia.in',
                'wikipedia.info',
                'wikipedia.is',
                'wikipedia.lt',
                'wikipedia.net',
                'wikipedia.org.il',
                'wikipedie.cz',
                'wikpedia.org',
            ],
        },
        'wikiquote.org' => {
            aliases => [
                'wikiquote.com',
                'wikiquote.cz',
                'wikiquote.net',
                'wikiquote.pt',
            ],
        },
        'wikisource.org' => {
            aliases => [
                'wikisource.com',
                'wikisource.pl',
                'wikisource.pt',
            ],
        },
        'wikiversity.org' => {
            aliases => [
                'wikiversity.com',
                'wikiversity.cz',
                'wikiversity.pt',
                'wikiverzita.cz',
            ],
        },
        'wikivoyage.org' => {
            aliases => [
                'wikivoyage.com',
                'wikivoyage.de',
                'wikivoyage.eu',
                'wikivoyage.net',
                'wikivoyager.de',
                'wikivoyager.org',
            ],
        },
        'wiktionary.org' => {
            aliases => [
                'wiktionary.com',
                'wiktionary.cz',
                'wiktionary.eu',
                'wiktionary.pt',
            ],
        },
        'wmftest.org' => {
            aliases => [
                'wmftest.com',
                'wmftest.net',
            ],
        },
    }

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
<% end -%>')

    $geolang_zero = inline_template('<% @langs.each do |lang| -%>
<%= lang %>              600 IN DYNA    geoip!text-addrs
<%= lang %>.m            600 IN DYNA    geoip!text-addrs
<%= lang %>.zero         600 IN DYNA    geoip!text-addrs
<% end -%>')

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
    create_resources(::authdns::zonealiases, $zone_aliases, { destdir => $staging_zones })
}
