Puppet::Type.newtype(:keystone_project) do
    
    desc 'keystone_project is used to manage new projects in openstack keystone.'

    ensurable

    newparam(:name, :namevar => true) do
        desc 'The name of the project.'
    end

    newproperty(:enabled) do
        desc 'Whether the project should be enabled.  Defaults to true.'
        newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
        defaultto(true)
        munge do |value|
            value.to_s.downcase.to_sym
        end
    end

    newproperty(:description) do
        desc 'The description of the project.'
    end

    newproperty(:id) do
        desc 'Read-only property of the project.'
        validate do |v|
            raise(Puppet::Error, 'This is a read only property.')
        end
    end

end
