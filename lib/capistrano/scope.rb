# require 'capistrano'
# unless Capistrano::Configuration.respond_to?(:instance)
#   abort "scope requires requires Capistrano 2"
# end


module Scope
  @@servers = Hash.new {|h,k| h[k] = {:ip_address => nil, :roles => [] } }
  
  def task_list
    @@servers.keys.map {|key| "@:#{key}"}
  end

  def role(role, server_name, options={})
    @@servers[server_name][:roles] << {:name => role, :options => options}
  end

  def server(server_name, ip_address)
    @@servers[server_name][:ip_address] = ip_address
  end

  def create_task(name, pattern, ns)
    ns.task(name) do
      set :current_scope, true
      keys = @@servers.keys.grep(/^#{pattern}/)
      
      keys.each do |key|
        ip_address = @@servers[key][:ip_address]
        @@servers[key][:roles].each do |role|
          top.role(role[:name], ip_address, role[:options])
        end
      end
    end
  end
  
  def namespace_task(namespace_list, ns)
    name    = namespace_list.pop
    pattern = "#{ns.fully_qualified_name}:#{name}".sub('@:','')

    if namespace_list.empty?
      create_task name, pattern, ns
    else
      ns.namespace name.to_sym do
      end
      create_task 'all', pattern, ns.namespaces[name.to_sym]
      namespace_task namespace_list, ns.namespaces[name.to_sym]
    end 
  end

  # Execution starts here.
  def create_server_tasks(ns)
    @@servers.keys.each do |name| 
      namespace_task name.split(':').reverse, ns
    end
  end
  
  def all(ns)
    @@servers.each_value do |scope_server|
      scope_server[:roles].each do |role|
        ns.top.role(role[:name], scope_server[:ip_address], role[:options])
      end
    end
  end
  
  def defined_roles(ns)
    ns.top.roles.keys.collect {|r| r.to_s }.sort {|a,b| a <=> b }
  end

  def defined_servers(ns)
    ip_to_name = @@servers.keys.inject({}) do |h,key| 
      h[@@servers[key][:ip_address]] = key
      h
    end
    defined_servers = []
    ns.top.roles.each_value do |defined_role|
      defined_role.servers.each do |server|
        unless defined_servers.include? ip_to_name[server.host]
          defined_servers << ip_to_name[server.host]
        end
      end
    end

    return defined_servers.sort
  end
end
Capistrano.plugin :scope, Scope


Capistrano::Configuration.instance.load do
  namespace '@'.to_sym do

    desc "[internal] create the scope tasks."
    task :create_server_tasks do
      scope.create_server_tasks self
    end

    desc "Scope all defined servers"
    task :all do
      scope.all self
    end
  
    desc "Show the roles and servers defined by this scope."
    task :show do
      puts "Roles:"
      scope.defined_roles(self).each do |defined_role|
        puts "         #{defined_role}"
      end
      puts "Servers:"
      scope.defined_servers(self).each do |defined_server|
        puts "         #{defined_server}"
      end
    end
    
    desc "[internal] Ensure that a stage has been selected."
    task :ensure do
      if !exists?(:current_scope)
        if exists?(:default_scope)
          logger.important "Defaulting to `#{default_scope}'"
          find_and_execute_task(default_scope)
        # else
        #   abort "No scope specified. Please specify one of: #{stages.join(', ')} (e.g. `cap #{stages.first} #{ARGV.last}')"
        end
      end 
    end

  end

  on :load, '@:create_server_tasks'
  on :start, '@:ensure', :except => scope.task_list + ['@:all', '@:create_server_tasks']
end

