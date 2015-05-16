class openstack::resources::repo {
    include '::apt'

    package { 'ubuntu-cloud-keyring':
        ensure => present,
    }

    apt::source { 'cloudarchive-kilo':
        location  => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
        release   => 'trusty-updates/kilo main',
        repos     => 'main',
        include   => {
            'deb' => true,
        },
    }
}
