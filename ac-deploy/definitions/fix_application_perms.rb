
define :fix_application_perms do
  
  Chef::Log.info "AC: fix_application_perms.rb" 
  
  # Assign variable names to the parameters passed.
  application = params[:application_name]
  
  # TODO 
  #  Set permissions of /app/application/sessions 
  # Reset permissions of the application files.
  Chef::Log.info "AC-fix_application_errors: find #{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:current_path]} -type f -exec chmod 0664 {} \;"
  execute "reset permissions of application files" do
    command "find #{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:current_path]} -type f -exec chmod 0664 '{}' \\;"
    ignore_failure true
  end

  # Reset permissions of the directories in the application home directory.
  Chef::Log.info "AC-fix_application_errors: find #{node[:deploy][application][:home_dir]} -type d -exec chmod 0775 '{}' \;"
  execute "reset permissions of application files" do
    command "find #{node[:deploy][application][:home_dir]} -type d -exec chmod 0775 '{}' \\; "
    ignore_failure true
  end

  # Reset the permissions of the application home directory.
  Chef::Log.info "AC-fix_application_errors: chmod 0771 #{node[:deploy][application][:home_dir]}"
  execute "reset permissions of application home directory" do
    command "chmod 0771 #{node[:deploy][application][:home_dir]} "
    ignore_failure true
  end

  # Reset the ownership of the application home directory.
  Chef::Log.info "AC-fix_application_errors: chown -Rf #{node[:deploy][application][:user_name]}:#{node[:deploy][application][:group_name]} #{node[:deploy][application][:home_dir]}"
  execute "reset ownership of application home directory" do
    command "chown -R #{node[:deploy][application][:user_name]}:#{node[:deploy][application][:group_name]} #{node[:deploy][application][:home_dir]}"
    ignore_failure true
  end

end
