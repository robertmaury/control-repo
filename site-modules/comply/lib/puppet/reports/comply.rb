# frozen_string_literal: true

require 'puppet'
require 'puppet/network/http_pool'
require 'puppet/util/comply'
require 'uri'
require 'json'

Puppet::Reports.register_report(:comply) do
  desc <<-DESC
    A copy of the standard http report processor except it sends a
    `application/json` payload to `:comply_url`
  DESC

  include Puppet::Util::Comply

  def process
    # Add in pe_console & producer fields
    report_payload = JSON.parse(to_json)
    report_payload['pe_console'] = pe_console
    report_payload['producer'] = Puppet[:certname]

    comply_urls = settings['comply_urls']

    comply_urls.each do |url|
      comply_url = "#{url}/data"
      Puppet.info "Comply sending report to #{comply_url}"
      send_to_comply(comply_url, report_payload)
    end
  end
end
