Generic Public Cloud Infrastructure
====

This repository contains resources to deploy a generic cloud platform on top of OVHcloud Public Cloud Infrastructure

```
         [UK1]                  [DE1]                   [GRA5]
           |                      |                        |
----------------------- // ----------------------- // -----------------------  Ext-net
           |                      |                        |
     [frontend1]-------|     [frontend1]-------|       [frontend1]-------|
          |            |          |            |            |            |
        ----- Int-net  |        ----- Int-net  |          ----- Int-net  |
          |            |          |            |            |            |
          |            |          |            |            |            |
  [b1-1] ... [b1-X]    |  [b2-1] ... [b2-X]    |    [b3-1] ... [b3-X]    |
                       |                       |                         |
-------------------------------------------------------------------------------  Multi-net
                       |                       |                         |
              [b1-1] ... [b1-X]        [b2-1] ... [b2-X]         [b3-1] ... [b3-X]
```

# Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 0.14
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

- Create a Public Cloud [project](https://docs.ovh.com/us/en/dedicated/vrack-pci-ds/#create-a-public-cloud-project)
- Create a Vrack on BareMetal Cloud [section](https://docs.ovh.com/us/en/dedicated/vrack-pci-ds/#create-a-public-cloud-project) (Do not associate it to your cloud project. It will be done automatically with Terraform).
- Create an [OpenStack's RC file](https://docs.ovh.com/us/en/public-cloud/configure_user_access_to_horizon/) on your Public Cloud project.
- Create an OVH [token](https://api.ovh.com/createToken/?GET=/*&POST=/*&PUT=/*&DELETE=/* ) (tokens must be added to you openstack's rc file)

- [Packer](https://www.packer.io/downloads.html) to build your own openstack images

# Demo

A fully fonctionnal demo environments will help you to deploy multiple infrastructures:

- [monoregion](/env/demo/infra/monoregion)
- [multiregion](/env/demo/infra/multiregion)
- [multiregion with a Vrack network](/env/demo/infra/multiregion-vrack)

# Environment definition

- `infra` directory is the definition of your different type of infrastructure
- All other files are used by Ansible to manage your instances.

```
$ tree -L 2 env/demo
env/demo
|-- README.md
|-- ansible.cfg
|-- config
|-- group_vars
|   `-- all
|-- infra
|   |-- monoregion
|   |-- multiregion
|   `-- multiregion-vrack
|-- inventory.ini
|-- playbooks
|   |-- check-cloudinit.yml
|   |-- check-port.yml
|   |-- facts.yml
|   |-- iptables.yml
|   |-- nginx.yml
|   |-- ssh-config.yml
|   |-- templates
|   `-- upgrade.yml
`-- ssh
```

# Let's start !

Let's deploy a multiregion infrastructure with a OVHcloud vrack.

Do not modify the demo environment, just copy it to `develop` to test this project.

```sh
/home/ansible/ovhcloud-infrastructure$ cp -Rf env/demo env/develop
```

## Generate ssh keys

This will be used to create your openstack keypair.

**no passphrase**.

```sh
/home/ansible/ovhcloud-infrastructure$ ssh-keygen -f env/develop/ssh/id_rsa
```

## Edit your project configuration file

```sh
/home/ansible/ovhcloud-infrastructure$ vim env/develop/infra/multiregion-vrack/variables.tfvars
```

- DNS Zone is used to create your ssh config file. DNS record are not created, it's just for human readable purpose and Ansible connectivity.
- Vrack ID is the one you created above from the Control Panel.
- Set up a default Vlan ID.

```hcl
zone = {
  root      = "wiseflat.com"
  subdomain = "infra"
}

vlan_id = 3
vrack_id = "pn-xxxx"
```

## First step

In order to attach your Public Cloud project to your Vrack, append to your openrc file a terraform variable. You can set your `OS_PASSWORD` as well to avoid to be prompted.

```sh
/home/ansible/ovhcloud-infrastructure$ echo 'export TF_VAR_project_id=${OS_TENANT_ID}' >> env/develop/openrc.sh
```

Source your OpenStack's RC file to set your environments variables:

```sh
/home/ansible/ovhcloud-infrastructure$ source env/develop/openrc.sh
```

```sh
/home/ansible/ovhcloud-infrastructure$ cd env/develop/live/multiregion-vrack
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform init
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform plan -var-file="variables.tfvars"
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform apply -var-file="variables.tfvars"
```

Terraform may fails because your Openstack project do not use the same regions. Check it on [horizon](https://horizon.cloud.ovh.net).

Edit `variables.tfvars` file in the same directory, which one contains some defaults values and override the `regions` variable, than execute again the last command.

```hcl
// regions = [
//     "DE1",
//     "UK1",
//     "GRA5"
// ]
```

If everything worked, at this step you will have security groups, networks, regions set up.

## Second step : deploy frontends

Setting `nbinstances = 1` will create 1 instance per region.
Edit `variables.tfvars` file in the same directory:

```hcl
frontends = {
    lan_net = [
      "10.0.1.0/24",
      "10.0.2.0/24",
      "10.0.3.0/24"
    ]
    vrack_net   = "192.168.0.0/16"
    hostname    = "frontend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = 1
    disk        = false
    disk_size   = 10
}
```

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform apply -var-file="variables.tfvars"
```

## Third step : deploy backends

Setting `backends.nbinstances = 1` will create 1 instance per region connected to the Internal network.
Setting `backends_vrack.nbinstances = 1` will create 1 instance per region connected the vrack network.

Edit `variables.tfvars` file in the same directory:

```yaml
backends = {
    hostname    = "backend"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = 1
    disk        = false
    disk_size   = 10
}

backends_vrack = {
    hostname    = "backend-vrack"
    flavor      = "s1-2"
    image       = "Ubuntu 20.04"
    nbinstances = 1
    disk        = false
    disk_size   = 10
}
```

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform apply -var-file="variables.tfvars"
```

## Ansible operations

Ansible helps you to update your local files automatically:

- inventory.ini
- ssh config

<details>
<summary>Check your Ansible inventory</summary>
<p>

```sh
/home/ansible/ovhcloud-infrastructure/env/develop$ ansible-inventory --graph
@all:
  |--@infra:
  |  |--backend-vrack1.de1.multivrack.infra.wiseflat.fr
  |  |--backend-vrack1.gra5.multivrack.infra.wiseflat.fr
  |  |--backend-vrack1.uk1.multivrack.infra.wiseflat.fr
  |  |--backend1.de1.multivrack.infra.wiseflat.fr
  |  |--backend1.gra5.multivrack.infra.wiseflat.fr
  |  |--backend1.uk1.multivrack.infra.wiseflat.fr
  |  |--frontend1.de1.multivrack.infra.wiseflat.fr
  |  |--frontend1.gra5.multivrack.infra.wiseflat.fr
  |  |--frontend1.uk1.multivrack.infra.wiseflat.fr
  |--@infrastructures:
  |  |--@regions:
  |  |  |--@monoregion:
  |  |  |--@multiregion:
  |  |  |  |--backend-vrack1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--backend-vrack1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--backend-vrack1.uk1.multivrack.infra.wiseflat.fr
  |  |  |  |--backend1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--backend1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--backend1.uk1.multivrack.infra.wiseflat.fr
  |  |  |  |--frontend1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--frontend1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--frontend1.uk1.multivrack.infra.wiseflat.fr
  |  |--@servers:
  |  |  |--@backend:
  |  |  |  |--backend1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--backend1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--backend1.uk1.multivrack.infra.wiseflat.fr
  |  |  |--@backend_vrack:
  |  |  |  |--backend-vrack1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--backend-vrack1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--backend-vrack1.uk1.multivrack.infra.wiseflat.fr
  |  |  |--@frontend:
  |  |  |--@frontend_vrack:
  |  |  |  |--frontend1.de1.multivrack.infra.wiseflat.fr
  |  |  |  |--frontend1.gra5.multivrack.infra.wiseflat.fr
  |  |  |  |--frontend1.uk1.multivrack.infra.wiseflat.fr
  |--@ungrouped:
  |  |--localhost
```
</p>
</details>

<details>
<summary>Ping all your instances</summary>
<p>

```sh
/home/ansible/ovhcloud-infrastructure/env/develop$ ansible -m ping all
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
frontend1.gra5.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
frontend1.uk1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend-vrack1.gra5.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend1.uk1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend-vrack1.uk1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend1.gra5.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
frontend1.de1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend-vrack1.de1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
backend1.de1.multivrack.infra.wiseflat.fr | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```
</p>
</details>

Then, you are good to go ! All your instances are ready to be configured with your configuration management tool (puppet, ansible, chef, etc).

In this demo, we will install nginx everywhere:

- Frontends will act as reverse proxy, they will forward requests to backend instances.
- Backends will answer their hostnames to check if load balancing is working.

</p>
</details>

<details>
<summary>Deploy the demo</summary>
<p>

```sh
/home/ansible/ovhcloud-infrastructure/env/develop$ ansible-playbook playbooks/nginx.yml
```

You can find your instances IPs address in you ssh configuration file.

UK1 frontend is load balancing requests to the internal network and to the vrack network !

```
$ curl http://54.37.4.210/
backend1.uk1.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.de1.multivrack.www.domain.com
```

GRA5 frontend is load balancing requests to the internal network and to the vrack network !

```
$ curl http://51.68.41.230/
backend1.gra5.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.de1.multivrack.www.domain.com
```

DE1 frontend is load balancing requests to the internal network and to the vrack network !

```
$ curl http://135.125.134.167/
backend1.de1.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.de1.multivrack.www.domain.com
```

All good !

</p>
</details>

## Last step : destroy everything

* Setting `backends.nbinstances = 0` will destroy all instances connected to the Internal network.
* Setting `backends_vrack.nbinstances = 0` will destroy all instances connected the vrack network.
* Setting `frontends.nbinstances = 0` will destroy all frontend instances.

Do it smoothly. It takes a lot of CPU ;-)

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform apply -var-file="variables.tfvars"
```

Finaly, destroy all other terraform resources

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terraform destroy -var-file="variables.tfvars"
```

# Troubleshooting

* When you increase (or reduce) the number of instances, do it smoothly. It takes a lot of CPU.
* If terraform fails, it is most of the time a network issue. Just launch `terraform apply` again.
* If an Ansible playbook fails, same resolution.
