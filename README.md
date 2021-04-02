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
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

- Create a Public Cloud [project](https://docs.ovh.com/us/en/dedicated/vrack-pci-ds/#create-a-public-cloud-project)
- Create a Vrack on BareMetal Cloud [section](https://docs.ovh.com/us/en/dedicated/vrack-pci-ds/#create-a-public-cloud-project) (Do not associate it to your cloud project. It will be done automatically with Terraform).
- Create an [OpenStack's RC file](https://docs.ovh.com/us/en/public-cloud/configure_user_access_to_horizon/) on your Public Cloud project.
- Create an OVH [token](https://api.ovh.com/createToken/?GET=/*&POST=/*&PUT=/*&DELETE=/* ) (tokens must be added to you openstack's rc file)

# Demo

A fully fonctionnal demo environments will help you to deploy multiple infrastructures:

- [monoregion](/env/demo/infra/monoregion)
- [multiregion](/env/demo/infra/multiregion)
- [multiregion with a Vrack network](/env/demo/infra/multiregion-vrack)

# Environment definition

- `infra` directory is the definition of your different type of infrastructure
- `Live` directory is terragrunt managed, it's a set of multiple Public Cloud Project. Each terragrunt live refers to one of your different infrastructures.
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
|-- live
|   |-- monoregion
|   |-- multiregion
|   |-- multiregion-vrack
|   `-- terragrunt.yml
|-- playbooks
|   |-- nginx.yml
|   `-- templates
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
/home/ansible/ovhcloud-infrastructure$ vim env/develop/live/terragrunt.yml
```

- Adapt paths to match the absolute path of your project.
- Vrack ID is the one you created above from the Control Panel
- Restricted Ip address filters ssh port 22, so add your public ip address for now.
- DNS Zone is used to create your ssh config file. DNS record are not created, it's just for human readable purpose and Ansible connectivity.

```yaml
---
working_dir: /home/ansible/ovhcloud-infrastructure/env/develop
ssh_public_key: /home/ansible/ovhcloud-infrastructure/env/develop/ssh/id_rsa.pub
playbook_path: /home/ansible/ovhcloud-infrastructure/playbooks

vrack_id: pn-xxxx

restricted_ip:
  - x.x.x.x/32

restricted_port:
  - 22

zone:
  root: domain.com
  subdomain: www
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
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt init
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt plan
```

Maybe, you will have some issues about regions, check it on [horizon](https://horizon.cloud.ovh.net)

Edit `terragrunt.hcl` file in the same directory, which one contains some defaults values and override the `regions` variable:

```
  # regions = [
  #   "DE1",
  #   "UK1",
  #   "GRA7"
  # ]
```

```
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt apply
```

If everything worked, at this step you will have security groups, networks, regions set up.

## Second step : deploy frontends

Edit `terragrunt.hcl` file in the same directory, which one contains some defaults values.

Setting `frontends = 1` will create 1 instance per region.

```yaml
  nbinstances = {
    frontends      = 1
    backends       = 0
    backends_vrack = 0
  }
```

Maybe, you will have to override the `regions` variable because of a localization restriction (check it on [horizon](https://horizon.cloud.ovh.net))

```
  # regions = [
  #   "DE1",
  #   "UK1",
  #   "GRA7"
  # ]
```

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt plan
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt apply
```

## Third step : deploy backends

Setting `backends = 1` will create 1 instance per region connected to the Internal network.

Setting `backends_vrack = 1` will create 1 instance per region connected the vrack network.

```yaml
  nbinstances = {
    frontends      = 1
    backends       = 1
    backends_vrack = 1
  }
```

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt plan
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt apply
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
  |--@infrastructures:
  |  |--@regions:
  |  |  |--@monoregion:
  |  |  |--@multiregion:
  |  |  |  |--backend-vrack1.de1.multivrack.www.domain.com
  |  |  |  |--backend-vrack1.gra5.multivrack.www.domain.com
  |  |  |  |--backend-vrack1.uk1.multivrack.www.domain.com
  |  |  |  |--backend1.de1.multivrack.www.domain.com
  |  |  |  |--backend1.gra5.multivrack.www.domain.com
  |  |  |  |--backend1.uk1.multivrack.www.domain.com
  |  |  |  |--frontend1.de1.multivrack.www.domain.com
  |  |  |  |--frontend1.gra5.multivrack.www.domain.com
  |  |  |  |--frontend1.uk1.multivrack.www.domain.com
  |  |--@servers:
  |  |  |--@backend:
  |  |  |  |--backend1.de1.multivrack.www.domain.com
  |  |  |  |--backend1.gra5.multivrack.www.domain.com
  |  |  |  |--backend1.uk1.multivrack.www.domain.com
  |  |  |--@backend_vrack:
  |  |  |  |--backend-vrack1.de1.multivrack.www.domain.com
  |  |  |  |--backend-vrack1.gra5.multivrack.www.domain.com
  |  |  |  |--backend-vrack1.uk1.multivrack.www.domain.com
  |  |  |--@frontend:
  |  |  |--@frontend_vrack:
  |  |  |  |--frontend1.de1.multivrack.www.domain.com
  |  |  |  |--frontend1.gra5.multivrack.www.domain.com
  |  |  |  |--frontend1.uk1.multivrack.www.domain.com
  |--@ungrouped:
  |  |--localhost
  |--@www:
  |  |--backend-vrack1.de1.multivrack.www.domain.com
  |  |--backend-vrack1.gra5.multivrack.www.domain.com
  |  |--backend-vrack1.uk1.multivrack.www.domain.com
  |  |--backend1.de1.multivrack.www.domain.com
  |  |--backend1.gra5.multivrack.www.domain.com
  |  |--backend1.uk1.multivrack.www.domain.com
  |  |--frontend1.de1.multivrack.www.domain.com
  |  |--frontend1.gra5.multivrack.www.domain.com
  |  |--frontend1.uk1.multivrack.www.domain.com
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
frontend1.de1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
frontend1.uk1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
frontend1.gra5.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend1.de1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend1.gra5.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend-vrack1.gra5.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend1.uk1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend-vrack1.de1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
backend-vrack1.uk1.multivrack.www.domain.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
</p>
</details>

<details>
<summary>Apt update/upgrade</summary>
<p>

```sh
/home/ansible/ovhcloud-infrastructure/env/develop$ ansible-playbook ../../playbooks/upgrade.yml
PLAY [apt-upgrade] *************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************
ok: [frontend1.de1.multivrack.www.domain.com]
ok: [backend1.de1.multivrack.www.domain.com]
ok: [backend1.uk1.multivrack.www.domain.com]
ok: [frontend1.uk1.multivrack.www.domain.com]
ok: [frontend1.gra5.multivrack.www.domain.com]
ok: [backend1.gra5.multivrack.www.domain.com]
ok: [backend-vrack1.gra5.multivrack.www.domain.com]
ok: [backend-vrack1.uk1.multivrack.www.domain.com]
ok: [backend-vrack1.de1.multivrack.www.domain.com]

TASK [apt | autoclean autoremove] **********************************************************************************************
ok: [frontend1.de1.multivrack.www.domain.com]
ok: [frontend1.gra5.multivrack.www.domain.com]
ok: [backend1.de1.multivrack.www.domain.com]
ok: [backend1.gra5.multivrack.www.domain.com]
ok: [backend1.uk1.multivrack.www.domain.com]
ok: [frontend1.uk1.multivrack.www.domain.com]
ok: [backend-vrack1.gra5.multivrack.www.domain.com]
ok: [backend-vrack1.de1.multivrack.www.domain.com]
ok: [backend-vrack1.uk1.multivrack.www.domain.com]

TASK [apt | upgrade] ***********************************************************************************************************
ok: [frontend1.de1.multivrack.www.domain.com]
ok: [frontend1.gra5.multivrack.www.domain.com]
ok: [backend1.de1.multivrack.www.domain.com]
ok: [backend1.uk1.multivrack.www.domain.com]
ok: [backend1.gra5.multivrack.www.domain.com]
ok: [frontend1.uk1.multivrack.www.domain.com]
ok: [backend-vrack1.gra5.multivrack.www.domain.com]
ok: [backend-vrack1.de1.multivrack.www.domain.com]
ok: [backend-vrack1.uk1.multivrack.www.domain.com]

PLAY RECAP *********************************************************************************************************************
backend-vrack1.de1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
backend-vrack1.gra5.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
backend-vrack1.uk1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
backend1.de1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
backend1.gra5.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
backend1.uk1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
frontend1.de1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
frontend1.gra5.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
frontend1.uk1.multivrack.www.domain.com : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

Playbook run took 0 days, 0 hours, 0 minutes, 37 seconds
```
</p>
</details>

Then, you are good to go ! All your instances are ready to be configured with your configuration management tool (puppet, ansible, chef, etc).

</p>
</details>

<details>
<summary>Deploy some nginx configurations to see if everything is working like a charm</summary>
<p>

```sh
/home/ansible/ovhcloud-infrastructure/env/develop$ ansible-playbook playbooks/nginx.yml
```

You can find IPs address of your instances in you ssh configuration file.

```
$ curl http://54.37.4.210/
backend1.uk1.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://54.37.4.210/
backend-vrack1.de1.multivrack.www.domain.com

$ curl http://51.68.41.230/
backend1.gra5.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://51.68.41.230/
backend-vrack1.de1.multivrack.www.domain.com

$ curl http://135.125.134.167/
backend1.de1.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.gra5.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.uk1.multivrack.www.domain.com
$ curl http://135.125.134.167/
backend-vrack1.de1.multivrack.www.domain.com
```
</p>
</details>

## Last step : destroy everything

Setting `backends = 0` will destroy all instances connected to the Internal network.
Setting `backends_vrack = 0` will destroy all instances connected the vrack network.
Setting `frontends = 0` will destroy all frontend instances.

Do it smoothly. It takes a lot of CPU ;-)

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt apply
```

Finaly, destroy all other terraform resources

```sh
/home/ansible/ovhcloud-infrastructure/env/develop/live/multiregion-vrack$ terragrunt destroy
```

# Troubleshooting

* When you increase (or reduce) the number of instances, do it smoothly. It takes a lot of CPU ;-)
* If terragrunt fails, it is most of the time a network issue. Just launch `terragrunt apply` again.
* If an Ansible playbook fails, same resolution.
