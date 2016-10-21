#Metadata
name				"ac-setup"
maintainer          "Artisan Council"
maintainer_email    "adam.kinnane@artisancouncil.com"
description         "Installs & configures PHP & Nginx for staging & production servers"
version             "1.0.0"
license             "Proprietary - All Rights Reserved"
privacy
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))


#System Specs
%w{ ubuntu amazon }.each do |os|
  supports os
end
