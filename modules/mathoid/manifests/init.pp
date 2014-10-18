# == Class: mathoid
#
# Mathoid is an application which takes various forms of math input and
# converts it to MathML + SVG output. It is a web-service implemented
# in node.js.
#
# === Parameters
#
# [*svg_generation*]
#   Enable SVG generation
# [*img_generation*]
#   Enable IMG generation.
# [*png_generation*]
#   Enable PNG generation. This is done via shelling out to Java and temporary
#   files, so it might be insecure.
# [*speakText_generation*]
#   Enable speakText generation.
#
class mathoid(
    $svg_generation=true,
    $img_generation=true,
    $png_generation=false,
    $speakText=false,
) {

    # Pending fix for <https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=742347>
    # require_package('node-jsdom')

    $require = undef
    if $png_generation {
        require_package('openjdk-7-jre-headless')
        $require = Package['openjdk-7-jre-headless']
    }

    service::node { 'mathoid':
        port            => 10042,
        config          => {
            svg       => $svg_generation,
            img       => $img_generation,
            png       => $png_generation,
            speakText => $speakText_generation,
        },
        healthcheck_url => '/_info',
        require         => $require,
    }
}
