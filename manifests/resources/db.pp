class openstack::resources::db {
    
    # install mysql server 
    class { '::mysql::server':
        root_password           => 'ABCabc123##',
        remove_default_accounts => true,
    }


}
