module OpencmsCookbookVars

  def opencms_standard_mode
    node['opencms']['standard_mode']
  end

  def opencms_base_dir
    node['tomcat']['webapp_dir'] + "/ROOT/WEB-INF"
  end

end

module OpencmsCookbook

  def run_opencms_sql(script_name, database)
    #Copies over and runs an sql script against the Mymenu database
    bash "run_#{script_name}" do
      user node['tomcat']['user']
      cwd opencms_base_dir
      code "mysql -u root --password='#{node['mysql']['server_root_password']}' #{database} < #{script_name}"
      action :nothing
    end

    cookbook_file "#{opencms_base_dir}/#{script_name}" do
      owner node['tomcat']['user']
      group node['tomcat']['group']
      mode node['opencms']['standard_mode']
      action :create
      notifies :run, "bash[run_#{script_name}]", :immediately
      not_if { File.exists?("#{opencms_base_dir}/#{script_name}") }
    end

  end

  def run_opencms_script(script_name, act=:run)

    bash "cms_run_#{script_name}" do
      cwd opencms_base_dir
      user node['tomcat']['user']
      code "sh cmsshell.sh -script=#{script_name}"
      action act
    end

  end


  def install_opencms_module(file_name)
    #Installs a module of file_name into the OpenCms system
    
    install_script = "setupdata/#{file_name}.txt"
    run_opencms_script(install_script, :nothing)

    #Create cookbook file, if it doesn't exist
    cookbook_file "#{opencms_base_dir}/packages/modules/#{file_name}.zip" do
      owner node['tomcat']['user']
      group node['tomcat']['group']
      mode node['opencms']['standard_mode']
      source "modules/#{file_name}.zip"
      action :create_if_missing
    end

    #Add the install script. This code assumes that
    #if the file exists on the node, then it has also
    #been run. So only run this if the file is not
    #present
    template "#{opencms_base_dir}/#{install_script}" do
      cookbook "opencms"
      owner node['tomcat']['user']
      group node['tomcat']['group']
      mode node['opencms']['standard_mode']
      source "import_module.txt.erb"
      action :create
      notifies :run, "bash[cms_run_#{install_script}]", :immediately
      not_if { File.exists?("#{opencms_base_dir}/#{install_script}") }
      variables({
                  :mod => "#{file_name}.zip"
                })
    end

  end

end


class Chef

  class Recipe
    include OpencmsCookbookVars
    include OpencmsCookbook
  end

  class Resource
    include OpencmsCookbookVars
  end
  
end
