ui = true

listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable     = "true"
}

storage "file" {
  path = "/data/vault/data"
}

ha_storage "consul" {
  address = "##IP_SERVER##:8500"
  path    = "vault/"
  scheme  = "http"
  service = "vault"
}

# HA settings
cluster_addr  = "http://##IP_SERVER##:8201"
api_addr      = "http://##IP_SERVER##:8200"

service_registration "consul" {
  address = "##IP_SERVER##:8500"
}