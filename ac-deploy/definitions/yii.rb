
define :yii do

  Chef::Log.info "AC-DEPLOY::main:yii entered"

  # Create variables based on parameters passed.
  application  = params[:application_name]
  release_path = params[:release_path]

  # Check if Yii is being used by the application. If it's not being used then
  # there's no point in adding the Yii framework symlink.
  if (File.exists?("#{release_path}/src/index.php") && File.readlines("#{release_path}/src/index.php").grep(/Yii::createWebApplication/).size > 0) || node[:deploy][application][:yii][:force] == true

    Chef::Log.info "AC-DEPLOY::main:yii Entered If statement, So this is a Yii app"

    if node[:deploy][application][:yii][:location].kind_of?(Array)

      node[:deploy][application][:yii][:location].each do |dir|
        link "#{release_path}#{node[:deploy][application][:code_path]}/#{dir}" do
          to "#{node[:setup][:framework][:yii][:path]}/#{node[:deploy][application][:yii][:version]}"
        end
      end

    else

      link "#{release_path}#{node[:deploy][application][:code_path]}/#{node[:deploy][application][:yii][:location]}" do
        to "#{node[:setup][:framework][:yii][:path]}/#{node[:deploy][application][:yii][:version]}"
      end

    end

  #end

  #if File.exists?("#{release_path}/src/index.php") && File.readlines("#{release_path}/src/index.php").grep(/Yii::createWebApplication/).size > 0

    # Create the assets cache directory on the shared filesystem. If this does
    # not exist, then the symlink will not work and the CMS will not run.
    #directory "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/assets" do
      #owner "root"
      #group "root"
      #mode 0777
      #recursive true
    #end

    # Create the runtime cache directory on the shared filesystem. If this
    # does not exist, then the symlink will not work and the CMS will not run.
    #directory "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/protected/runtime" do
      #owner "root"
      #group "root"
      #mode 0777
      #recursive true
    #end

    # Delete the existing assets and runtime cache directory in the application
    # directory as many repositories include this by default. However, a symlink
    # cannot be created over the top of an existing directory.
    #directory "#{release_path}#{node[:deploy][application][:code_path]}/assets" do
      #recursive true
      #action :delete
      #only_if { File.exist?("#{release_path}#{node[:deploy][application][:code_path]}/assets") }
    #end

    #directory "#{release_path}#{node[:deploy][application][:code_path]}/protected/runtime" do
      #recursive true
      #action :delete
      #only_if { File.exist?("#{release_path}#{node[:deploy][application][:code_path]}/protected/runtime") }
    #end

    # Create the symlink for the assets cache directory which links to the
    # shared filesystem.
    #link "#{release_path}#{node[:deploy][application][:code_path]}/assets" do
      #to "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/assets"
    #end

    # Create the symlink for the runtime cache directory which links to the
    # shared filesystem.
    #link "#{release_path}#{node[:deploy][application][:code_path]}/protected/runtime" do
      #to "#{node[:setup][:nfs][:target]}/#{node[:deploy][application][:document_root]}/protected/runtime"
    #end

    # Create the global configuration file for the application based on the
    # ERB template in the code repository. This can use variables specified
    # in the JSON string from OpsWorks. It will first check to see if one exists
    # for the specific application before using the default.
    if File.exist?("#{release_path}#{node[:deploy][application][:code_path]}/protected/config/#{application}.erb")
      config_source = "#{release_path}#{node[:deploy][application][:code_path]}/protected/config/#{application}.erb"
      
      Chef::Log.info "AC-DEPLOY: Entered If statement,#{release_path}#{node[:deploy][application][:code_path]}/protected/config/#{application}.erb exist so setting it to config_source"
    else
      config_source = "#{release_path}#{node[:deploy][application][:code_path]}/protected/config/main.erb"
      Chef::Log.info "AC-DEPLOY: Entered If statement,#{release_path}#{node[:deploy][application][:code_path]}/protected/config/#{application}.erb does not exist so setting #{release_path}#{node[:deploy][application][:code_path]}/protected/config/main.erb to config_source"
    end

    template "#{release_path}#{node[:deploy][application][:code_path]}/protected/config/main.php" do
      local true
      source config_source
      owner "root"
      group "root"
      mode 0644
      variables ({:application => {
                  :base_path => "#{release_path}/src",
                  :db => {
                    :host => node[:deploy][application][:database][:host],
                    :name => node[:deploy][application][:database][:database],
                    :pass => node[:deploy][application][:database][:password],
                    :user => node[:deploy][application][:database][:username]
              }}})
      only_if { File.exists?("#{config_source}") }
    end

    # Create the document index file for the application based on the ERB
    # template in the code repository. This can use variables specified in the
    # JSON string from OpsWorks.
    template "#{release_path}#{node[:deploy][application][:code_path]}/index.php" do
      local true
      source "#{release_path}#{node[:deploy][application][:code_path]}/index.erb"
      owner "root"
      group "root"
      mode 0644
      #variables ({:application => node[:deploy][application]}) 
      variables :application => node[:deploy][application] 
      only_if { File.exists?("#{release_path}#{node[:deploy][application][:code_path]}/index.erb") }
    end

  else

    log "message" do
      message "AC-DEPLOY: Yii cannot be found in the index.php file, so assuming Yii is not being used."
      level :info
    end

  end

end
