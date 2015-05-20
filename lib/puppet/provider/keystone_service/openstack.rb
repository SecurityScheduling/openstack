require 'csv'
require 'puppet/util/inifile'
Puppet::Type.type(:keystone_service).provide(:openstack) do

    desc "Provider to manage keystone services."


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
