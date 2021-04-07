class role::fervid {

  class {'::secure_linux_cis':
   time_servers  => ['us.pool.ntp.org'],
   profile_type  => 'server',
   allow_users   => ['robert'],
   exclude_rules => ['ensure_bootloader_password_is_set']
  }

}
