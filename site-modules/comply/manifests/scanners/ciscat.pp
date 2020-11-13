# @summary Installs a JRE
#
# CIS CAT Pro scanner requies a JRE as a prerequisite
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
# @example
#   include comply::scanners::ciscat
#
# @example Mange packages elsewhere
#   class { 'comply::ciscat':
#     linux_manage_unzip  => false,
#     windows_manage_jre8 => false,
#   }
#
class comply::scanners::ciscat(
  Boolean $linux_manage_unzip = $comply::linux_manage_unzip,
  Boolean $windows_manage_jre8 = $comply::windows_manage_jre8,
  Pattern[/(\d+\.\d+.\d+)/] $scanner_source = $comply::scanner_source,
) inherits comply {
  include archive

  if $scanner_source =~ /v(\d+\.\d+.\d+)/ {
    $scanner_version = $1

    if ($scanner_version == undef) {
      fail('Scanner source does not contain valid version. Version should be included in filepath.')
    }
  }

  if $facts['kernel'] == 'windows' {
    $install_path = 'C:/ProgramData/PuppetLabs/comply'

    include chocolatey

    if $windows_manage_jre8 {
      package { 'jre8':
        ensure   => latest,
        provider => 'chocolatey',
        notify   => Service['pxp-agent'],
      }
    }
  } else {
    $install_path = '/opt/puppetlabs/comply'

    if ($facts['os']['family'] == 'RedHat') and ($facts['os']['release']['major'] == '6' or $facts['os']['release']['major'] == '2') {
      class { 'java':
        distribution => 'jre',
        package      => 'java-1.8.0-openjdk',
      }
    } else {
      class { 'java':
        distribution => 'jre',
      }
    }

    if $linux_manage_unzip {
      package { 'unzip':
        ensure => 'installed'
      }
    }
  }

  unless ($facts['assessor'] == $scanner_version) {
    file {
      default:
        ensure => directory,
      ;
      'comply':
        path   => $install_path,
      ;
      "${install_path}/tmp": ;
      "${install_path}/tmp/Assessor-CLI-${scanner_version}.zip":
        ensure => file,
        source => $scanner_source,
      ;
    }

    archive { "Assessor-CLI-${scanner_version}.zip":
      path         => "${install_path}/tmp/Assessor-CLI-${scanner_version}.zip",
      extract      => true,
      extract_path => $install_path,
      creates      => "${install_path}/Assessor-CLI",
      cleanup      => true,
    }

    file { 'Assessor-CLI.jar':
      path    => "${install_path}/Assessor-CLI/Assessor-CLI.jar",
      mode    => '0755',
      require => Archive["Assessor-CLI-${scanner_version}.zip"],
    }

    file { 'Assessor-CLI Version':
      path    => "${install_path}/Assessor-CLI/VERSION",
      content => $scanner_version,
      require => File['Assessor-CLI.jar'],
    }
  }
}
