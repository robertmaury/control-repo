# @summary Installs oscap on a system
#
# Installs the oscap scanner on to a system. Linux only
#
# @example
#   include comply::scanners::oscap
class comply::scanners::oscap {
  case $facts['os']['family'] {
    'RedHat': {
      package { 'openscap-scanner':
        ensure   => 'installed',
      }
      package { 'scap-security-guide':
        ensure   => 'installed',
      }
    }
    'Debian': {
      package { 'libopenscap8':
        ensure   => 'installed',
      }
    }
    default:  {
      notify {'OS is not currently supported':}
    }
  }
}
