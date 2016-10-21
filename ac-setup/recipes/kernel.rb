# Kernel tweaks for ubuntu
case node['platform']
when 'debian', 'ubuntu' 
    execute "Set more files open per instance" do
        command "sysctl -w fs.file-max=999999"
    end 
    execute "Set more open connections per instance" do
        command "sysctl -w net.core.somaxconn=1024"
    end 
    execute "Set more open backlog connections per instance" do
        command "sysctl -w net.core.netdev_max_backlog=3072"
    end 
end
