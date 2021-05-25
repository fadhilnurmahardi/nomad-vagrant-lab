#!/bin/bash
set -e
export VAULT_ADDR=http://vault.service.consul:8200
nomad_token=$(vault token create -policy="nomad-server-policy" -period=72h -orphan -format=json | jq -r '.auth.client_token')
sudo tee /etc/nomad.d/vault.hcl>/dev/null<<EOF
vault {
    enabled = true
    address = "http://vault.service.consul:8200"
    create_from_role = "nomad-cluster"
    token = "$nomad_token"
}
EOF

sudo systemctl restart nomad.service