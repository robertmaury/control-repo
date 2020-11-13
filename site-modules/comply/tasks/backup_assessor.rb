#!/opt/puppetlabs/puppet/bin/ruby
# frozen_string_literal: true

require 'puppet'
require 'open3'
require 'fileutils'

begin
  require_relative '../../ruby_task_helper/files/task_helper.rb'
  require_relative '../lib/task_helper'
rescue LoadError
  # include location for unit tests
  require 'fixtures/modules/ruby_task_helper/files/task_helper.rb'
  require 'fixtures/modules/comply/lib/task_helper'
end

# BackUpAssessor task
class BackupAssessor < TaskHelper
  def task(operation: 'create', **_kwargs)
    install_path, = return_install_directories
    backup_location = install_path.chomp('/') + '_old/'
    if operation == 'delete'
      FileUtils.remove_dir backup_location
      return {
        status: 0,
        stdout: "Removed #{backup_location}",
      }
    elsif operation == 'restore'
      FileUtils.mv backup_location, install_path
      return {
        status: 0,
        stdout: "Moved #{backup_location} to #{install_path}",
      }
    else
      FileUtils.mv install_path, backup_location
      return {
        status: 0,
        stdout: "Moved #{install_path} to #{backup_location}",
      }
    end
  end
end

if $PROGRAM_NAME == __FILE__
  BackupAssessor.run
end
