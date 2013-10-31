#
# Cookbook Name:: opencms
# Recipe:: default
#
# Copyright 2013, Andrew Adams
#
# All rights reserved - Please redistribute
#

#Reusable vars for the app
webapp_dir = node['tomcat']['webapp_dir']
tomcat_user = node['tomcat']['user']
tomcat_group = node['tomcat']['group']

#Get rid of the manager directory and WAr
#Opencms will run as ROOT
file "#{webapp_dir}/ROOT.war" do
  action :delete
end

directory "#{webapp_dir}/ROOT" do
  action :delete
  recursive true
  not_if do
    File.exists?("#{webapp_dir}/opencms.zip")
  end
end

#We need unzip to use opencms.zip
package "unzip" do
  action :install
end

opencms_zip = "#{webapp_dir}/opencms.zip"
remote_file opencms_zip  do
  source node['opencms']['url']
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  action :create_if_missing
end

file opencms_zip do  
  action :nothing
end

#Unzip the file, rename to root notify tomcat if it
#wasn't present 
bash "unzip_opencms" do
  cwd webapp_dir
  user tomcat_user
  code <<-EOH
    unzip opencms.zip
    mv *.war ROOT.war
  EOH
  timeout 60 * 2 #Two minutes to unzip
  creates "#{webapp_dir}/ROOT"
  notifies :restart, "service[tomcat]", :immediately
  notifies :delete, "file[#{opencms_zip}]"
  not_if do
    File.exists?("#{opencms_base_dir}/config/opencms.properties")
  end
end

#We may need to wait on slower systems for tomcat
#to unpackage the war
bash "wait_for_tomcat_to_unpackage" do
  code "sleep 5"
end

#Copy over the correct opencms files.
#opencms.properties for property Mysql config
template "#{opencms_base_dir}/config/opencms.properties" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "opencms.properties.erb"
end

#linux friendly cmsshell.sh
template "#{opencms_base_dir}/cmsshell.sh" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "cmsshell.sh.erb"
end

#Create the database for use
cookbook_file "#{opencms_base_dir}/create_database.sql" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "create_database.sql"
end

#Initialize the database
run_opencms_sql("create_database.sql", "")
run_opencms_sql("bootstrap.sql", "opencms")

#Copy and run bootstrap CMS data scripts
cookbook_file "#{opencms_base_dir}/setupdata/cmssetup_bootstrap.txt" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "cmssetup_bootstrap.txt"
end
run_opencms_script("setupdata/cmssetup_bootstrap.txt")

#Install all the base modules 
node['opencms']['modules'].each { |mod| install_opencms_module(mod) }

#Publish everything to Solr
["cmssetup_solr.txt", "cmssetup_solr_online.txt"].each do |script|
  cookbook_file "#{opencms_base_dir}/setupdata/#{script}" do
    owner tomcat_user
    group tomcat_group
    mode opencms_standard_mode
    source script
  end
  run_opencms_script("setupdata/#{script}")
end

#Configure opencms for the current server
template "#{opencms_base_dir}/config/opencms-importexport.xml" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "opencms-importexport.xml.erb"
end

template "#{opencms_base_dir}/config/opencms-system.xml" do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  source "opencms-system.xml.erb"
end

#Make sure tomcat owns its folder
directory opencms_base_dir do
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  recursive true
  action :nothing
end

#Update nginx with proper config
template "#{node['nginx']['dir']}/sites-available/opencms.conf" do
  source "nginx.config.erb"
end

bash "link_to_sites_available" do
  cwd node['nginx']['dir']
  code "ln -s sites-available/opencms.conf sites-enabled/"
  notifies :restart, "service[nginx]"  
end

#Update Tomcat to have the right proxy information and restart
template "#{node['tomcat']['base']}/conf/server.xml" do
  source "server.xml.erb"
  owner tomcat_user
  group tomcat_group
  mode opencms_standard_mode
  notifies :restart, "service[tomcat]"
end
