data_dir = "/tmp/nomad/server"

server {
  enabled          = true
  bootstrap_expect = 3
  job_gc_threshold = "2m"
}

datacenter = "sg"

region = "ap-southeast-1"

advertise {
  http = "{{ GetInterfaceIP `enp0s8` }}"
  rpc  = "{{ GetInterfaceIP `enp0s8` }}"
  serf = "{{ GetInterfaceIP `enp0s8` }}"
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

client {
  enabled           = true
  network_interface = "enp0s8"
  servers           = ["172.16.1.101", "172.16.1.102", "172.16.1.103"]
}

consul {
  address = "##IP_SERVER##:8500"
}