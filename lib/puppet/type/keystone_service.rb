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

end
