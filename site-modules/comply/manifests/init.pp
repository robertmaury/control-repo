# @summary Installs scarp and ciscat on a node
#
# Installs scarp and ciscat on a node
#
# @param [Boolean] linux_manage_unzip
#   Determines if this module should manage the installation of unzip on Linux
#
# @param [Boolean] windows_manage_jre8
#   Determines if this module should manage the installation of jre8 on Windows
#
# @param scanner_source
#   Supplies the storage location (URL) for the scanner. Required
#
# @example Use defaults
#   include comply
#
# @example Mange packages elsewhere
#   class { 'comply':
#     linux_manage_unzip  => false,
#     windows_manage_jre8 => false,
#   }
#
class comply (
  Boolean $linux_manage_unzip = true,
  Boolean $windows_manage_jre8 = true,
  Pattern[/(\d+\.\d+.\d+)/] $scanner_source = 'puppet:///modules/comply/Assessor-CLI-v4.0.24.zip',
  ) {
  include comply::scanners::ciscat
}
