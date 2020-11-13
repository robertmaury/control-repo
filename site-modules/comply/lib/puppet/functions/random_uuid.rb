require 'securerandom'

# @summary Returns a random uuid
#
#   Returns a random uuid
Puppet::Functions.create_function(:random_uuid) do
  def random_uuid
    SecureRandom.uuid
  end
end
