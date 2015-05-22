require 'csv'
require 'puppet/util/inifile'
Puppet::Type.type(:keystone_project).provide(
    :openstack,
    :parent => Puppet::Provider::Keystone
) do

    desc "Provider to manager keystone projects"

    confine :osfamily => :debian

    commands :openstack => '/usr/bin/openstack'

    def bool_to_sym(bool)
        bool == true ? :true : :false
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def enabled=(value)
        @property_flush[:enabled] = value
    end

    def enabled
        bool_to_sym(instance(resource[:name])[:enabled])
    end

    def description=(value)
        @property_flush[:description] = value
    end

    def description
        instance(resource[:name])[:description]
    end

    def id
        instance(resource[:name])[:id]
    end

    def create
        token = get_admin_token
        os_url = get_admin_endpoint
        openstack('--os-url',os_url,'--os-token',token,'project','create','--description',resource[:description],resource[:name])
        @property_hash[:ensure] = :present
    end

    def destroy
        token = get_admin_token
        os_url = get_admin_endpoint
        id = instance(resource[:name])[:id]
        openstack('--os-url',os_url,'--os-token',token,'project','delete',id)
        @property_hash.clear
    end

    def self.instances
        token = get_admin_token
        os_url = get_admin_endpoint
        projects = openstack('--os-url',os_url,'--os-token',token,'project','list','--long','-f','csv')
        projects = CSV.parse(projects)
        projects.shift
        projects.collect do |project|
            new(
                :name => project[1],
                :ensure => :present,
                :enabled => project[3].downcase.chomp == 'true' ? true : false,
                :description => project[2],
                :id => project[0]
            )
        end
    end

    def self.prefetch(resources)
        projects = instances
        resources.keys.each do |name|
            if provider = projects.find{ |openstack| openstack.name == name }
                resources[name].provider = provider
            end
        end
    end

    def instances
        token = get_admin_token
        os_url = get_admin_endpoint
        projects = openstack('--os-url',os_url,'--os-token',token,'project','list','--long','-f','csv')
        projects = CSV.parse(projects)
        projects.shift
        projects.collect do |project|
            { 
                :name => project[1],         
                :enabled => project[3].downcase.chomp == 'true' ? true : false,
                :description => project[2],
                :id => project[0]
            }
        end
    end

    def instance(name)
        @instance ||= instances.select { |instance| instance[:name] == name }.first || {}
    end

    def flush
    end

end
