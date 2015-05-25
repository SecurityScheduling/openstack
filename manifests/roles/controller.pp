class openstack::roles::controller inherits ::openstack::role {
    
    #also needs rabbitmq installed
    include '::openstack::resources::rabbitmq'

    #controller needs to have the msql database
    include '::openstack::resources::db'

    #configure all the services an Openstack Controller needs
    include '::openstack::profiles::keystone'

}
