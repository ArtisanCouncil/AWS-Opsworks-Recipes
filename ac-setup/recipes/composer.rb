Chef::Log.info "AC-SETUP::main Attempting to install composer" 
execute "install composer" do
  # cwd "/usr/bin"
  # command "curl -sS https://getcomposer.org/installer | /usr/bin/php -- --install-dir=/usr/bin && mv -f /usr/bin/composer.phar /usr/bin/composer"
  # command "./php -r \"readfile('https://getcomposer.org/installer');\" > composer-setup.php && ./php composer-setup.php --install-dir=/usr/bin --filename=composer && ./php -r \"unlink('composer-setup.php');\""
  command "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin && mv -f /usr/bin/composer.phar /usr/bin/composer"
end
Chef::Log.info "AC-SETUP::main Installed Composer" 

# Set up /root/.composer directory with auth stuff

directory "/root/.composer/" do
    owner "root"
    group "root"
    mode 0771
    recursive true
    action :create
end

template "/root/.composer/auth.json" do
    path "/root/.composer/auth.json"
    source "composer-auth.json.erb"
    owner "root"
    group "root"
    mode 0771
end 

# Schedule the Composer self-updater to run every day. If Composer is not
# automatically updated after 30 days, it will refuse to install until it is
# updated. If this fails, running ac-setup::framework will reinstall it.  
cron "schedule composer self-updater" do 
  minute "0"
  hour "2"
  day "*"
  month "*"
  weekday "*"
  command "/usr/bin/composer self-update > /dev/null 2>&1"
  action :create
end
Chef::Log.info "AC-SETUP::main Installed cronjob for composer self update" 

# install prestimisso to speed up composer installs 
# https://github.com/hirak/prestissimo
#
execute "Install prestissimo for faster composer things" do
    command "composer global require hirak/prestissimo"
    ignore_failure true
end

# add composer config file for prestissimo
template "/root/.composer/config.json" do
    path "/root/.composer/config.json"
    source "composer-config.json.erb"
    owner "root"
    group "root"
    mode 0771
end 

