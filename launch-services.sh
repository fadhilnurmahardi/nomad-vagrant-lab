#!/bin/bash

function generate_systemd_config_consul {
  local systemd_config_path="/etc/systemd/system/consul.service"
  echo "Creating systemd config file to run Consul in $systemd_config_path"

  local -r unit_config=$(cat <<EOF
[Unit]
Description="HashiCorp Consul - A service mesh solution"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=$config_path
EOF
)

  local -r service_config=$(cat <<EOF
[Service]
Type=notify
User=vagrant
Group=vagrant
ExecStart=/usr/bin/consul agent -config-dir /etc/consul.d/ -dns-port=53 -recursor=8.8.8.8
ExecReload=/usr/bin/consul reload
KillMode=process
Restart=on-failure
TimeoutSec=300s
LimitNOFILE=65536
EOF
)

  local -r install_config=$(cat <<EOF
[Install]
WantedBy=multi-user.target
EOF
)

  echo -e "$unit_config" > "$systemd_config_path"
  echo -e "$service_config" >> "$systemd_config_path"
  echo -e "$install_config" >> "$systemd_config_path"
}

function generate_systemd_config_nomad {
  local systemd_config_path="/etc/systemd/system/nomad.service"
  echo "Creating systemd config file to run Nomad in $systemd_config_path"

  local readonly unit_config=$(cat <<EOF
[Unit]
Description="HashiCorp Nomad"
Documentation=https://www.nomadproject.io/
Requires=network-online.target
After=network-online.target
ConditionalFileNotEmpty=$config_path
EOF
)

  local readonly service_config=$(cat <<EOF
[Service]
User=vagrant
Group=vagrant
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536
EOF
)

  local readonly install_config=$(cat <<EOF
[Install]
WantedBy=multi-user.target
EOF
)

  echo -e "$unit_config" > "$systemd_config_path"
  echo -e "$service_config" >> "$systemd_config_path"
  echo -e "$install_config" >> "$systemd_config_path"
}

function generate_systemd_config_vault {
  local systemd_config_path="/etc/systemd/system/vault.service"
  local vault_config_dir="/etc/vault.d/"
  local config_path="$config_dir/default.hcl"

  local vault_description="HashiCorp Vault - A tool for managing secrets"
  local vault_command="server"
  local vault_config_file_or_dir="$vault_config_dir"

  echo "Creating systemd config file to run Vault in $systemd_config_path"

  local -r unit_config=$(cat <<EOF
[Unit]
Description=\"$vault_description\"
Documentation=https://www.vaultproject.io/docs/
Requires=network-online.target
After=network-online.target
StartLimitIntervalSec=60
StartLimitBurst=3
EOF
)

  local -r service_config=$(cat <<EOF
[Service]
User=vagrant
Group=vagrant
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault $vault_command -config $vault_config_file_or_dir -log-level=info
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity
EOF
)

  local -r install_config=$(cat <<EOF
[Install]
WantedBy=multi-user.target
EOF
)

  echo -e "$unit_config" > "$systemd_config_path"
  echo -e "$service_config" >> "$systemd_config_path"
  echo -e "$install_config" >> "$systemd_config_path"
}

generate_systemd_config_consul
generate_systemd_config_nomad
generate_systemd_config_vault

systemctl enable consul
systemctl enable vault
systemctl enable nomad
sudo setcap cap_net_bind_service=+ep /usr/bin/consul
systemctl restart consul
PRIVATE_IP=$(hostname -I | awk '{print $2}')
sudo sed -i "s/#DNS=/DNS=$PRIVATE_IP/g" "/etc/systemd/resolved.conf"
sudo sed -i "s/#DNS=/DNS=$PRIVATE_IP/g" "/etc/systemd/resolved.conf"
sudo sed -i "s/##IP_SERVER##/$PRIVATE_IP/g" "/etc/vault.d/default.hcl"
sudo systemctl restart systemd-resolved.service
systemctl restart vault
systemctl restart nomad