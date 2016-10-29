define :laravel do
    Chef::Log.info "AC-DEPLOY::main:laravel entered"
    # Create variables based on parameters passed.
    application  = params[:application_name]
    release_path = params[:release_path]

    # Create the app.php file for Laravel based on the template if it exists. If
    # it does not exist, then it will just skip it.
    #template "#{release_path}#{node[:deploy][application][:code_path]}/.env" do
    if(File.exists?("#{release_path}#{node[:deploy][application][:code_path]}/src/env.erb")) 
        Chef::Log.info "AC-DEPLOY: env.erb exists, creating .env file using vars"
        Chef::Log.info("DB_HOST: #{node[:deploy][application][:environment_variables][:DB_HOST]}")
        Chef::Log.info("DB_USERNAME: #{node[:deploy][application][:environment_variables][:DB_USERNAME]}")
        Chef::Log.info("DB_DATABASE: #{node[:deploy][application][:environment_variables][:DB_DATABASE]}")
    end

    # Create .env file based off environment variables & defaults
    
    template "#{release_path}#{node[:deploy][application][:code_path]}/src/.env" do  
        local true
        source "#{release_path}#{node[:deploy][application][:code_path]}/src/env.erb"
        owner "root"
        group "root"
        mode 0644
        variables :application => node[:deploy][application] 
        only_if { File.exists?("#{release_path}#{node[:deploy][application][:code_path]}/src/env.erb") }
    end

    # If there's no vendors folder and composer is present, attempt composer install.
    # TODO Check if src/ exists, if not check if #{release_path}/composer.json exists and install in the appropriate section
    if (File.exists?("#{release_path}/src/composer.json")) # TODO This will fail if the stuff isn't in src/

        # Delete the default PHP-FPM pool configuration because the default one is not
        # required. Instead, create one based on the template in this cookbook.
        if (File.exists?("#{release_path}/src/composer.lock"))
            Chef::Log.info "AC-deploy: Laravel - found composer.lock file. DELETING IT"
            file "#{release_path}/composer.lock" do
                action :delete
            end
        end

        if (File.exists?("#{release_path}/src/public/.htaccess"))
            Chef::Log.info "AC-deploy: Laravel - found .htaccess file. DELETING IT"
            file "#{release_path}/src/public/.htaccess" do
                action :delete
            end
        end 


#Chef::Log.info "AC-DEPLOY: run composer commands - current user: #{node['current_user']}"
#Chef::Log.info "AC-DEPLOY: run composer commands - user should be: #{node[:deploy][application][:user_name]}"
Chef::Log.info "AC-DEPLOY: run composer release path #{release_path}/src"

		#TODO: ensure directories exist and have correct permissions??

        update_flags = "--no-scripts"  
        # run install with flags generated above 
        Chef::Log.info "Running composer update with flags #{update_flags}"
        execute "composer update" do
	    user "#{node[:deploy][application][:user_name]}" #added to ensure correct user
            cwd "#{release_path}/src" # TOD
            command "composer #{update_flags} update"
            ignore_failure true #false
        end

        Chef::Log.info "Running composer dump-autoload"
        execute "composer dump-autoload" do
	    user "#{node[:deploy][application][:user_name]}" #added to ensure correct user
            cwd "#{release_path}/src" # TOD
            command "composer dump-autoload"
            ignore_failure false
        end


        install_flags = "--optimize-autoloader"  
        # run install with flags generated above 
        Chef::Log.info "Running composer install with flags #{install_flags}"
        execute "composer install" do
            cwd "#{release_path}/src"
            command "composer #{install_flags} install"
            ignore_failure false
            creates "#{release_path}/src/composer.lock" 
        end
        
        
        Chef::Log.info "AC-DEPLOY: completed Laravel deploy"
    end
end
