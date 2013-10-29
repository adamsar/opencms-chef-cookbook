#
# Cookbook Name:: opencms
# Recipe:: default
#
# Copyright 2013, Andrew Adams
#
# All rights reserved - Please redistribute
#

#Delete the tomcat administrator webapp
service "tomcat" do
  action :stop
end

#Reusable vars for the app
tbase = node['tomcat']['webapp_dir']
obase = "#{tbase}/ROOT/WEB-INF"
tuser = node['tomcat']['user']
tgroup = node['tomcat']['group']
standard_mode = "0664"

#Get rid of the manager, etc
directory "#{tbase}/ROOT" do
  action :delete
  recursive true
  not_if do
    File.exists?("#{tbase}/opencms.zip")
  end
end

file "#{tbase}/ROOT.war" do
  action :delete
end

#We need unzip to use opencms.zip
package "unzip" do
  action :install
end

remote_file "#{tbase}/opencms.zip"  do
  source node['opencms']['url']
  owner tuser
  group tgroup
  mode standard_mode
  action :create_if_missing
end

bash "unzip_opencms" do
  cwd tbase
  user tuser
  code <<-EOH
    unzip opencms.zip
    mv *.war ROOT.war
  EOH
  timeout 60*2 #Two minutes to unzip
  creates "#{tbase}/ROOT"
  notifies :restart, "service[tomcat]", :immediately
  not_if do
    File.exists?("#{obase}/config/opencms.properties")
  end
end

bash "wait_for_tomcat_to_unpackage" do
  code "sleep 5"
end

#Copy over the correct opencms files
template "#{tbase}#{node['opencms']['base_dir']}/config/opencms.properties" do
  owner tuser
  group tgroup
  mode standard_mode
  source "opencms.properties.erb"
end

template "#{tbase}#{node['opencms']['base_dir']}/cmsshell.sh" do
  owner tuser
  group tgroup
  mode standard_mode
  source "cmsshell.sh.erb"
end

#Create the database for use
cookbook_file "#{obase}/create_database.sql" do
  owner tuser
  group tgroup
  mode standard_mode
  source "create_database.sql"
end

bash "create_database" do
  user tuser
  cwd obase
  code "mysql -u root --password='#{node['mysql']['server_root_password']}' < create_database.sql"
end

cookbook_file "#{obase}/bootstrap.sql" do  
  owner tuser
  group tgroup
  mode standard_mode
  source "bootstrap.sql"
end

bash "create_tables" do
  user tuser
  cwd obase
  code "mysql -u root --password='#{node['mysql']['server_root_password']}' opencms < bootstrap.sql"
end

bootstrap_file = "#{obase}/setupdata/bootstrap.txt"
do_bootstrap = !File.exists?(bootstrap_file)
cookbook_file bootstrap_file do
  owner tuser
  group tgroup
  mode standard_mode
  source "cmssetup_bootstrap.txt"
  not_if !do_bootstrap
end


cookbook_file "#{tbase}#{node['opencms']['base_dir']}/setupdata/cmssetup_solr.txt" do
  owner tuser
  group tgroup
  mode standard_mode
  source "cmssetup_solr.txt"
  not_if !do_bootstrap
end

cookbook_file "#{tbase}#{node['opencms']['base_dir']}/setupdata/cmssetup_solr_online.txt" do
  owner tuser
  group tgroup
  mode standard_mode
  source "cmssetup_solr_online.txt"
  not_if !do_bootstrap
end

bash "install_cms_bootstrap" do
  user tuser
  cwd obase
  code "sh cmsshell.sh -script=setupdata/bootstrap.txt"
  not_if !do_bootstrap
end

if do_bootstrap then
  node['opencms']['modules'].each do |mod|

    cookbook_file "#{obase}/setupdata/#{mod}.txt" do
      owner tuser
      group tgroup
      mode standard_mode
      source "modules/#{mod}.txt"
    end
    
    bash "install_#{mod}" do
      user "root"
      cwd obase
      code "sh cmsshell.sh -script=setupdata/#{mod}.txt"
    end
    
  end
end


bash "index_to_solr_offline" do
  user tuser
  cwd "#{tbase}#{node['opencms']['base_dir']}"
  code "sh cmsshell.sh -script=setupdata/cmssetup_solr.txt"
  not_if !do_bootstrap
end

bash "index_to_solr_online" do
  user tuser
  cwd "#{tbase}#{node['opencms']['base_dir']}"
  code "sh cmsshell.sh -script=setupdata/cmssetup_solr_online.txt"
  not_if !do_bootstrap
end

#configure opencms
template "#{tbase}/ROOT/WEB-INF/config/opencms-importexport.xml" do
  owner tuser
  group tgroup
  mode standard_mode
  source "opencms-importexport.xml.erb"
end

template "#{tbase}/ROOT/WEB-INF/config/opencms-system.xml" do
  owner tuser
  group tgroup
  mode standard_mode
  source "opencms-system.xml.erb"
end

#Make sure tomcat owns its folder
directory obase do
  owner tuser
  group tgroup
  mode standard_mode
  recursive true
  action :nothing
end

template "#{node['nginx']['dir']}/sites-enabled/server.conf" do
  source "nginx.config.erb"
  notifies :restart, "service[nginx]"
end

template "#{node['tomcat']['base']}/conf/server.xml" do
  source "server.xml.erb"
  owner tuser
  group tgroup
  mode standard_mode
  notifies :restart, "service[tomcat]"
end
