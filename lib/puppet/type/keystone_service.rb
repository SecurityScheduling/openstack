require 'uri'
Puppet::Type.newtype(:keystone_service) do

    desc 'keystone_service is used to create a new service in openstack keystone.'

    ensurable

    newparam(:name, :namevar => true) do
        desc 'The name of the service.'
    end

    newparam(:type) do
        desc 'The type of the service.'
        newvalues(:identity, :compute, :network, :image)
    end

    newparam(:description) do
        desc 'The description of the service.'
    end

    #newparam(:admin_token) do
    #    desc 'The admin token to connect to the keystone endpoint.'
    #end

    #newparam(:keystone_endpoint) do
    #    desc 'The keystone endpoint for management'
    #    validate do |value|
    #        unless URI.parse(value).is_a?(URI::HTTP)
    #            fail("Invalid endpoint #{value}")
    #        end
    #    end
    #end

    #validate do
    #    fail('type required') if self[:ensure] == :present and self[:type].nil?
    #    fail('admin_token required') if self[:ensure] == :present and self[:admin_token].nil?
    #    fail('keystone_endpoint required') if self[:ensure] == :present and self[:keystone_endpoint].nil?
    #end
end
