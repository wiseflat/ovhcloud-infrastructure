Create a custom OpenStack image with Packer
===

# Prerequisites

- jq
- python3-openstackclient 


# Packer configuration

Source your openrc.sh

```sh
/home/ansible/ovhcloud-infrastructure/packer$ source ../env/develop/openrc.sh
```

Let's find some needed ID. In this example we will build an Ubuntu 20.04 image on a s1-2 instance, with an interface connected on public network Ext-Net.

```sh
/home/ansible/ovhcloud-infrastructure/packer$ export SOURCE_ID=`openstack image list -f json | jq -r '.[] | select (.Name == "Ubuntu 20.04") | .ID'`
/home/ansible/ovhcloud-infrastructure/packer$ export FLAVOR_ID=`openstack flavor list -f json | jq -r '.[] | select(.Name == "s1-2") | .ID'`
/home/ansible/ovhcloud-infrastructure/packer$ export NETWORK_ID=`openstack network list -f json | jq -r '.[] | select(.Name == "Ext-Net") | .ID'`
```


```json
"variables": {
  "identity_endpoint": "{{env `OS_AUTH_URL`}}",
  "region": "{{env `OS_REGION_NAME`}}",
  "ext_net_id": "{{env `NETWORK_ID`}}",
  "flavor_name": "s1-2",
  "tag": "latest",
  "image_name": "custom-Ubuntu-2004",
  "source_image_name": "Ubuntu 20.04",
  "ssh_user": "ubuntu",
  "name": "ubuntu2004"
},
```
# Packer build

```sh
/home/ansible/ovhcloud-infrastructure/packer$ packer validate packer.json
/home/ansible/ovhcloud-infrastructure/packer$ packer build packer.json
```

Once the image is created, you can check it with: 

```sh
/home/ansible/ovhcloud-infrastructure/packer$ openstack image list | grep 'custom-Ubuntu-2004'
| 4ee6d0a1-1a8a-4ded-8b7d-85b269da1a5a | custom-Ubuntu-2004                            | active |
```
