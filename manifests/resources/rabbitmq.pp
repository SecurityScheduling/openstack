class openstack::resources::rabbitmq {
    
    # install rabbitmq 
    class { '::rabbitmq':
        package_gpg_key   => 'https://www.rabbitmq.com/rabbitmq-signing-key-public.asc',
        delete_guest_user => true,
    } ->

    # configure rabbitmq openstack user
    rabbitmq_user { 'openstack':
        password => 'ABCabc123##',
    } ->

    rabbitmq_user_permissions { 'openstack@/':
        configure_permission => '.*',
        read_permission      => '.*',
        write_permission     => '.*',
    }
}
