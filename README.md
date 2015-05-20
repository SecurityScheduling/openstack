# security scheduling - Openstack Kilo

This module installs openstack kile in a multi-node environment

## Install

To use this module simply assign a role to your nodes:

```
'controller' {
    include ::openstack::role::controller
}

'network' {
    include ::openstack::role::network
}
```

## Progress

Finishing up the keystone service
