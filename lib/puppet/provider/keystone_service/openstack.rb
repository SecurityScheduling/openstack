require 'csv'
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_service).provide(
    :openstack,
    :parent => Puppet::Provider::Keystone
) do

    desc "Provider to manage keystone services."


    confine :osfamily => :debian

    commands :openstack => '/usr/bin/openstack'


    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        service = resource[:name]
        type = resource[:type]
        description = resource[:description]
        token = get_admin_token
        os_url = get_admin_endpoint
        openstack('--os-url',os_url,'--os-token',token,'service','create','--name',service,'--description',"#{description}",type)
        @property_hash[:ensure] = :present 
    end

    def destroy
        service = resource[:name]
        token = get_admin_token
        os_url = get_admin_endpoint
        openstack('--os-url',os_url,'--os-token',token,'service','delete',service)
        @property_hash.clear
    end

    def self.instances
        token = get_admin_token
        os_url = get_admin_endpoint
        services = openstack('--os-url',os_url,'--os-token',token,'service','list','-f','csv')
        services = CSV.parse(services)
        services.shift
        services.collect do |line|
            name = line[1]
            new(:name => name,
                :ensure => :present,
               )
        end
    end

    def self.prefetch(resources)
        services = instances
        resources.keys.each do |name|
            if provider = services.find{ |openstack| openstack.name == name }
                resources[name].provider = provider
            end
        end
    end

end
