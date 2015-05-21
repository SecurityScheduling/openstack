require 'csv'
require 'puppet/util/inifile'
Puppet::Type.type(:keystone_endpoint).provide(:openstack) do

    desc "Provider to manager keystone endpoints"

    confine :osfamily => :debian

    commands :openstack => '/usr/bin/openstack'

    def self.keystone_file
        return @keystone_file if @keystone_file
        @keystone_file = Puppet::Util::IniConfig::File.new
        @keystone_file.read('/etc/keystone/keystone.conf')
        @keystone_file
    end

    def keystone_file
        self.class.keystone_file
    end

    def self.admin_token
        @admin_token ||= get_admin_token
    end

    def get_admin_token
        self.class.get_admin_token
    end

    def self.get_admin_token
        if keystone_file and keystone_file['DEFAULT'] and keystone_file['DEFAULT']['admin_token']
             return "#{keystone_file['DEFAULT']['admin_token'].strip}"
        else
             return nil
        end
    end

    def self.get_admin_endpoint
        if keystone_file
            if keystone_file['DEFAULT']
                if keystone_file['DEFAULT']['admin_endpoint']
                    auth_url = keystone_file['DEFAULT']['admin_endpoint'].strip.chomp('/')
                    return "#{auth_url}/v2.0/"
                end
                
                if keystone_file['DEFAULT']['admin_port']
                    admin_port = keystone_file['DEFAULT']['admin_port'].strip
                else
                    admin_port = '35357'
                end

                if keystone_file['DEFAULT']['admin_bind_host']
                    host = keystone_file['DEFAULT']['admin_bind_host'].strip
                    if host == "0.0.0.0"
                        host = "127.0.0.1"
                    elsif host == "::0"
                        host = '[::1]'
                    end
                else
                    host = "127.0.0.1"
                end
            end

            protocol = 'http'
        end

        "#{protocol}://#{host}:#{admin_port}/v2.0/"
    end

    def get_admin_endpoint
        self.class.get_admin_endpoint
    end

    def self.admin_endpoint
        @admin_endpoint ||= get_admin_endpoint
    end

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
