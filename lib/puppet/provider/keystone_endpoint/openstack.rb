require 'csv'
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_endpoint).provide(
    :openstack,
    :parent => Puppet::Provider::Keystone
) do

    desc "Provider to manager keystone endpoints"

    confine :osfamily => :debian

    commands :openstack => '/usr/bin/openstack'


    def exists?
        @property_hash[:ensure] == :present
    end

    def region
        instance(resource[:name])[:region]
    end

    def public_url=(value)
        @property_flush[:public_url] = value
    end

    def public_url
        instance(resource[:name])[:public_url]
    end

    def internal_url=(value)
        @property_flush[:internal_url] = value
    end

    def internal_url
        instance(resource[:name])[:internal_url]
    end

    def admin_url=(value)
        @property_flush[:admin_url] = value
    end

    def admin_url
        instance(resource[:name])[:admin_url]
    end

    def id
        instance(resource[:name])[:id]
    end

    def create
        region, name = resource[:name].split('/')
        token = get_admin_token
        os_url = get_admin_endpoint
        public_url = resource[:public_url]
        internal_url = resource[:internal_url]
        admin_url = resource[:admin_url]
        openstack('--os-url',os_url,'--os-token',token,'endpoint','create','--publicurl',public_url,'--internalurl',internal_url,'--adminurl',admin_url,'--region',region,'identity')
        @property_hash[:ensure] = :present
    end

    def destroy
        region, name = resource[:name].split('/')
        endpoint = name
        token = get_admin_token
        os_url = get_admin_endpoint
        id = instance(resource[:name])[:id]
        openstack('--os-url',os_url,'--os-token',token,'endpoint','delete',id)
        @property_hash.clear
    end

    def self.instances
        token = get_admin_token
        os_url = get_admin_endpoint
        endpoints = openstack('--os-url',os_url,'--os-token',token,'endpoint','list','--long','-f','csv')
        endpoints = CSV.parse(endpoints)
        endpoints.shift
        endpoints.collect do |line|
            service_name = line[2]
            region = line[1]
            public_url = line[4]
            admin_url = line[5]
            internal_url = line[6]
            new(
                :name => "#{region}/#{service_name}",
                :ensure => :present,
                :id => line[0],
                :region => region,
                :public_url => public_url,
                :internal_url => internal_url,
                :admin_url => admin_url
            )
        end
    end

    def self.prefetch(resources)
        endpoints = instances
        resources.keys.each do |name|
            if provider = endpoints.find{ |openstack| openstack.name == name }
                resources[name].provider = provider
            end
        end
    end

    def instances
        token = get_admin_token
        os_url = get_admin_endpoint
        endpoints = openstack('--os-url',os_url,'--os-token',token,'endpoint','list','--long','-f','csv')
        endpoints = CSV.parse(endpoints)
        endpoints.shift
        endpoints.collect do |line|
            service_name = line[2]
            region = line[1]
            public_url = line[4]
            admin_url = line[5]
            internal_url = line[6]
            { 
                :name => "#{region}/#{service_name}",
                :ensure => :present,
                :id => line[0],
                :region => region,
                :public_url => public_url,
                :internal_url => internal_url,
                :admin_url => admin_url,
            }
        end
    end

    def instance(name)
        @instance ||= instances.select { |instance| instance[:name] == name }.first || {}
    end


end
