# @summary Returns module version
#
#   Returns module version
Puppet::Functions.create_function(:module_version) do
  def module_version
    JSON.parse(
      File.read(Pathname.new(__FILE__).dirname.join('../../../metadata.json')),
    )['version'].split('.')[0..2].join('.')
  end
end
