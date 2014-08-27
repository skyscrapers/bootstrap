bootstrap
=========

Options
-------
-r "<value>" : repo for puppet install if you want a specific version. Defaults to local apt sources. Example: -r "https://apt.puppetlabs.com/ trusty main"
-p <value>   : puppetmaster address. Defaults to localhost.
-t <value>   : timezone. For example -t "Europe/Brussels". Default = leave it be.
-h <value>   : hostname of the system. Example: -h test-webserver. Default = output of /bin/hostname.
-f <value>   : fqdn of the system. Example: -f webserver.test.domain.com. Default = output of /bin/hostname -f.

Usage
-----
Manual or as AWS EC2 UserData

#!/bin/bash
/bin/bash <(/usr/bin/wget -qO- https://raw.githubusercontent.com/skyscrapers/bootstrap/master/autobootstrap.sh) -r "<package repo URL and release name and section name>" -p <puppetmaster URI> -t <timezone> -h <hostname> -f <fqdn>
