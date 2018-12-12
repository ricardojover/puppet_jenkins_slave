class jenkins::agent ()  {
  $jenkins_home_folder_path = '/home/jenkins'
  $jenkins_ssh_folder_path = '/home/jenkins/.ssh'
  $user = 'jenkins'
  $group = 'jenkins'

  class { 'apt': }
  apt::ppa{ 'ppa:openjdk-r/ppa': }

  case $::operatingsystem {
    debian: {
      package { "openjdk-7-jre-headless":
        ensure => "latest",
      }
    }

    # Notice for newer versions of Jenkins the slave
    # will have to run java8
    ubuntu: {
      $java = $::operatingsystemrelease ? {
        /^(12.04|13.10)$/ => 'openjdk-7-jre-headless',
        default => 'openjdk-8-jre-headless',
      }

      package { "java":
        ensure  => "installed",
        name    => $java,
        require => [Exec['wait_for_aptget_to_finish', 'wait_for_dpkg_to_finish'], Apt::Ppa['ppa:openjdk-r/ppa']],
      }

      if $java == 'openjdk-8-jre-headless' {
        exec { "update_java_alternatives":
          command => '/usr/bin/update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
          cwd 		=> '/',
          require => Package["java"]
        }
      }
    }
  }

  file { $jenkins_ssh_folder_path:
		ensure  => 'directory',
		owner   => $user,
		group   => $group,
		mode    => "0750",
		require => User[$user],
  }

  user { $user:
    ensure      => present,
    home        => $jenkins_home_folder_path,
    managehome  => true,
    shell       => '/bin/bash',
  }

  file { "$jenkins_ssh_folder_path/config":
    owner 	=> $user,
    group 	=> $group,
    mode  	=> "0600",
    content => template('jenkins/config'),
    require => File[$jenkins_ssh_folder_path],
  }

  file { "$jenkins_ssh_folder_path/jenkins.pub":
    owner 	=> $user,
    group 	=> $group,
    mode  	=> "0600",
    source 	=> 'puppet:///modules/jenkins/jenkins.pub',
    require => File[$jenkins_ssh_folder_path],
  }

  file { "$jenkins_ssh_folder_path/jenkins.key":
    owner 	=> $user,
    group 	=> $group,
    mode  	=> "0600",
    source 	=> 'puppet:///modules/jenkins/jenkins.key',
    require => File[$jenkins_ssh_folder_path],
  }

  # As you can see bellow there are many ways of adding authorized keys...
  ssh_authorized_key { 'jenkins':
    user 		=> 'jenkins',
    type   	=> 'ssh-rsa',
    key 		=> "AAAA....",
    require => File[$jenkins_ssh_folder_path],
  }

  file { "${jenkins_ssh_folder_path}/authorized_keys" :
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => '0600',
		require => File[$jenkins_ssh_folder_path],
  }

  # You may have problems using ssh_authorized_key in some versions of puppet
  #  https://projects.puppetlabs.com/issues/21203
  file_line { 'JenkinsBuild':
    ensure	=> present,
    path    => "${jenkins_ssh_folder_path}/authorized_keys",
    line    => "ssh-rsa AAAA.... me"
  }

  exec { 'mangle sudoers':
		command => "/bin/grep includedir.*/etc/sudoers.d /etc/sudoers || echo '#includedir /etc/sudoers.d' >> /etc/sudoers",
    cwd 		=> '/etc',
  }

  file { '/etc/sudoers.d':
		ensure	=> 'directory',
    owner 	=> 'root',
    group 	=> 'root',
    mode  	=> "0755",
	}

  file { '/etc/sudoers.d/20-jenkins':
    owner 	=> 'root',
    group 	=> 'root',
    mode  	=> "0440",
    content => 'jenkins ALL=(ALL) NOPASSWD:ALL',
    require => File['/etc/sudoers.d'],
  }
}

