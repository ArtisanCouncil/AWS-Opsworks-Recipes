#case node['platform']
#    when 'debian', 'ubuntu' 
#    package 'httpd' do 
#        action :remove  # TODO THIS COULD ALSO BE HTTPD WTF
#    end
#when 'redhat', 'centos', 'fedora' 
#end
package 'apache2' do 
    action :remove  # TODO THIS COULD ALSO BE HTTPD WTF
end

package "nginx" 

Chef::Log.info "AC-SETUP::main Finished install of nginx" 

# Create the global Nginx configuration based on the template in this cookbook.

case node['platform']
when 'debian', 'ubuntu'
    template "nginx.conf" do
        path "#{node[:setup][:nginx][:conf_dir]}/nginx.conf"
        source "nginx-ubuntu.conf.erb"
        owner "root"
        group "root"
        variables :nginx => node[:setup][:nginx] 
        mode 0644
    end 

when 'redhat', 'centos', 'fedora', 'amazon'
    template "nginx.conf" do
        path "#{node[:setup][:nginx][:conf_dir]}/nginx.conf"
        source "nginx.conf.erb"
        owner "root"
        group "root"
        variables :nginx => node[:setup][:nginx] 
        mode 0644
    end 

end
Chef::Log.info "AC-SETUP::main Created nginx.conf file at /etc/nginx/nginx.conf"

Chef::Log.warn "NGINX USER : #{node[:setup][:nginx][:user_name]}"
Chef::Log.warn "PHP USER : #{node[:setup][:php][:user_name]}"


template ".htpasswd" do
  path "/etc/nginx/.htpasswd"
  source "htpasswd.erb"
  owner "root"
  group "root"
  mode 0644
end 

template "default.conf" do
  path "#{node[:setup][:nginx][:site_dir]}/default.conf"
  source "nginx-default.conf.erb"
  owner "root"
  group "root"
  mode 0644
end 
Chef::Log.info "AC-SETUP::main Created default nginx site config @ /etc/nginx/conf.d/default.conf"

# Add the index.html template to the default root directory for when a domain is
# not yet configured.
template "index.html" do
  path "/usr/share/nginx/html/index.html"
  source "index.html.erb"
  owner "root"
  group "root"
  mode "0644"
end 
