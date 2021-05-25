#!/bin/bash
set -e

echo "Make dir /data"
sudo mkdir -p /data

echo "Setup docker config json"
sudo tee /data/config.json > /dev/null<<EOF
{
  "credHelpers" : {
    "519960579476.dkr.ecr.ap-southeast-1.amazonaws.com" : "ecr-login"
  }
}
EOF

echo "Setup docker plugin config nomad"
sudo tee /etc/nomad.d/docker-plugin.hcl > /dev/null<<EOF
plugin "docker" {
  config {
    auth {
      config = "/data/config.json"
    }
  }
}
EOF

echo "Setup /root/.aws dir"
sudo mkdir -p /root/.aws
echo "Setup creds aws"
sudo tee /root/.aws/credentials > /dev/null<<EOF
[default]
aws_access_key_id=$AWS_KEY
aws_secret_access_key=$AWS_SECRET
EOF


echo "Restarting nomad..."
sudo systemctl restart nomad.service
echo "Nomad Restarted"