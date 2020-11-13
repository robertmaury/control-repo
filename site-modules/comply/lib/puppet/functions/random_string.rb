require 'securerandom'

# @summary Returns a random uuid
#
#   Returns a random uuid
Puppet::Functions.create_function(:random_string) do
  def random_string
    SecureRandom.hex
  end
end
