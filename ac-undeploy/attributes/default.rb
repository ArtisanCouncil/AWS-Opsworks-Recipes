# Include the attributes set in the ac-setup cookbook as it specifies the
# directories used for the applications. Any changes should be made globally,
# but ensure that there are no applications deployed before making changes.

# Iterate through the applications data passed by OpsWorks stack JSON.
node[:deploy].each do |application, deploy|

  # If the application was not in the JSON string passed by OpsWorks, then it
  # should not be modified in any way.
  if !deploy[:application]
    next
  end

  # Set the home directory variable based on the WWW directory and the
  # application document root.
  default[:deploy][application][:home_dir] = "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}"

  # Set the user and group name to the application name.
  default[:deploy][application][:user_name]  = application[0, 32]
  default[:deploy][application][:group_name] = application[0, 32]

end
