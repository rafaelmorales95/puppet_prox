#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
APP="PuppetServer"
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function header_info {
clear
cat <<"EOF"
  ____              _           _   
 |  _ \ _   _ _ __ (_) ___  ___| |_ 
 | |_) | | | | '_ \| |/ _ \/ __| __|
 |  __/| |_| | |_) | |  __/\__ \ |_ 
 |_|    \__, | .__/|_|\___||___/\__|
        |___/|_| Puppet Server LXC
EOF
}

header_info
echo -e "Loading..."

function default_settings() {
  CT_TYPE="1"
  PW="puppetadmin"
  CT_ID=$NEXTID
  HN="puppet"
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="yes"
  VERB="no"
  echo_default
}

start
build_container
description

# --- Inside the container ---
pct exec $CTID -- bash -c "apt-get update && apt-get install -y curl wget gnupg lsb-release"

# Add Puppet repo
pct exec $CTID -- bash -c "wget https://apt.puppet.com/puppet7-release-bookworm.deb && dpkg -i puppet7-release-bookworm.deb && apt-get update"

# Install Puppet Server
pct exec $CTID -- bash -c "apt-get install -y puppetserver"

# Fix ownership
pct exec $CTID -- bash -c "chown -R puppet:puppet /etc/puppetlabs /opt/puppetlabs /var/log/puppetlabs /var/opt/puppetlabs"

# Enable and start service
pct exec $CTID -- bash -c "systemctl enable puppetserver && systemctl start puppetserver"

# Wait for it to start
sleep 10

# Confirm service
pct exec $CTID -- systemctl status puppetserver --no-pager

# Install dashboard dependencies
pct exec $CTID -- bash -c "apt-get install -y python3-pip python3-venv git sqlite3"

# Clone Puppetboard
pct exec $CTID -- bash -c "cd /opt && git clone https://github.com/voxpupuli/puppetboard.git && cd puppetboard && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"

# Generate minimal config
pct exec $CTID -- bash -c "mkdir -p /etc/puppetboard && echo 'PUPPETDB_HOST = \"localhost\"' > /etc/puppetboard/default_settings.py"

# Create systemd service for dashboard
pct exec $CTID -- bash -c "cat <<EOF > /etc/systemd/system/puppetboard.service
[Unit]
Description=Puppetboard Dashboard
After=network.target

[Service]
User=root
WorkingDirectory=/opt/puppetboard
ExecStart=/opt/puppetboard/venv/bin/gunicorn -b 0.0.0.0:8080 puppetboard.app:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# Enable dashboard
pct exec $CTID -- systemctl daemon-reexec
pct exec $CTID -- systemctl daemon-reload
pct exec $CTID -- systemctl enable puppetboard
pct exec $CTID -- systemctl start puppetboard

IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
msg_ok "Puppet Server and Puppetboard Dashboard installed"
echo -e "\n🔐 SSH Login: root / puppetadmin"
echo -e "🌐 Puppetboard Dashboard: http://${IP}:8080"
echo -e "🐾 Puppet Server is running at port 8140 for agents.\n"
