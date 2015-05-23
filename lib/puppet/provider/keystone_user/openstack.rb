require 'csv'
require 'puppet/provider/keystone'
Puppet::Type.type(:keystone_user).provide(
    :openstack,
    :parent => Puppet::Provider::Keystone
) do

    desc "Provider to manage keystone users"

    confine :osfamily => 'debian'

    commands :openstack => '/usr/bin/openstack'

    def bool_to_sym(bool)
        bool == true ? :true : :false
    end

    def exists?
        @property_hash[:ensure] == :present
    end

    def email=(value)
        token = get_admin_token
        os_url = get_admin_endpoint
        openstack('--os-url',os_url,'--os-token',token,'user','set','--email',value,resource[:name])
    end

    def email
        instance(resource[:name])[:email]
    end

    #def password=(value)
    #    token = get_admin_token
    #    os_url = get_admin_endpoint
    #    openstack('--os-url',os_url,'--os-token',token,'user','set','--password',value,resource[:name])
    #end

    #def password
    #    instance(resource[:name])[:password]
    #end

    def id
        instance(resource[:name])[:id]
    end

    def sym_to_bool(sym)
        sym == :true ? true : false
    end

    def enabled=(value)
        token = get_admin_token
        os_url = get_admin_endpoint
        is_enabled = sym_to_bool(value)
        if is_enabled == true
            openstack('--os-url',os_url,'--os-token',token,'user','set','--enable',resource[:name])
        else
            openstack('--os-url',os_url,'--os-token',token,'user','set','--disable',resource[:name])
        end
    end

    def enabled
        bool_to_sym(instance(resource[:name])[:enabled])
    end

    def create
        token = get_admin_token
        os_url = get_admin_endpoint
        openstack('--os-url',os_url,'--os-token',token,'user','create','--password',resource[:password],'--email',resource[:email],resource[:name])
        @property_hash[:ensure] = :present
    end

    def destroy
        token = get_admin_token
        os_url = get_admin_endpoint
        id = instance(resource[:name])[:id]
        openstack('--os-url',os_url,'--os-token',token,'user','delete',id)
        @property_hash.clear
    end

    def self.instances
        token = get_admin_token
        os_url = get_admin_endpoint
        users = openstack('--os-url',os_url,'--os-token',token,'user','list','--long','-f','csv')
        users = CSV.parse(users)
        users.shift
        users.collect do |user|
            new(
                :name => user[1],
                :ensure => :present,
                :enabled => user[4].downcase.chomp == 'true' ? true : false,
                :email => user[3],
                :id => user[0]
            )
        end
    end

    def self.prefetch(resources)
        users = instances
        resources.keys.each do |name|
            if provider = users.find{ |openstack| openstack.name == name }
                resources[name].provider = provider
            end
        end
    end

    def instances
        token = get_admin_token
        os_url = get_admin_endpoint
        users = openstack('--os-url',os_url,'--os-token',token,'user','list','--long','-f','csv')
        users = CSV.parse(users)
        users.shift
        users.collect do |user|
            {
                :name => user[1],
                :enabled => user[4].downcase.chomp == 'true' ? true : false,
                :email => user[3],
                :id => user[0]
            }
        end
    end

    def instance(name)
        @instance ||= instances.select { |instance| instance[:name] == name }.first || {}
    end

    def flush
    end

end
