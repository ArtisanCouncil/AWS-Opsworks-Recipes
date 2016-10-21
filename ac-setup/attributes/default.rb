require "net/smtp"                          # required for email alerts
require "time"                              # time module

## DEBUG 
Chef::Log.level = :debug 
# Global Config

# Set the default timezone for the servers.

# Set default variables for the Nginx and PHP configurations. These will default
# across all instances, but can be overridden using JSON in OpsWorks. It is
# important that none of the configuration directories are altered after at
# least one server has been deployed unless you know what you're doing. You have
# been warned well in advance.

case node['platform']
when 'debian', 'ubuntu'
  # do debian/ubuntu things 
  Chef::Log.warn "PLATFORM #{node['platform']}"
when 'redhat', 'centos', 'fedora' , 'amazon'
  Chef::Log.warn "PLATFORM redhat/centos/fedora/amazon"
end

# I think we can't use case statements in definitions for some reason, trying this here for now
# nginx config
case node['platform']
when 'debian', 'ubuntu' 
    default[:setup][:nginx][:user_name]            = "www-data"
    default[:setup][:nginx][:group_name]           = "www-data" 
    default[:setup][:php][:user_name]              = "www-data"
    default[:setup][:php][:group_name]             = "www-data"
when 'redhat', 'centos', 'fedora', 'amazon'
    default[:setup][:nginx][:user_name]            = "nginx"
    default[:setup][:nginx][:group_name]           = "nginx"
    default[:setup][:php][:user_name]            = "nginx"
    default[:setup][:php][:group_name]           = "nginx"

end
# php config
case node['platform']
when 'debian', 'ubuntu'
  # do debian/ubuntu things 
    default[:setup][:php][:conf_dir]               = "/etc/php/7.0/fpm/"
    default[:setup][:php][:conf_dir_ext]           = "/etc/php/7.0/fpm/conf.d"
    default[:setup][:php][:log_dir]                = "/var/log/php-fpm"
    default[:setup][:php][:site_dir]               = "/etc/php/7.0/fpm/pool.d" 
    default[:setup][:php][:pool_dir]               = "/etc/php/7.0/fpm/pool.d"  # for /etc/php5/fpm/pool.d/www.conf 
when 'redhat', 'centos', 'fedora' , 'amazon'
    default[:setup][:php][:conf_dir]               = "/etc"
    default[:setup][:php][:conf_dir_ext]           = "/etc/php.d"
    default[:setup][:php][:log_dir]                = "/var/log/php-fpm"
    default[:setup][:php][:site_dir]               = "/etc/php-fpm.d" 
end 



default[:setup][:nginx][:conf_dir]             = "/etc/nginx"
default[:setup][:nginx][:log_dir]              = "/var/log/nginx"
default[:setup][:nginx][:site_dir]             = "/etc/nginx/conf.d"
default[:setup][:nginx][:www_dir]              = "/app"


default[:setup][:cron][:cron_dir]              = "/etc/cron.d"

# Set some default variables for the global configuration of Nginx. These can be
# changed at any point, but do note that they may impact on server performance.
default[:setup][:nginx][:port]                          = 80

default[:setup][:nginx][:client_max_body_size]          = "128m"

default[:setup][:nginx][:gzip]                          = "on"
default[:setup][:nginx][:gzip_static]                   = "on"
default[:setup][:nginx][:gzip_vary]                     = "on"
default[:setup][:nginx][:gzip_disable]                  = "MSIE [1-6].(?!.*SV1)"
default[:setup][:nginx][:gzip_http_version]             = "1.0"
default[:setup][:nginx][:gzip_comp_level]               = "6"
default[:setup][:nginx][:gzip_proxied]                  = "any"
default[:setup][:nginx][:gzip_types]                    = [ "text/plain",
                                                            "text/html",
                                                            "text/css",
                                                            "application/x-javascript",
                                                            "text/xml",
                                                            "application/xml",
                                                            "application/xml+rss",
                                                            "text/javascript" ]

default[:setup][:nginx][:proxy_buffering]               = "off"
default[:setup][:nginx][:fastcgi_keep_conn]             = "on"

default[:setup][:nginx][:sendfile]                      = "on"

default[:setup][:nginx][:keepalive]                     = "on"
default[:setup][:nginx][:keepalive_timeout]             = 65

default[:setup][:nginx][:worker_processes]              = 2
default[:setup][:nginx][:worker_connections]            = 1024
default[:setup][:nginx][:server_names_hash_bucket_size] = 512

default[:setup][:nginx][:real_ip_header]                = "X-Forwarded-For"
default[:setup][:nginx][:set_real_ip_from]              = "0.0.0.0/0"

default[:setup][:nginx][:proxy_connect_timeout]         = "10800s"
default[:setup][:nginx][:proxy_send_timeout]            = "10800s"
default[:setup][:nginx][:proxy_read_timeout]            = "10800s"
default[:setup][:nginx][:send_timeout]                  = "10800s"

# Set some default variables for the global configuration of PHP. These can be
# changed at any point, but do note that they may impact on server performance.
default[:setup][:php][:short_open_tag] = "off"

default[:setup][:php][:output_buffering] = "off"
default[:setup][:php]['zlib.output_compression'] = "off"

# Set some default veriables for log management on the server.
default[:setup][:logrotate][:conf_dir_ext] = "/etc/logrotate.d"


# If an environment has been specified, then override the variables for the
# specific environment using anything in its attributes file.
if node[:setup][:environment] == "production"

  #Chef::Log.level = :debug                    # Shows more debug in chef logs
  Chef::Log.info "AC-SETUP:attributes/production.rb - Overwriting nginx config with production values"

end

if node[:setup][:environment] == "staging" 
  Chef::Log.info "AC-SETUP:attributes/staging.rb - Overwriting nginx config with staging values" 
  default[:setup][:nginx][:gzip]                          = "off"
  # TODO Should change some PHP values, show errors etc
end
