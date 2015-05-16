class openstack::profiles::base {
    # stuff that is common to all roles

    #need NTP installed on all nodes
    include '::ntp'
}
