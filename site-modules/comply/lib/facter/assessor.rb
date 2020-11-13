# Get information about assessor
require 'facter'
require 'json'
require 'task_helper'

Facter.add(:assessor) do
  setcode do
    os_facts = get_fact('os')
    install_path = case os_facts['os']['family']
                   when 'windows'
                     'C:/ProgramData/PuppetLabs/comply/Assessor-CLI/'
                   else
                     '/opt/puppetlabs/comply/Assessor-CLI/'
                   end

    version_file = "#{install_path}VERSION"

    assessor_version = File.read(version_file, 64) if File.exist?(version_file)

    assessor_version
  end
end
