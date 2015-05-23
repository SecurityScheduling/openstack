File.expand_path('../..', File.dirname(__FILE__)).tap { |dir| $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir) }
Puppet::Type::newtype(:keystone_user) do

    desc 'keystone_user is used to manage users in openstack keystone.'

    ensurable

    newparam(:name, :namevar => true) do
        desc 'The name of the user.'
    end

    newparam(:password) do
        desc 'The password for the new user'
    end

    newproperty(:enabled) do
        desc 'Whether the user should be enabled.  Defaults to true.'
        newvalues(/(t|T)rue/, /(f|F)alse/, true, false )
        defaultto(true)
        munge do |value|
            value.to_s.downcase.to_sym
        end
    end

    newproperty(:id) do
        desc 'Read-only property of the user'
        validate do |v|
            raise(Puppet::Error, 'This is a read only property.')
        end
    end

    newproperty(:email) do
        desc 'The users email address'
    end

end
