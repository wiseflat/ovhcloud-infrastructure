output "ansible" {
  description = "The result of ansible playbook execution"
  value       = null_resource.ansible
}

output "instances" {
  description = "List of instances"
  value = [
    for instance in openstack_compute_instance_v2.instance :
    {
      hostname    = split(".", instance.name)[0]
      public_ipv4 = instance.access_ip_v4
    }
  ]
}