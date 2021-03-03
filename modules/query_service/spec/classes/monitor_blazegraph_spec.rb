require_relative '../../../../rake_modules/spec_helper'

describe 'icinga::monitor::wdqs', :type => :class do
  let(:pre_condition) do
    'class profile::base($notifications_enabled = true) {}
    include profile::base'
  end

  it { is_expected.to contain_monitoring__check_prometheus('wdqs-response-time-eqiad')
                          .with_query('histogram_quantile(0.99, sum (rate(varnish_backend_requests_seconds_bucket{backend=~".*wdqs.*"}[10m])) by (le))')
  }
end
