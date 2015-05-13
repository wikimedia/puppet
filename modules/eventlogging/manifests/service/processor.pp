# == Define: eventlogging::service::processor
#
# EventLogging processors transform a raw request log, such as might be
# generated by Varnish or MediaWiki, into a well-structured stream of
# JSON events.
#
# === Parameters
#
# [*format*]
#   scanf-like format string, specifying the layout of EventLogging
#   fields in raw log records. The available format specifiers are:
#
#     %h       Client IP
#     %j       JSON object
#     %q       Query-string-encoded JSON
#     %t       Timestamp in NCSA format
#     %{..}i   Tab-delimited string
#     %{..}s   Space-delimited string
#     %{..}d   Integer
#
#   (Where '..' is the desired property name for the matching group.)
#
#   All other parts of the format string are interpreted as Python
#   regexp syntax. See <http://docs.python.org/2/library/re.html>
#   for details.
#
# [*input*]
#   The URI of the raw log stream which the processor will take as its
#   input. Example: 'tcp://eventlog1001.eqiad.wmnet:8421'.
#
# [*output*]
#   A URI specifying the interface and port on which the processed event
#   stream will be published. Example: 'tcp://*:8600'.
#
# [*output_invalid*]
#   An optional URI specifying the interface and port on which the invalid
#   event stream will be published. Example: 'tcp://*:8600'. Defaults to
#   null.
#
# [*sid*]
#   Specifies the socket ID the processor will use to identify itself
#   when subscribing to input streams. Defaults to the resource title.
#
# [*ensure*]
#   If 'present' (the default), sets up the processor. If 'absent',
#   destroys it.
#
# === Examples
#
#  eventlogging::service::processor { 'client_side_events':
#    input  => 'tcp://127.0.0.1:8422',
#    format => '%q %l %n %t %h',
#    output => 'tcp://*:8522',
#  }
#
define eventlogging::service::processor(
    $format,
    $input,
    $output,
    $output_invalid = undef,
    $sid            = $title,
    $ensure         = present,
) {
    include ::eventlogging

    $basename = regsubst($title, '\W', '-', 'G')
    file { "/etc/eventlogging.d/processors/${basename}":
        ensure  => $ensure,
        content => template('eventlogging/processor.erb'),
        notify  => Service['eventlogging/init'],
    }
}
