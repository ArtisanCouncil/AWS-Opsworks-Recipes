
Chef::Log.info "AC-SETUP::main Starting install of PHP packages" 
Chef::Log.warn "node.platform #{node['platform']}"
case node['platform']
when 'debian', 'ubuntu'
    # do debian/ubuntu things
    Chef::Log.warn "PLATFORM debian/ubuntu"
    Chef::Log.warn "PLATFORM #{node['platform']}"


    package "python-software-properties"
    
    execute "Installing repo for php7" do
        command "add-apt-repository ppa:ondrej/php"
    end

    execute "Apt-get update" do
        command "apt-get update"
    end

    execute "Install PHP stuff" do
        command "apt-get install -y --force-yes php7.0-cli php7.0-common php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd php7.0-mysql php7.0-bz2 php7.0-mcrypt php7.0-json php7.0-mysql php7.0-mbstring php7.0-xml php7.0-opcache"
    end


    #package "php7.0-cli"
    #package "php7.0-common"
    #package "php7.0"
    #package "php7.0-mysql"
    #package "php7.0-fpm"
    #package "php7.0-curl"
    #package "php7.0-gd"
    #package "php7.0-mysql"
    #package "php7.0-bz2"

    Chef::Log.warn "Installed PHP7 YAY"
   when 'redhat', 'centos', 'fedora', 'amazon'
    Chef::Log.warn "PLATFORM redhat/centos/fedota"
    package "php56"
    package "php56-cli"
    package "php56-fpm"
    package "php56-gd"
    package "php56-intl"
    package "php56-mbstring"
    package "php56-mcrypt"
    package "php56-mysqlnd"
    package "php56-process"
    package "php56-pecl-imagick"
    package "php56-pecl-memcache"
    package "php56-pecl-oauth"
    package "php56-soap"
    package "php56-xml"
    package "php56-xmlrpc"
    package "php56-opcache"

end

# Create the global PHP configuration based on the template in this cookbook.
# This should be consistent on each node running PHP for load-balanced clusters.
template "php.ini" do
  path "#{node[:setup][:php][:conf_dir]}/php.ini"
  source "php.ini.erb"
  owner "root"
  group "root"
  mode 0644
end
Chef::Log.warn "AC-SETUP::main Made php config file @ #{node[:setup][:php][:conf_dir]}/php.ini"
#
##Delete the default PHP-FPM pool configuration because the default one is not
## required. Instead, create one based on the template in this cookbook.
file "#{node[:setup][:php][:site_dir]}/www.conf" do
  action :delete
end
#
Chef::Log.info "AC-SETUP::base Deleted original PHP-FPM config file @ #{node[:setup][:php][:site_dir]}/www.conf"

# # below not needed??
# Create defailt.conf file for nginx requests that don't match any other site domains's e.g. hitting http://xxx.xxx.xxx.xx ip of site
template "default.conf" do
  path "#{node[:setup][:php][:site_dir]}/default.conf"
  source "php-default.conf.erb"
  owner "root"
  group "root"
  mode 0644
end

Chef::Log.info "AC-SETUP::main Created PHP-FPM config file @ #{node[:setup][:php][:site_dir]}/www.conf"

# PHP mcrypt module bug on ubuntu NOT NEEDED FOR 7.0 YAY
#if( node['platform'] == 'ubuntu' || node['platform'] == 'debian')
#    execute "Loading mcrypt module because #{node['platform']} is dumb" do
#        command "php5enmod mcrypt"
#    end
#end

case node['platform']
when 'debian', 'ubuntu'
  # do debian/ubuntu things

    template "#{node[:setup][:php][:pool_dir]}/www.conf" do
        source "www.conf.erb"
        owner "root"
        mode 0644
    end
    Chef::Log.warn "AC-SETUP::main Created WWW.CONF CONFIG FILE BECAUSE UBUNTU"

    execute "Stopping php5-fpm if it's not already started" do
        command "service php7.0-fpm stop"
        ignore_failure true
    end
    execute "Starting php5-fpm" do
        command "service php7.0-fpm start"
    end
end
