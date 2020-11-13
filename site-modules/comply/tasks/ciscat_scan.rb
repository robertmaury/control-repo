#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'puppet'
require 'open3'
require 'json'

begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
  require_relative '../lib/task_helper'
rescue LoadError
  # include location for unit tests
  require 'fixtures/modules/ruby_task_helper/files/task_helper.rb'
  require 'fixtures/modules/comply/lib/task_helper'
end

# Ciscat scan task
class CiscatClass < TaskHelper
  def clean_reports(result_file_matcher, result_file)
    # remove existing scan result files
    Dir.glob(result_file_matcher).each { |file| File.delete(file) }
    FileUtils.rm_f(result_file)
  rescue Errno::ENOENT # rubocop:disable Lint/HandleExceptions
    # do nothing, this is fine
  end

  def task(comply_server: nil, comply_port: nil, benchmark: nil, profile: nil, scan_hash: nil, custom_profile_id: nil, scan_type: 'adhoc', **_kwargs)
    if (benchmark.nil? && scan_hash.nil?) || (!benchmark.nil? && !scan_hash.nil?)
      raise TaskHelper::Error.new('Either scan_hash OR benchmark must be set exclusively',
                                  'ciscatclass/cannot_parse_scan_hash',
                                  status: 1,
                                  err: scan_hash)
    end
    install_path, result_path = return_install_directories
    # use the hash to get the profile and benchmark
    fqdn = get_fact('fqdn')['fqdn'].downcase
    if !scan_hash.nil?
      # parse the scan_hash string information to json
      begin
        parsed_hash = JSON.parse(scan_hash)
      rescue
        raise TaskHelper::Error.new("Cannot parse scan_hash #{scan_hash}",
                                    'ciscatclass/cannot_parse_scan_hash',
                                    status: 1,
                                    err: scan_hash)
      end
      # the following takes the hash and converts all keys or symbols to strings for lookup simplicity
      # nicer ways to do it in newer ruby versions or rails, but constrained to this while we support older ruby
      parsed_hash = parsed_hash.each_with_object({}) { |(k, v), memo| memo[k.to_s] = v; }
      # convert hostnames/keys to lowercase, looped this way for ruby 2.4
      lower_parsed_hash = {}
      parsed_hash.each_pair do |key, value|
        lower_parsed_hash[key.downcase] = value
      end
      parsed_hash = lower_parsed_hash
      benchmark_profile = parsed_hash[fqdn]
      if benchmark_profile.nil?
        raise TaskHelper::Error.new("No match for host #{fqdn}",
                                    'ciscatclass/hosts_doesnt_match_fqdn',
                                    status: -1, # jc_status does not return
                                    err: parsed_hash)
      end
      benchmark_file = benchmark_profile['benchmark']
      profile_option = '-p ' + benchmark_profile['profile']
      custom_profile_id = benchmark_profile['custom_profile_id']
    else
      benchmark_file = benchmark
      profile_option = if profile.nil?
                         ''
                       else
                         "-p #{profile}"
                       end
    end

    # remove existing scan result files
    result_file_matcher = File.join(result_path, 'puppet-compliance*.xml')
    result_file = File.join(result_path, 'xccdf-results.xml')
    clean_reports(result_file_matcher, result_file)

    java_check = 'java -version'
    begin
      _stdout, jc_stderr, _jc_status = Open3.capture3(java_check)
    rescue Errno::ENOENT
      raise TaskHelper::Error.new('Java installation not detected',
                                  'ciscatclass/javamissing',
                                  status: -1, # jc_status does not return
                                  cmd_ran: java_check,
                                  err: jc_stderr)
    end

    unless File.file?("#{install_path}benchmarks/#{benchmark_file}")
      raise TaskHelper::Error.new("Benchmark files not found #{install_path}benchmarks/#{benchmark_file}",
                                  'ciscatclass/benchmarkmissing',
                                  status: -1, # file does not return
                                  err: nil)
    end

    cmd = "java -Xmx2048M -jar #{install_path}Assessor-CLI.jar -q -rp puppet-compliance -rd #{result_path} #{profile_option} -b #{install_path}benchmarks/#{benchmark_file}"
    stdout, stderr, status = Open3.capture3(cmd)
    begin
      Dir.glob(result_file_matcher).each { |file| File.rename(file, result_file) }
    rescue Errno::ENOENT => e
      raise TaskHelper::Error.new("Unable to locate scan report '#{result_file}'",
                                  'ciscatclass/missingreport',
                                  status: status.exitstatus,
                                  cmd_ran: cmd,
                                  err: e.message)
    end
    unless status.exitstatus.zero?
      raise TaskHelper::Error.new("Scan did not complete successfully '#{cmd}', '#{stderr}'",
                                  'ciscatclass/noscan',
                                  status: status.exitstatus,
                                  cmd_ran: cmd,
                                  err: stderr)
    end

    # upload to comply server
    unless comply_server == 'nil'
      response = upload_scan_result(result_file: result_file, format: 'ciscat', comply_server: comply_server,
                                    comply_port: comply_port, custom_profile_id: custom_profile_id,
                                    scan_type: scan_type, fqdn: fqdn)
      if response.code != '200'
        raise TaskHelper::Error.new("Report upload failed #{response.code}",
                                    'ciscatclass/upload_failed',
                                    status: response.code,
                                    err: response.code)
      end
    end
    clean_reports(result_file_matcher, result_file)
    {
      status: status.exitstatus,
      scan_cmd: cmd,
      stdout: stdout,
      result_file: result_file,
    }
  end
end

if $PROGRAM_NAME == __FILE__
  CiscatClass.run
end
