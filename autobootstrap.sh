#!/bin/bash

##### LICENSE

# Copyright (c) Skyscrapers (iLibris bvba) 2014 - http://skyscrape.rs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##### USAGE

# Options
#
# -r "<value>" : repo for puppet install if you want a specific version. Defaults to local apt sources. Example: -r "https://apt.puppetlabs.com/ trusty main"
# -p <value>   : puppetmaster address. Defaults to localhost.
# -t <value>   : timezone. For example -t "Europe/Brussels". Default = leave it be.
# -h <value>   : hostname of the system. Example: -h test-webserver. Default = output of /bin/hostname.
# -f <value>   : fqdn of the system. Example: -f webserver.test.domain.com. Default = output of /bin/hostname -f.
#
# Manual or as AWS EC2 UserData
#
# /bin/bash <(/usr/bin/wget -qO- http(s)://<location>/autobootstrap.sh) -r "<package repo URL and release name and section name>" -p <puppetmaster URI> -t <timezone> -h <hostname> -f <fqdn>

##### BEGIN SCRIPT

echo ""
echo "AUTO BOOTSTRAP script"
echo "---------------------"
echo ""
echo "This script will attempt to setup some basic configuration on a new Ubuntu system."
echo "apt, hostname, hosts file, timezone and Puppet agent."
echo ""

##### PARAMS and VARS

PACKAGEREPO=
PUPPETMASTER="localhost"
TIMEZONE=
HOSTNAME=`/bin/hostname`
FQDN=`/bin/hostname -f`

while getopts :r:p:t:h:f: opt; do
  case $opt in
  r)
    PACKAGEREPO=$OPTARG
    ;;
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
}

# set the hosts file
function sethosts {
  echo -n "* Adding host to hosts file"
  echo "127.0.0.1     $FQDN   $HOSTNAME" >> /etc/hosts
  echo " - Done"
}

# setup apt
function setupapt {
  if [ ! -z "$PACKAGEREPO" ]; then
    echo "deb $PACKAGEREPO" >> /etc/apt/sources.list.d/autobootstrap.list
    echo " - Done"

    echo -n "* Executing apt-get update"
    apt-get update
    echo " - Done"
  fi
}

# install and setup puppet
function installpuppet {
  echo -n "* Attempting to install puppet"
  apt-get install -y --force-yes puppet
  echo " - Done"

  echo -n "* Set Puppet to start on boot"
  if [ -f "/etc/default/puppet" ]; then
    sed -i 's/no/yes/g' /etc/default/puppet
  fi
  echo " - Done"

  echo -n "* Specify puppetmaster server \"$PUPPETMASTER\" and certname in Puppet agent config"
  echo "" >> /etc/puppet/puppet.conf
  echo "[agent]" >> /etc/puppet/puppet.conf
  echo "server=$PUPPETMASTER" >> /etc/puppet/puppet.conf
  echo "certname=$FQDN" >> /etc/puppet/puppet.conf
  echo "report=true" >> /etc/puppet/puppet.conf
  echo " - Done"

  echo -n "* Start Puppet agent"
  /etc/init.d/puppet restart > /dev/null
  echo " - Done"
}

# post setup stuff
function post {
  echo ""
  echo "All DONE"
  echo ""
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
  fi
}

##### EXECUTE

echo ""
echo "Starting setup..."
echo ""

sethostname
sethosts
settimezone
setupapt
installpuppet
post
