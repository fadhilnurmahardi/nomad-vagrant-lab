#!/bin/bash
set -e
echo "Generating nomad bootsrap token..."
acl_bootsrap_token="$(nomad acl bootstrap || echo "false")"

if [[ "$acl_bootsrap_token" != "false" ]]; then
mkdir -p /vagrant/playgroud
sudo tee /vagrant/playgroud/nomad_bootsrap_token>/dev/null<<EOF
$acl_bootsrap_token
EOF
fi

echo "Nomad bootsrap token saved on /vagrant/playgroud/nomad_bootsrap_token"
