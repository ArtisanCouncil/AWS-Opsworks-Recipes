define :writable do
  deploy = params[:deploy_data]
  release_path = params[:release_path]

  if deploy[:writable]
    deploy[:writable].each do |writable|
      directory "#{release_path}#{node[:deploy][application][:code_path]}/#{writable}" do
        owner node[:deploy][application][:user_name]
        group node[:deploy][application][:group_name]
        mode 0777
      end
    end
  end

end
