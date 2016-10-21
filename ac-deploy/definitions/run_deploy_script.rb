define :run_deploy_script do

  # Create variables based on parameters passed.
  application  = params[:application_name]
  release_path = params[:release_path]

  # Execute the deployment shell script if it exists in the repository. This
  # should contain any post-installation scripts that need to be run to retrieve
  # third-party libraries and so forth.
  execute "run deployment script" do
    command "/bin/sh #{release_path}/scripts/deploy.sh"
    only_if { File.exists?("#{release_path}/scripts/deploy.sh") }
  end

end
