ssh_public_key = "../../ssh/id_rsa.pub"

zone = {
  root      = "wiseflat.com"
  subdomain = "infra"
}

vlan_id  = 3
vrack_id = "pn-xxxx"

restricted_ip = [
  "0.0.0.0/0"
]

restricted_port = [
  22
]

// regions = [
//     "DE1",
//     "UK1",
//     "GRA5"
// ]

domains = []

format = "%01d"

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
  nbinstances = 0
  disk        = false
  disk_size   = 10
}

backends = {
  hostname    = "backend"
  flavor      = "s1-2"
  image       = "Ubuntu 20.04"
  nbinstances = 0
  disk        = false
  disk_size   = 10
}

backends_vrack = {
  hostname    = "backend-vrack"
  flavor      = "s1-2"
  image       = "Ubuntu 20.04"
  nbinstances = 0
  disk        = false
  disk_size   = 10
}
