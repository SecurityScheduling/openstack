class openstack::profiles::keystone (
    $admin_token = hiera(openstack::admin_token),
    $keystone_db_pass = hiera(openstack::keystone_db_pass),
    $keystone_server = hiera(openstack::keystone_server),
) {

    # load the keystone packages
    $keystone_packages = ['keystone','python-openstackclient','apache2','libapache2-mod-wsgi','memcached','python-memcache','python-mysqldb']
    package { $keystone_packages: ensure => present }

    group { 'keystone':
        ensure  => present,
        system  => true,
        require => Package[$keystone_packages],
    }

    user { 'keystone':
        ensure  => present,
        gid     => 'keystone',
        system  => true,
        require => Package[$keystone_packages],
    }
    
    # stop keystone from starting automatically
    file { '/etc/init/keystone.override':
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => 'manual',
    }

    # create the keystone database
    mysql_database { 'keystone':
        ensure  => present,
        charset => 'utf8',
        collate => 'utf8_swedish_ci',
    } ->

    mysql_user{ 'keystone@localhost':
        ensure        => present,
        password_hash => mysql_password('ABCabc123##'),
    } ->

    mysql_user{ 'keystone@%':
        ensure        => present,
        password_hash => mysql_password('ABCabc123##'),
    } ->

    mysql_grant{ 'keystone@%/keystone.*':
        user       => 'keystone@%',
        table      => 'keystone.*',
        privileges => ['ALL'],
    } ->

    mysql_user{ "keystone@${keystone_server}":
        ensure        => present,
        password_hash => mysql_password('ABCabc123##'),
    } ->

    mysql_grant { "keystone@${keystone_server}/keystone.*":
        user       => "keystone@${keystone_server}",
        table      => 'keystone.*',
        privileges => ['ALL'],
    } ->

    mysql_grant { 'keystone@localhost/keystone.*':
        user       => 'keystone@localhost',
        table      => 'keystone.*',
        privileges => ['ALL'],
    } ->

    exec { 'keystone-manage db_sync':
        path        => '/usr/bin',
        user        => 'keystone',
        refreshonly => true,
        subscribe   => Package[$keystone_packages],
        require     => User['keystone'],
    }

    # generate the keystone.conf file
    file { '/etc/keystone/keystone.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('openstack/keystone.conf.erb'),
    }

    file_line { 'servername':
        path => '/etc/apache2/apache2.conf',
        line => "ServerName ${keystone_server}"
    }

    file { '/etc/apache2/sites-available/wsgi-keystone.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/openstack/wsgi-keystone.conf',
    }

    file { '/etc/apache2/sites-enabled/wsgi-keystone.conf':
        ensure => 'link',
        target => '/etc/apache2/sites-available/wsgi-keystone.conf',
    }

    $cgi_dirs = ['/var/www/cgi-bin','/var/www/cgi-bin/keystone']

    file { $cgi_dirs:
        ensure => directory,
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0755',
    }

    file { '/var/www/cgi-bin/keystone/main':
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0755',
        source => 'puppet:///modules/openstack/main',
    }

    file { '/var/www/cgi-bin/keystone/admin':
        owner  => 'keystone',
        group  => 'keystone',
        mode   => '0755',
        source => 'puppet:///modules/openstack/admin',
        notify => Service['apache2'],
    }

    service {'apache2':
        ensure => running,
        enable => true,
    }

    file {'/var/lib/keystone/keystone.db':
        ensure => absent,
    }

    keystone_service { 'keystone': 
        ensure      => present,    
        description => 'Openstack Identity',
        type        => 'identity',
    }

    keystone_endpoint { 'RegionOne/keystone':
        ensure       => present,
        public_url   => "http://${keystone_server}:5000/v2.0",
        internal_url => "http://${keystone_server}:5000/v2.0",
        admin_url    => "http://${keystone_server}:35357/v2.0",
    }

    keystone_project { 'admin':
        ensure      => present,
        description => 'Admin Project',
        enabled     => 'true',
    }

    keystone_project { 'service':
        ensure      => present,
        description => 'Service Project',
        enabled     => 'true',
    }

    keystone_project { 'demo':
        ensure      => present,
        description => 'Demo Project',
        enabled     => 'true',
    }

}
