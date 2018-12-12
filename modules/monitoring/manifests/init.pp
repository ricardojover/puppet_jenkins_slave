class monitoring (
  $filebeat_yml,
  $metricbeat_yml) {

  $filebeat_dir = '/usr/share/filebeat/'
  $metricbeat_dir = '/usr/share/metricbeat/'

  file { 'metricbeat directory':
    ensure => 'directory',
    path   => $metricbeat_dir,
    mode   => '0755'
  }

  file { 'filebeat directory':
    ensure => 'directory',
    path   => $filebeat_dir,
    mode   => '0755'
  }

  # It is important to note that systemd is only fully supported 
  # in Ubuntu 15.04 and later releases.
  # https://wiki.ubuntu.com/SystemdForUpstartUsers
  $upstart = $::operatingsystem ? {
    debian => 'yes',
    ubuntu => $::operatingsystemrelease ? {
      /^(12.04|14.04)$/ => 'yes',
      default => 'no',
    }
  }

  # Metricbeat and filebeat services must exist
  if ($upstart == 'yes') {
    exec { 'stop_filebeat':
      command => '/sbin/initctl stop filebeat',
     require => File[$filebeat_dir]
    }
  } else {
    exec { 'stop_filebeat':
      command => '/bin/systemctl stop filebeat',
      require => File[$filebeat_dir]
    }
  }

  # We do not need to start it after that cos it'll be started after the deployment...
  file { '/usr/share/filebeat/filebeat.yml':
    ensure  => present,
    mode    => '0644',
    owner   => root,
    content => template($filebeat_yml),
    require => Exec['stop_filebeat']
  }

  if ($upstart == 'yes') {
    exec { 'stop_metricbeat':
      command => '/sbin/initctl stop metricbeat',
      require => File[$metricbeat_dir]
    }
  } else {
    exec { 'stop_metricbeat':
      command => '/bin/systemctl stop metricbeat',
      require => File[$metricbeat_dir]
    }
  }
  

  file { '/usr/share/metricbeat/metricbeat.yml':
    ensure  => present,
    mode    => '0644',
    owner   => root,
    content => template($metricbeat_yml),
    require => Exec['stop_metricbeat']
  }
}
