# frozen_string_literal: true

require 'puppet/indirector/facts/yaml'
require 'puppet/util/profiler'
require 'puppet/util/comply'
require 'json'
require 'time'

# Comply Facts
class Puppet::Node::Facts::Comply < Puppet::Node::Facts::Yaml
  desc 'Save facts to Comply and then to yamlcache.'

  include Puppet::Util::Comply

  def profile(message, metric_id, &block)
    message = 'Comply: ' + message
    arity = Puppet::Util::Profiler.method(:profile).arity
    case arity
    when 1
      Puppet::Util::Profiler.profile(message, &block)
    when 2, -2
      Puppet::Util::Profiler.profile(message, metric_id, &block)
    end
  end

  def save(request)
    # yaml cache goes first
    super(request)

    profile('comply_facts#save', [:comply, :facts, :save, request.key]) do
      begin
        Puppet.info 'Submitting facts to Comply'
        current_time = Time.now
        send_facts(request, current_time.clone.utc)
      rescue StandardError => e
        Puppet.err "Could not send facts to Comply: #{e}\n#{e.backtrace}"
      end
    end
  end
end
