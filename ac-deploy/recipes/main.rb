Chef::Log.level = :debug 
#===============================================================================#
# FILE: main.rb
#===============================================================================#
# PURPOSE: Contains the bulk of the instance set up code for instances 
#===============================================================================#
# STEPS TAKEN WHEN SETTING UP NODES:
#   1. Timezone setup
#   2. Request ASPP ID
#
#===============================================================================# 
# 
=begin

Chef::Log.info "AC-DEPLOY::main.rb: Creating /tmp/.ssh & other ssh files"
directory "/tmp/.ssh" do
    action :create
    not_if { File.exist?("/tmp/.ssh") }
end

Chef::Log.info "AC-DEPLOY::main.rb: Creating ssh_deploy_wrapper.sh"
template "/tmp/.ssh/ssh_deploy_wrapper.sh" do
    source "ssh_deploy_wrapper.sh.erb"
    owner "root"
    mode 0770
end



Chef::Log.info "AC-DEPLOY::main.rb: Entering main deploy loop "
# Iterate through the applications passed by OpsWorks.
node[:deploy].each do |application, deploy|
    Chef::Log.info "AC-DEPLOY::main.rb: Creating ssh_deploy_wrapper.sh"
    template "/tmp/.ssh/ssh_deploy_wrapper.sh" do
        source "ssh_deploy_wrapper.sh.erb"
        owner "root"
        mode 0770
    end

    # If the application was not in the JSON string passed by OpsWorks, then it
    # should not be modified in any way.
    if !node[:deploy][application][:application] or node[:deploy][application][:document_root].empty?
        Chef::Log.warn "Skipping application: #{application}"  
        next
    end 

    if defined?node[:deploy][:skip][application] 
        Chef::Log.warn "Skipping application #{application}"
        next
    end

    Chef::Log.info "AC-DEPLOY::main.rb: node #{node} " 
    Chef::Log.info "AC-DEPLOY::main.rb: node.default: #{node.default} " 
    Chef::Log.info "AC-DEPLOY::main.rb: deploy #{deploy} " 
    Chef::Log.info "AC-DEPLOY::main.rb: node.default[:deploy] #{node.default[:deploy]} " 
    Chef::Log.info "AC-DEPLOY::main.rb: node.default[:deploy][application] #{node.default[:deploy][application]} " 
    #
    # fail flag
    node.default[:deploy][application][:fail] = 0

    # Create user and groups for application.
    create_application_ids do
        application_name application
    end

    # Check to make sure the users were created. If they were, then let the
    # process to continue, otherwise move on to the next application.
    if node[:deploy][application][:fail] == 1
        # TODO send email
        Chef::Log.warn "AC-DEPLOY::main.rb: USER OR GROUP FAILED TO CREATE"
        next
    end

    # Create any standard directories for the user now that the user exists
    create_application_dirs do
        application_name application
    end

    # Determine which repository is being used to download the code to the
    # application servers.
    case node[:deploy][application][:scm][:scm_type]
    when "git"

        Chef::Log.info "AC-DEPLOY::main.rb: 2 Creating ssh key file for deployment #{node[:deploy][application][:scm][:ssh_key]} " 
        if node[:deploy][application][:scm][:ssh_key] 
            file "/root/.ssh/id_deploy" do
                content node[:deploy][application][:scm][:ssh_key]
                owner "root"
                group "root"
                mode 0600
            end
        end
    else
        Chef::Log.info "AC-DEPLOY::main.rb: 3 Creating ssh key file for deployment" 
    end


    # Determine which repository is being used to download the code to the
    # application servers.
    if (node[:deploy][application][:scm][:scm_type] == "git" && node[:deploy][application][:scm][:repository])

        deploy_path = node[:setup][:nginx][:www_dir] + "/" + deploy[:document_root] 

        Chef::Log.info "AC-DEPLOY::main.rb: dir=#{node[:setup][:nginx][:www_dir]}" 
        Chef::Log.info "AC-DEPLOY::main.rb: document_root=#{deploy[:document_root]}"
        Chef::Log.info "AC-DEPLOY::main.rb: repository=#{node[:deploy][application][:scm][:repository]}" 
        Chef::Log.info "AC-DEPLOY::main.rb: deploy_path " + deploy_path 

        deploy deploy_path do
            repository node[:deploy][application][:scm][:repository]
            branch node[:deploy][application][:scm][:revision]
            git_ssh_wrapper "/tmp/.ssh/ssh_deploy_wrapper.sh"
            keep_releases 3
            symlink_before_migrate.clear
            create_dirs_before_symlink.clear
            purge_before_symlink.clear
            #rollback_on_error true # TODO test out rolling baqck on errors
            symlinks.clear
            migrate false
            enable_submodules true
            action :deploy

            # When the repository has been deployed, do the following using the
            # variables provided by the deploy definition.
            before_symlink do

                # The release_path is only a local variable and cannot be passed to
                # the yii definition - maybe a bug? To fix this, simply create another
                # variable to hold the string.
                app_release_path = release_path

                # Check to see if Laravel is in the repository and create the template
                # files for the configuration.
                laravel do
                    application_name application
                    release_path app_release_path
                end 

                                # TODO Make this better 
                #   move composer before/after scripts into SH scripts that we can reference here maybe bin/before_deploy.sh 
                # Run the process to check if a deploy script needs to be run or not.
                # This may be required for some web applications like Laravel.
                # For this to execute, #{release_path}/scripts/deploy.sh must be an executable file
                #run_deploy_script do
                #application_name application
                #release_path app_release_path
                #end

                # Trigger the permission change for any writeable directories.
                #writable do
                #deploy_data node[:deploy][application]
                #release_path app_release_path
                #end 
            end

        end

    else
        # By default, create an empty current directory for applications that do not
        # have a code repository.
        Chef::Log.warn "AC-DEPLOY::main.rb: SCM TYPE NOT GIT : #{node[:deploy][application][:scm][:scm_type]} != git"
        directory "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:current_path]}" do
            owner node[:deploy][application][:user_name]
            group node[:deploy][application][:group_name]
            mode 0755
            recursive true
            action :create
        end

    end

    Chef::Log.info "AC-DEPLOY::main fixing application permissions"
    fix_application_perms do
        application_name application
    end

    # Iterate through any symlink requests in the location block object. This will
    # create a symlink for any applications that need to be accessible under its
    # own domain name and a shared domain name.
    # should create files and folders that don't exist. -Si 28/04/2014
    if node[:deploy][application][:nginx][:location]

        log "message" do
            message "AC-DEPLOY: attempting symlink"
            level :info
        end

        node[:deploy][application][:nginx][:location].each do |path, location|
            if location[:symlink]
                log "message" do
                    message "AC-DEPLOY: attempting symlink #{location[:symlink]}"
                    level :info
                end

                mydir = File.dirname("#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}/#{path}")

                unless File.directory?(mydir)
                    log "message" do
                        message "AC-DEPLOY: no dir found. creating"
                        level :info
                    end
                    directory mydir do
                        owner node[:deploy][application][:user_name]
                        group node[:deploy][application][:group_name]
                        mode 0771
                        recursive true
                        action :create
                    end
                end

                link "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}/#{path}" do
                    to "#{node[:setup][:nginx][:www_dir]}/#{location[:symlink]}/current#{node[:deploy][application][:code_path]}"
                end 
            end
        end
    end 

    # Deploy any other custom template files specified in the JSON string from
    # OpsWorks. This allows any application to have its own templates using the
    # deployment variables.
    if node[:deploy][application][:template] 
        node[:deploy][application][:template].each do |template, id|
            template "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:current_path]}/#{id[:destination]}" do
                local true
                source "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:current_path]}/#{id[:source]}"
                owner "root"
                group "root"
                mode 0644
                #variables ({:application => node[:deploy][application]}) 
                #variables ({:application => "#{node[:deploy][application]}"})
                variables :application => node[:deploy][application]
            end
        end 
    end

    #
    # # PHP & Nginx set config up per site
    #
        # Set the filename variable based on the document root. If a sub-directory
    # has been specified, then replace the '/' with '-' to keep it as a file.
    filename = node[:deploy][application][:document_root].sub("/", "-")

    # Create the PHP-FPM site configuration file based on the ERB template.
    template "#{node[:setup][:php][:site_dir]}/#{filename}.conf" do
        source "php-site.conf.erb"
        owner "root"
        mode 0644
        #variables ({:application => node[:deploy][application]}) 
        variables :application => node[:deploy][application]
    end

    # Create the session data directory, if it does not already exist. The owner
    # and group should be set to the same as Nginx as it will be the one that
    # reads from this directory.
    directory "#{node[:deploy][application][:session_dir]}" do
        owner node[:setup][:nginx][:user_name]
        group node[:setup][:nginx][:group_name] 
        mode 0755
        recursive true
        action :create
    end 

    # set template name
    template_name =  node[:setup][:nginx][:site_dir] + "/" + filename + ".conf" 

    # Create the Nginx site configuration file based on the ERB template.
    template template_name do
        source "nginx-site.conf.erb"
        owner "root"
        mode 0644
        #variables ({:application => node[:deploy][application]})
        variables :application => node[:deploy][application]
    end

    # If the log directory does not already exist, which it probably will not,
    # then create it and set the correct permissions.
    directory node[:deploy][application][:log_dir] do
        owner node[:setup][:nginx][:user_name]
        group node[:setup][:nginx][:group_name]
        mode 0755
        recursive true
        action :create
    end

    # Create the access_log file, if it does not already exist, and set the
    # correct permissions.
    file node[:deploy][application][:nginx][:access_log] do
        owner node[:setup][:nginx][:user_name]
        group node[:setup][:nginx][:group_name]
        mode 0640
        action :create
    end

    # Create the error_log file, if it does not already exist, and set the
    # correct permissions.
    file node[:deploy][application][:nginx][:error_log] do
        owner node[:setup][:nginx][:user_name]
        group node[:setup][:nginx][:group_name]
        mode 0640
        action :create
    end


    Chef::Log.info "AC-DEPLOY:: restarting nginx &  php-fpm" 
    execute "reload nginx" do
        command "service nginx reload"
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
        #
end # end of application loop
#
# Define the nginx service with its allowed parameters.
# Remove SSH key disabled for testing 
# If the SSH key exists on the system, remove it for security purposes.
#if File.exists?("/root/.ssh/id_deploy")
#file "/root/.ssh/id_deploy" do
#action :delete
#end
#end 

=end
