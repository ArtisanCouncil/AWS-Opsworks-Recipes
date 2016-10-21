define :create_application_ids do

  # Assign variable names to the parameters passed.
    application = params[:application_name]

    Chef::Log.info "AC-create_application_ids: Creating #{node[:deploy][application][:home_dir]} with #{node[:deploy][application][:user_name]} : #{node[:deploy][application][:group_name]}"

    # create group ID for application
    group "#{node[:deploy][application][:group_name]}" do
        #gid node[:deploy][application][:id]
        only_if { `cat /etc/group | grep -E '^#{node[:deploy][application][:group_name]}:'` }
    end 

    #create user ID for application
    user "#{node[:deploy][application][:user_name]}" do
        #uid node[:deploy][application][:id]
        gid node[:deploy][application][:group_name]
        home "#{node[:deploy][application][:home_dir]}"
        shell "/sbin/nologin"
        only_if { `cat /etc/passwd | grep -E '^#{node[:deploy][application][:user_name]}:'` }
    end 

    # TODO only_if doesn't exist already
    directory node[:deploy][application][:home_dir] do
        owner node[:deploy][application][:user_name]
        group node[:deploy][application][:group_name] 
        mode 0777
        recursive true
        action :create
    end 
end
