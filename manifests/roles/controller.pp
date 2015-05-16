class openstack::roles::controller inherits ::openstack::role {
    
    #controller needs to have the msql database
    include '::openstack::resources::db'

    #also needs rabbitmq installed
    include '::openstack::resources::rabbitmq'

}
