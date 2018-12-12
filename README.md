In this project I use Puppet to configure Ubuntu to work as a Jenkins Slave.
I assume filebeat and metricbeat are already installed and configured in 
upstart or systemd.


This project has been tested in Puppet 3.8, 5 and 6. For Puppet 3.8 you will
need to install older versions of the modules apt and stdlib though.

## How to install Puppet 6 ?
```
PUPPET_VERSION=6
CODENAME=$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d'=' -f 2)
wget https://apt.puppetlabs.com/puppet${PUPPET_VERSION}-release-${CODENAME}.deb
sudo dpkg -i puppet${PUPPET_VERSION}-release-${CODENAME}.deb
sudo apt update -y
sudo apt install -y puppet-agent
```

Notice that in Puppet 4 they changed the location of a lot of important config files and directories.
Everything can now be found in /opt/puppetlabs. 
```
export PATH=/opt/puppetlabs/bin:$PATH
```

By adding the puppetlabs path at the beginning of your path you ensure that you won't execute 
an older version installed on your computer by mistake.

## Installing dependencies
In the directory of this project execute the command bellow to install the necessary
dependencies (It will automatically install the missing dependencies like stdlib):
```
puppet module install puppetlabs-apt --version 6.2.1 --modulepath=./modules
```

## Running a manifest
To run the puppet manifest jenkins_slave.pp:
```
puppet apply --detailed-exitcodes --color=true --modulepath=./modules manifests/jenkins_slave.pp
```

