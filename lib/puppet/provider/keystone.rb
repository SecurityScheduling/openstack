require 'puppet/util/inifile'
require 'puppet'
class Puppet::Provider::Keystone < Puppet::Provider

    initvars
    commands :openstack => 'openstack'

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

        "#{protocol}://#{host}:#{admin_port}/v2.0"
    end

    def get_admin_endpoint
        self.class.get_admin_endpoint
    end

    def self.admin_endpoint
        @admin_endpoint ||= get_admin_endpoint
    end

end
