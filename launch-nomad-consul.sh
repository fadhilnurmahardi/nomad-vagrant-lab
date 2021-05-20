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
ExecStart=/usr/bin/consul agent -config-dir /etc/consul.d/ -bind '{{ GetInterfaceIP "enp0s8" }}'
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

generate_systemd_config_consul
generate_systemd_config_nomad

systemctl enable consul
systemctl enable nomad
systemctl restart consul
systemctl restart nomad