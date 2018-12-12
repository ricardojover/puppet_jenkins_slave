# The main reason of these commands is because, sometimes puppet throws an error when tries to 
# update or get packages because the apt or dpkg are running maintenance tasks
class common {
  exec {'wait_for_dpkg_to_finish':
    command => 'while true; do if pgrep "dpkg" > /dev/null; then echo "waiting for dpkg to finish"; sleep 1; else break; fi; done',
    cwd => '/tmp',
    provider => 'shell'
  }

  exec {'wait_for_aptget_to_finish':
    command => 'while true; do if pgrep "apt" > /dev/null; then echo "waiting for apt processes to finish"; sleep 1; else break; fi; done',
    cwd => '/tmp',
    provider => 'shell'
  }
}
