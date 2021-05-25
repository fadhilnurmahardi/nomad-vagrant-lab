#!/bin/bash

set -e

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
EOF
)

  local readonly service_config=$(cat <<EOF
[Service]
User=root
Group=root
ExecStart=/usr/bin/nomad agent -config /etc/nomad.d/
ExecReload=/bin/kill --signal HUP \$MAINPID
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity
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

  local vault_command="server"
  local vault_config_file_or_dir="$vault_config_dir"

  echo "Creating systemd config file to run Vault in $systemd_config_path"

  local -r unit_config=$(cat <<EOF
[Unit]
Description="HashiCorp Vault - A tool for managing secrets"
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

function run_consul_service {
  sudo systemctl enable consul
  sudo setcap cap_net_bind_service=+ep /usr/bin/consul
  sudo systemctl restart consul
  PRIVATE_IP=$(hostname -I | awk '{print $2}')
  sudo sed -i "s/#DNS=/DNS=$PRIVATE_IP/g" "/etc/systemd/resolved.conf"
  sudo sed -i "s/#DNS=/DNS=$PRIVATE_IP/g" "/etc/systemd/resolved.conf"
  sudo systemctl restart systemd-resolved.service
}

function run_nomad_service {
  PRIVATE_IP=$(hostname -I | awk '{print $2}')
  sudo sed -i "s/##IP_SERVER##/$PRIVATE_IP/g" "/etc/nomad.d/default.hcl"
  sudo systemctl enable nomad
  sudo systemctl restart nomad
}

function run_vault_service {
  mkdir -p /data
  chown vagrant /data
  PRIVATE_IP=$(hostname -I | awk '{print $2}')
  sudo sed -i "s/##IP_SERVER##/$PRIVATE_IP/g" "/etc/vault.d/default.hcl"
  sudo systemctl enable vault
  sudo systemctl restart vault
}

function run_init_vault {
  echo "Start init vault"
  export VAULT_ADDR=http://127.0.0.1:8200
  vault_secrets="$(vault operator init -key-shares=5 -key-threshold=5 || echo "false")"

  if [[ "$vault_secrets" != "false" ]]; then
    mkdir -p /vagrant/playgroud
    sudo tee /vagrant/playgroud/vault>/dev/null<<EOF
"$vault_secrets"
EOF
  fi

  ITER=0
  IFS=$'\n'
  for key in $(cat /vagrant/playgroud/vault | grep -o ': .*' | sed 's@: @@'); do
      if [[ $ITER -eq 5 ]]; then
          break
      else 
          vault operator unseal $key
      fi
      ITER=$(expr $ITER + 1)
  done
  echo "Vault unsealed"
}

function run {
  local run_vault="false"
  local init_vault="false"

  while [[ $# > 0 ]]; do
    local key="$1"

    case "$key" in
      --run-vault)
        run_vault="true"
        ;;
      --init-vault)
        init_vault="true"
        ;;
    esac

    shift
  done

  generate_systemd_config_consul
  generate_systemd_config_nomad
  generate_systemd_config_vault

  run_consul_service
  if [[ "$run_vault" == "true" ]]; then
    run_vault_service
    if [[ "$init_vault" == "true" ]]; then
      sleep 5
      run_init_vault
    fi
  fi
  run_nomad_service
}

run "$@"