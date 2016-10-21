# Create all of the application directories required unless they already exist.
# This should be a default across all applications. Any special directories for
# special purposes can be created in their own recipes.
define :create_application_dirs do

  Chef::Log.info "AC: create_application_dir.rb" 
  
  # Assign variable names to the parameters passed.
  application = params[:application_name]

  # Create user home directory in application partition.
  directory node[:deploy][application][:home_dir] do
    owner node[:deploy][application][:user_name]
    group node[:deploy][application][:group_name]
    mode 0771
    recursive true
    action :create
  end

  # Create logs directory in the application home directory.
  directory node[:deploy][application][:log_dir] do
    owner node[:deploy][application][:user_name]
    group node[:deploy][application][:group_name]
    mode 0770
    action :create
  end

  # If the sessions variable has been set, then create a shared sessions directory.
  if node[:deploy][application][:sessions]

    link node[:deploy][application][:session_dir] do
      action :delete
      only_if { File.symlink?("#{node[:deploy][application][:session_dir]}") }
    end
 
    directory node[:deploy][application][:session_dir] do
      recursive true
      action :delete
      only_if { File.exist?("#{node[:deploy][application][:session_dir]}") }
    end

    directory "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/sessions" do
      owner "root"
      group "root"
      mode 0777
      recursive true
      action :create
      not_if { File.exist?("#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/sessions") }
    end

    link node[:deploy][application][:session_dir] do
      to "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/sessions"
    end

  else

    link node[:deploy][application][:session_dir] do
      action :delete
      only_if { File.symlink?("#{node[:deploy][application][:session_dir]}") }
    end

    # Create sessions directory in application home directory.
    directory node[:deploy][application][:session_dir] do
      owner node[:deploy][application][:user_name]
      group node[:deploy][application][:group_name]
      mode 0770
      action :create
    end

  end


end
