# Timezone symlink file to force a new symlink on the /etc/localtime file. 
execute "set timezone" do
    command "ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime"
end 

package "unzip" 
include_recipe "ac-setup::kernel"
include_recipe "ac-setup::nginx"
include_recipe "ac-setup::php"
include_recipe "ac-setup::composer"
include_recipe "ac-setup::start"
