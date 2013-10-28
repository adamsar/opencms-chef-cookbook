name             'opencms'
maintainer       'Ubicast'
maintainer_email 'a_adams@ubicast.com'
license          'All rights reserved'
description      'Installs/Configures the latest version of opencms'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

recipe "opencms::default", "Installs opencms on a tomcat installation"

#%w{ ohai, tomcat, nginx, mysql }.each do |pkg|
#  depends pkg
#end

depends "ohai"
depends "nginx"
depends "tomcat"
depends "mysql"
