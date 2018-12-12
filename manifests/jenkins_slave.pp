include common
include jenkins::agent

class { 'monitoring':
  filebeat_yml      => 'monitoring/filebeat.yml',
  metricbeat_yml    => 'monitoring/metricbeat.yml'
}

file { '/home/jenkins': 
  ensure => directory, 
}

exec { '/bin/chown jenkins /home/jenkins':
  require => User[jenkins],
  before => File['/home/jenkins/.ssh'],
  cwd => '/tmp',
}

exec { 'add-docker-key':
  command => 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -',
  cwd => '/tmp',
  provider => 'shell'
}

file { '/etc/apt/sources.list.d/docker.list':
  content => "deb https://download.docker.com/linux/ubuntu $::lsbdistcodename stable",
  mode => "0644",
  owner => 'root'
}

exec { 'enable_docker_repo':
  require => [Exec['add-docker-key'], File['/etc/apt/sources.list.d/docker.list']],
  cwd => '/tmp',
  command => '/usr/bin/apt-get update',
  provider => 'shell'
}

exec { '/usr/bin/apt-get update':
  cwd => '/tmp',
  provider => 'shell'
}

$packages = [	'curl', 'apt-transport-https', 'ca-certificates', 
              'software-properties-common',	'firefox', 'gcc', 
              'imagemagick', 'libjpeg-dev', 'libncurses5-dev', 
              'libpng-dev', 'memcached', 'python-virtualenv',	
              'x11-apps', 'xfonts-100dpi', 'xfonts-75dpi', 
							'xfonts-cyrillic', 'xfonts-scalable', 'xvfb' ]

package { $packages:
  ensure => "installed",
  require => Exec['/usr/bin/apt-get update'],
}

$packages_to_purge = ['docker', 'docker-engine', 'docker.io']

package { $packages_to_purge: 
  ensure=>'purged',
}

package { 'docker-ce': 
  ensure=>'installed', 
  require=>[Package[$packages], Package[$packages_to_purge], Exec['enable_docker_repo']],
}
  
exec { 'install_docker_compose':
  name => '/bin/bash -c \'sudo curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose\'',
  cwd => '/'
}

