# frozen_string_literal: true

require 'json'
require 'open3'

def get_fact(fact)
  if Gem.win_platform?
    require 'win32/registry'
    installed_dir =
      begin
        Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Puppet Labs\Puppet') do |reg|
          # rubocop:disable Style/RescueModifier
          # Rescue missing key
          dir = reg['RememberedInstallDir64'] rescue ''
          # Both keys may exist, make sure the dir exists
          break dir if File.exist?(dir)
          # Rescue missing key
          reg['RememberedInstallDir'] rescue ''
          # rubocop:enable Style/RescueModifier
        end
      rescue Win32::Registry::Error
        # Rescue missing registry path
        ''
      end
    facter =
      if installed_dir.empty?
        ''
      else
        File.join(installed_dir, 'bin', 'facter.bat')
      end

  else
    facter = '/opt/puppetlabs/puppet/bin/facter'
  end

  # Fall back to PATH lookup if puppet-agent isn't installed
  facter = 'facter' unless File.exist?(facter)
  cmd = [facter, '--json']
  cmd << fact if fact
  stdout, stderr, status = Open3.capture3(*cmd)
  raise "Exit #{status.exitstatus} running #{cmd.join(' ')}: #{stderr}" unless status.success?
  JSON.parse(stdout)
end

def return_install_directories
  os_facts = get_fact('os')
  case os_facts['os']['family']
  when 'windows'
    install_path = 'C:/ProgramData/PuppetLabs/comply/Assessor-CLI/'
    result_path = 'C:/ProgramData/PuppetLabs/comply/tmp/'
  else
    install_path = '/opt/puppetlabs/comply/Assessor-CLI/'
    result_path = '/opt/puppetlabs/comply/tmp/'
  end
  [install_path, result_path]
end

def upload_scan_result(result_file: nil, format: nil, comply_server: nil, comply_port: nil, custom_profile_id: nil, scan_type: 'adhoc', fqdn: nil)
  os_facts = get_fact('os')
  # parse report for facts
  path = case os_facts['os']['family']
         when 'windows'
           ''
         else
           # fix for missing path in RHEL6 vm
           'export PATH=/usr/local/bin:$PATH && '
         end

  path_to_result_file = if result_file.nil?
                          File.join(Dir.tmpdir, 'xccdf-results.xml')
                        else
                          result_file
                        end
  request = Net::HTTP::Post.new('/api/v3/core/store/report')
  form_data = [['report', File.open(path_to_result_file)], ['scantype', scan_type], ['format', format], ['fqdn', fqdn]]
  form_data.push(['customprofileid', custom_profile_id.to_s]) unless custom_profile_id.nil?
  request.set_form form_data, 'multipart/form-data'
  # send the report to the scarp server
  config = Open3.capture3("#{path}puppet config print ssldir")
  ssldir = config[0].strip

  response = Net::HTTP.start(
    comply_server,
    comply_port.to_i,
    use_ssl: true,
    key: OpenSSL::PKey::RSA.new(File.read("#{ssldir}/private_keys/#{fqdn}.pem")),
    cert: OpenSSL::X509::Certificate.new(File.read("#{ssldir}/certs/#{fqdn}.pem")),
    ca_file: "#{ssldir}/certs/ca.pem",
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
    verify_depth: 5,
  ) do |http|
    http.request(request)
  end
  response
end
