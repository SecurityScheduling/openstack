File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
require 'uri'
Puppet::Type.newtype(:keystone_endpoint) do

    desc 'keystone_endpoint is used to create a new service endpoint in openstack keystone.'

    ensurable

    newparam(:name, :namevar => true) do
        desc 'The name of the endpoint "region/servicename".'
        newvalues(/\S+\/\S+/)
    end

    newproperty(:region) do
    end

    newproperty(:public_url) do
    end

    newproperty(:internal_url) do
    end

    newproperty(:admin_url) do
    end

end

