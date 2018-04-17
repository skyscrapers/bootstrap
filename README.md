bootstrap
=========
About
-----
This script will attempt to setup some basic configuration on a new Ubuntu system and provision it with the latest puppet 5.5 version.. After that puppet should do the rest of the configuration.

Tested on Ubuntu 14.04 and 16.04 (12.04 is unsupported). Things like apt, hostname, hosts file, timezone and Puppet agent. After running, the only thing to do, is open up firewall rules and/or accept the puppet agent certificate (if applicable).

Options
-------
- -r "&lt;value&gt;" : repo for puppet install if you want a specific version. Defaults to local apt sources. Example: -r "https://apt.puppetlabs.com/ trusty main"
- -p &lt;value&gt;   : puppetmaster address. Defaults to localhost.
- -t &lt;value&gt;   : timezone. For example -t "Europe/Brussels". Default = leave it be.
- -h &lt;value&gt;   : hostname of the system. Example: -h test-webserver. Default = output of /bin/hostname.
- -f &lt;value&gt;   : fqdn of the system. Example: -f webserver.test.domain.com. Default = output of /bin/hostname -f.
- -e &lt;value&gt;   : environment of the system. Example: -e development. If empty it will not add the environment to the puppet config.

Usage
-----
Manual or as AWS EC2 UserData

    #!/bin/bash
    /bin/bash <(/usr/bin/wget -qO- https://raw.githubusercontent.com/skyscrapers/bootstrap/master/autobootstrap.sh) -r "<package repo URL and release name and section name>" -p <puppetmaster URI> -t <timezone> -h <hostname> -f <fqdn> -e <environment>
