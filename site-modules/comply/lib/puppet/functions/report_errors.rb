# frozen_string_literal: true

# @summary Returns error details
#
#   Returns error details

Puppet::Functions.create_function(:report_errors) do
  # @param error_hash
  # @param allow_exit_code2
  # @return [String] Returns error string
  # @example
  #   report_erros('[a, hash, of, errors]', true)
  dispatch :report_errors do
    param 'ResultSet', :error_hash
    optional_param 'Boolean', :allow_exit_code2
  end

  def report_errors(error_hash, allow_exit_code2 = false)
    error_hash.each do |target|
      data = target.to_data
      if data['status'] == 'failure'
        if (data['value'].key? 'stderr') && allow_exit_code2 && (data['value']['status'] != 2)
          Puppet.warning("[Failed][#{data['target']}][#{data['action']}][#{data['object']}]\n>>> #{data['value']['stderr'].strip}\n")
        elsif data['value'].key? '_error'
          Puppet.warning("[Failed][#{data['target']}][#{data['action']}][#{data['object']}]\n>>> #{data['value']['_error']['msg'].strip}\n")
        end
      end
    end
  end
end
