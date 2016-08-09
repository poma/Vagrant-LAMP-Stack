#
# Cookbook Name:: app
# Recipe:: db
#
# Credits: David Stanley (https://github.com/davidstanley01/vagrant-chef/)
#

# Install MySQL server & MySQL client
mysql_service 'mysql' do
  port '3306'
  version '5.5'
  initial_root_password node['mysql']['server_root_password']
  action [:create, :start]
end

# Create database if it doesn't exist
ruby_block "create_#{node['app']['name']}_db" do
    block do
        %x[mysql -h 127.0.0.1 -u root -p#{node['mysql']['server_root_password']} -e "CREATE DATABASE #{node['app']['db_name']};"]
    end
    not_if "mysql -h 127.0.0.1 -u root -p#{node['mysql']['server_root_password']} -e \"SHOW DATABASES LIKE '#{node['app']['db_name']}'\" | grep #{node['app']['db_name']}";
    action :create
end

# Load default database if database dump file existing and database is empty
if File.exist?("#{node['app']['db_dump']}")
    ruby_block "seed #{node['app']['name']} database" do
        block do
            %x[mysql -h 127.0.0.1 -u root -p#{node['mysql']['server_root_password']} #{node['app']['db_name']} < #{node['app']['db_dump']}]
        end
        not_if "mysql -h 127.0.0.1 -u root -p#{node['mysql']['server_root_password']} -e \"SHOW TABLES FROM #{node['app']['db_name']}\" | \
            grep 1"
        action :create
    end
end
