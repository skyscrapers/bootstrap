#!/bin/bash
##### USAGE

# Options
#
# -p <value>   : puppetmaster address. Defaults to localhost.
# -t <value>   : timezone. For example -t "Europe/Brussels". Default = leave it be.
# -h <value>   : hostname of the system. Example: -h test-webserver. Default = output of /bin/hostname.
# -f <value>   : fqdn of the system. Example: -f webserver.test.domain.com. Default = output of /bin/hostname -f.
#
# Manual or as AWS EC2 UserData
#
# /bin/bash <(/usr/bin/wget -qO- http(s)://<location>/autobootstrap.sh) -p <puppetmaster URI> -t <timezone> -h <hostname> -f <fqdn>

##### BEGIN SCRIPT

echo ""
echo "AUTO BOOTSTRAP script"
echo "---------------------"
echo ""
echo "This script will attempt to setup some basic configuration on a new Ubuntu system."
echo "hostname, hosts file, timezone and Puppet agent."
echo ""

/usr/bin/logger -t autobootstrap "STARTING autobootstrap.sh"

##### PARAMS and VARS

PUPPETMASTER="localhost"
TIMEZONE="UTC"
HOSTNAME=`/bin/hostname`
FQDN=`/bin/hostname -f`
ENVIRONMENT=""

while getopts :r:p:t:h:f:e: opt; do
  case $opt in
  p)
    PUPPETMASTER=$OPTARG
    ;;
  t)
    TIMEZONE=$OPTARG
    ;;
  h)
    HOSTNAME=$OPTARG
    ;;
  f)
    FQDN=$OPTARG
    ;;
  e)
    ENVIRONMENT=$OPTARG
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    exit 2
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 2
    ;;
  esac
done

##### FUNCTIONS

# set the hostname
function sethostname {
  echo -n "* Setting up hostname to $HOSTNAME"
  hostname "$HOSTNAME"
  echo "$HOSTNAME" > /etc/hostname
  echo " - Done"
  /usr/bin/logger -t autobootstrap "hostname set to $HOSTNAME"
}

# set the hosts file
function sethosts {
  echo -n "* Adding host to hosts file"
  echo "127.0.0.1     $FQDN   $HOSTNAME" >> /etc/hosts
  echo " - Done"
  /usr/bin/logger -t autobootstrap "updated /etc/hosts with $HOSTNAME and $FQDN"
}

function enablePreserveHostname {
  echo -n "* Enabling preserve_hostname"
  sed -i '/preserve_hostname/s/false/true/' /etc/cloud/cloud.cfg
  echo " - Done"
  /usr/bin/logger -t autobootstrap "enabled preserve_hostname in /etc/cloud/cloud.cfg"
}

# setup apt
function setupapt {
  eval `cat /etc/lsb-release`

  cd /tmp
  wget -q https://apt.puppetlabs.com/puppet5-release-${DISTRIB_CODENAME}.deb
  dpkg -i /tmp/puppet5-release-${DISTRIB_CODENAME}.deb
  /usr/bin/logger -t autobootstrap "added puppetlabs apt repo and key"

  echo -n "* Executing apt-get update"
  apt-get update
  echo " - Done"
  /usr/bin/logger -t autobootstrap "ran apt-get update"

  echo -n "* Executing apt-get dist-upgrade"
  DEBIAN_FRONTEND=noninteractive
  unset UCF_FORCE_CONFFOLD
  export UCF_FORCE_CONFFNEW=YES
  ucf --purge /boot/grub/menu.lst
  apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy dist-upgrade
  echo " - Done"
  /usr/bin/logger -t autobootstrap "ran apt-get dist-upgrade"
}

# install and setup puppet
function installpuppet {
  echo -n "* Attempting to install puppet"
  apt-get install -y --force-yes puppet-agent=5.5.*
  echo " - Done"
  /usr/bin/logger -t autobootstrap "installed puppet"

  echo -n "* Specify puppetmaster server \"$PUPPETMASTER\" and certname in Puppet agent config"
  echo "" > /etc/puppetlabs/puppet/puppet.conf
  echo "[agent]" >> /etc/puppetlabs/puppet/puppet.conf
  echo "server=$PUPPETMASTER" >> /etc/puppetlabs/puppet/puppet.conf
  echo "certname=$FQDN" >> /etc/puppetlabs/puppet/puppet.conf
  echo "report=true" >> /etc/puppetlabs/puppet/puppet.conf
  [[ ! -z $ENVIRONMENT ]] && echo "environment=$ENVIRONMENT" >> /etc/puppetlabs/puppet/puppet.conf
  echo " - Done"
  /usr/bin/logger -t autobootstrap "setup puppet agent to use $PUPPETMASTER as puppetmaster"

  echo -n "* Disabling ec2_userdata fact"
  mkdir -p /etc/facter/facts.d/
  cat > /etc/facter/facts.d/ec2_userdata.sh <<EOL
#!/bin/bash
## THIS FILE IS PUPPETIZED, CHANGES WILL BE OVERWRITTEN EVENTUALLY
## CONTACT A SYSADMIN TO CHANGE SETTINGS IN HERE

# Overwrite the ec2_userdata fact due to it containing gzipped data
# https://tickets.puppetlabs.com/browse/FACT-1024
# https://tickets.puppetlabs.com/browse/FACT-1354
echo 'ec2_userdata='
EOL
  chmod a+x /etc/facter/facts.d/ec2_userdata.sh
  /opt/puppetlabs/bin/facter --no-cache ec2_userdata
  echo " - Done"
  /usr/bin/logger -t autobootstrap "disabled ec2_userdata fact"

  echo -n "* Enable puppet"
  /opt/puppetlabs/bin/puppet agent --enable

  echo -n "* Start Puppet agent"
  service puppet restart > /dev/null
  echo " - Done"
  /usr/bin/logger -t autobootstrap "started puppet agent"
}

# post setup stuff
function post {
  echo ""
  echo "All DONE"
  echo ""
  /usr/bin/logger -t autobootstrap "autobootstrap.sh ENDED"
  exit 0
}

# set time zone
function settimezone {
  if [ ! -z "$TIMEZONE" ]; then
    echo "Setup timezone"
    echo "$TIMEZONE" > /etc/timezone
    rm /etc/localtime
    ln -s /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    date
    echo " - Done"
    /usr/bin/logger -t autobootstrap "set time zone to $TIMEZONE"
  fi
}

##### EXECUTE

echo ""
echo "Starting setup..."
echo ""

sethostname
sethosts
enablePreserveHostname
settimezone
setupapt
installpuppet
post
