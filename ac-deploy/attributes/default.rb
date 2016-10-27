# Include the attributes set in the ac-setup cookbook as it specifies the
# directories used for the applications. Any changes should be made globally,
# but ensure that there are no applications deployed before making changes.

# Iterate through the applications data passed by OpsWorks.
node[:deploy].each do |application, deploy|

  # Set the default application name. AWS OpsWorks does not pass this, so if it
  # is not set manually, then just use the application shortname.
  default[:deploy][application][:name] = application

  # Set the default port number for the web application. If this is modified,
  # ensure the load balancer is equipped to handle the port.
  default[:deploy][application][:nginx][:port] = node[:setup][:nginx][:port]

  # Set the default log and session directories for the application. If using
  # a multi-node cluster, it is a requirement to use database sessions or there
  # will be inconsistencies when dealing with session data.
  default[:deploy][application][:log_dir]     = "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}/logs"
  default[:deploy][application][:session_dir] = "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}/sessions"

  # Set a sub-directory for the source code in the repository if necessary.
  default[:deploy][application][:code_path] = "" # Not needed for soda right now #TODO figure dis out with a file check

  # Determine if there is a document sub-root, which is sometimes needed if the
  # application is not in the top-level of the code repository. If no sub-root
  # is specified, then the document root should be used.
  default[:deploy][application][:current_path]   = "#{node[:deploy][application][:document_root]}/current#{node[:deploy][application][:code_path]}"

  # Set a base path for any applications that require it.
  default[:deploy][application][:base_path] = "#{node[:setup][:nginx][:www_dir]}/#{default[:deploy][application][:current_path]}"

  if deploy[:document_subroot]
    default[:deploy][application][:nginx][:root] = "#{node[:setup][:nginx][:www_dir]}/#{default[:deploy][application][:current_path]}/#{node[:deploy][application][:document_subroot]}"
  else
    default[:deploy][application][:nginx][:root] = "#{node[:setup][:nginx][:www_dir]}/#{default[:deploy][application][:current_path]}"
  end

  # Set the default document indexes in the order of priority, starting at the
  # top. This can be changed if the application requires something different.
  default[:deploy][application][:nginx][:index] = [ "index.html",
                                                    "index.htm",
                                                    "index.php" ]

  default[:deploy][application][:nginx][:timeout] = 60

  # Set the default location of the log files for the application. This can be
  # modified, but is recommended to leave as default for consistency.
  default[:deploy][application][:nginx][:access_log] = "#{node[:deploy][application][:log_dir]}/www-access_log"
  default[:deploy][application][:nginx][:error_log]  = "#{node[:deploy][application][:log_dir]}/www-error_log"

  # Set custom headers to identify the application node serving the request and
  # any other custom requirements for the application.
  default[:deploy][application][:nginx][:headers]['X-Served-By'] = "#{node[:opsworks][:instance][:hostname]}"

  # Set the default arguments in the location blocks. Additional location blocks
  # can easily be added in the array if you require custom rewrite rules etc.
  default[:deploy][application][:nginx][:location]["/"][:autoindex]        = "off"
  default[:deploy][application][:nginx][:location]["/"][:try_files]        = "$uri $uri/ /index.php?$args"
  #default[:deploy][application][:nginx][:location]["^~ /messages/"][:root] = "/usr/share/nginx/html"

  # Set the default name for the PHP-FPM socket file.
  default[:deploy][application][:php][:socket_name] = "php-fpm.#{node[:deploy][application][:document_root]}.sock".gsub("/", "-")

  # Specify the default process configuration for PHP-FPM. This should be
  # adjusted if an application requires capacity for a larger amount of traffic,
  # or even if it only receives little traffic.
  # TODO Make this generated based off max memory/cpu cores 
  #default[:deploy][application][:php][:max_children]      = 30
  #default[:deploy][application][:php][:start_servers]     = 5
  #default[:deploy][application][:php][:min_spare_servers] = 5
  #default[:deploy][application][:php][:max_spare_servers] = 10
  default[:deploy][application][:php][:max_requests]      = 300

  # Set the default slow log timeout. This can be increased or decreased for
  # debugging performance implications on applications.
  default[:deploy][application][:php][:slowlog_timeout] = "5s"

  # Set any php_flag variables and their value. Acceptable values for php_flag
  # are: on, off, 0, 1.
  default[:deploy][application][:php][:php_flag][:display_errors] = "on"

  # Set any php_value variables and their value. Acceptable values for php_value
  # can be any integer or string, depending on the variable specification.
  default[:deploy][application][:php][:php_value]["session.save_handler"] = "files"
  default[:deploy][application][:php][:php_value]["session.save_path"]    = "#{node[:deploy][application][:session_dir]}"

  # Set any php_admin_flag variables and their value. The php_admin_flag
  # variables will permanently enforce the flag and not allow user override.
  # Acceptable values for php_admin_flag are: on, off, 0, 1.
  # TODO Show errors on stage hide them on prod
  default[:deploy][application][:php][:php_admin_flag][:log_errors] = "on"

  # Set any php_admin_value variables and their value. The php_admin_value
  # variables will permanently enforce the value and not allow user override.
  # Acceptable values for php_admin_value can be any integer or string,
  # depending on the variable specification.
  default[:deploy][application][:php][:php_admin_value][:memory_limit] = "256M"
  default[:deploy][application][:php][:php_admin_value][:error_log]    = "#{node[:deploy][application][:log_dir]}/php-error_log"

  if node[:setup][:environment]
    default[:deploy][application][:php][:php_admin_value]['newrelic.appname'] = "\"#{node[:deploy][application][:name]} (#{node[:setup][:environment].capitalize})\""
  else
    default[:deploy][application][:php][:php_admin_value]['newrelic.appname'] = "\"#{node[:deploy][application][:name]}\""
  end

  # Set application debug to be off. This is generally just a true or false
  # value which can be used in a template. It needs to manually be added to the
  # .ERB file in your code repository.
  default[:deploy][application][:debug] = "false"

  # Set the home directory for the application. This should always be the root
  # application directory. Overriding this may cause permission issues.
  default[:deploy][application][:home_dir] = "#{node[:setup][:nginx][:www_dir]}/#{node[:deploy][application][:document_root]}"

  # If the application has a user and group ID set in the JSON string, then
  # set the username to be the application shortname. If no user or group ID has
  # been specified, then use the Nginx default user.

  #Chef::Log.info "AC-Deploy: Setting Application ID, username & groupname to: " << application[0, 32]
  default[:deploy][application][:id]         =
  default[:deploy][application][:user_name]  = application[0, 32]
  default[:deploy][application][:group_name] = application[0, 32]

  default[:deploy][application][:environment_variables][:APP_ENV] = node[:setup][:environment] || 'production'
  default[:deploy][application][:environment_variables][:APP_DEBUG] = false
  default[:deploy][application][:environment_variables][:APP_KEY] = "0SAbvRlKBd3lOinFLLWPOkFDcN83sEpL"

  default[:deploy][application][:environment_variables][:CACHE_DRIVER] = "file"
  default[:deploy][application][:environment_variables][:SESSION_DRIVER] = "database"
  default[:deploy][application][:environment_variables][:QUEUE_DRIVER] = "sync"

	#TODO: update settings to Artisan Council account
 	#Mail settings
  default[:deploy][application][:environment_variables][:MAIL_DRIVER] = "smtp"
  default[:deploy][application][:environment_variables][:MAIL_HOST] = "email-smtp.us-west-2.amazonaws.com"
  default[:deploy][application][:environment_variables][:MAIL_PORT] = "587"
  default[:deploy][application][:environment_variables][:MAIL_USERNAME] = "AKIAJDPAUEPYEKLQKIYQ"
  default[:deploy][application][:environment_variables][:MAIL_PASSWORD] = "Ancl370NZ/6rOBgtWyiRxgVbidhdTp5GX+L0kHS4DQ4t"

	#database settings
  default[:deploy][application][:environment_variables][:DB_HOST] = deploy[:database][:host] rescue "prod-db.cf6zjaksexix.us-west-1.rds.amazonaws.com"
  default[:deploy][application][:environment_variables][:DB_DATABASE] = deploy[:database][:database] rescue ""
  default[:deploy][application][:environment_variables][:DB_USERNAME] = deploy[:database][:username] rescue "root"
  default[:deploy][application][:environment_variables][:DB_PASSWORD] = deploy[:database][:password] rescue "b055"

	#AWS settings
  default[:deploy][application][:environment_variables][:AWS_ACCESS_KEY_ID] = "AKIAJDAJOYN7L77X7WSQ"
  default[:deploy][application][:environment_variables][:AWS_SECRET_ACCESS_KEY] = "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"
  default[:deploy][application][:environment_variables][:AWS_REGION] = "us-east-1"
end
