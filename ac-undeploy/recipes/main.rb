node[:deploy].each do |application, deploy|
  if !deploy[:application]
    next
  end

  # Set the filename variable based on the document root. If a sub-directory
  # has been specified, then replace the '/' with '-' to keep it as a file.
  filename = deploy[:document_root].sub("/", "-")

  # Delete the Nginx site configuration file and issue an immediate reload.
  file "#{node[:setup][:nginx][:site_dir]}/#{filename}.conf" do
    action :delete
  end
  #
  # Set the filename variable based on the document root. If a sub-directory
  # has been specified, then replace the '/' with '-' to keep it as a file.
  filename = deploy[:document_root].sub("/", "-")

  # Delete the PHP-FPM site configuration file and issue an immediate reload.
  file "#{node[:setup][:php][:site_dir]}/#{filename}.conf" do
    action :delete
  end

  if !deploy[:application] or deploy[:document_root].empty?
    next
  end

  # Delete the document root from the system recursively.
  directory "#{node[:setup][:nginx][:www_dir]}/#{deploy[:document_root]}" do
    recursive true
    action :delete
  end

  # Delete the application user from the system.
  user "#{deploy[:user_name]}" do
    action :remove
  end

  # Delete the application group from the system.
  group "#{deploy[:group_name]}" do
    action :remove
  end

  # has been specified, then replace the '/' with '-' to keep it as a file.
  filename = deploy[:document_root].sub("/", "-")

  # Remove any old crons beginning with the filename. As the removed crons
  # cannot be detected, it is easier to remove them all and create them again.
  execute "delete old crons" do
    command "rm -f #{node[:setup][:cron][:cron_dir]}/#{filename}-*"
  end 
  Chef::Log.info "Finished undeploying application"

  Chef::Log.info "AC-UNDEPLOY:: restarting nginx &  php-fpm" 
  execute "reload nginx" do
      command "service nginx reload"
      retries 1
  end
  execute "reload php-fpm" do
      command "service php-fpm reload"
      retries 1
  end 
 
end
