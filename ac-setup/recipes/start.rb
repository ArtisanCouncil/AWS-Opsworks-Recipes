
Chef::Log.info "AC-SETUP::start START.RB ENTERED" # Let us know we've begun processing this file

#
# #
# # START AND ENABLE SERVICES
# #
# 
#service "nginx" do              # Enable the Nginx service & trigger a start event to start it up.
  #supports :status => true, :start => true, :restart => true, :reload => true
  #action [ :enable, :start ]
#end
#Chef::Log.info "MIK-SETUP::start Set up & started NGINX service" 

#service "php-fpm" do            # Enable the PHP-FPM service & trigger a start event to start it up.  
  #supports :status => true, :start => true, :restart => true, :reload => true
  #action [ :enable, :start ]
#end

#Chef::Log.info "AC-SETUP::start Set up & started PHP-FPM service" 

# Define the crond service with its allowed parameters.
service "crond" do
  supports :status => true, :restart => true, :reload => true
end

#Chef::Log.info "MIK-SETUP::start End of mik-setup::start.rb" 


Chef::Log.info "AC-SETUP:: restarting nginx &  php-fpm"
execute "restart nginx" do
    command "service nginx restart"
    retries 1
end

case node['platform']
    when 'debian', 'ubuntu'
        execute "restart php7.0-fpm" do
            command "service php7.0-fpm restart"
            retries 1
        end 
    when 'redhat', 'centos', 'fedora', 'amazon'
        execute "restart php-fpm" do
            command "service php-fpm restart"
            retries 1
        end
end
