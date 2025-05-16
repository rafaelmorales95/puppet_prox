#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 ____                  _                   
|  _ \ ___  _ __   ___| |_ _ __ _   _ ___ 
| |_) / _ \| '_ \ / _ \ __| '__| | | / __|
|  __/ (_) | |_) |  __/ |_| |  | |_| \__ \
|_|   \___/| .__/ \___|\__|_|   \__,_|___/
           |_|                            
 Puppet Server LXC Installer
EOF
}
header_info
echo -e "Loading..."

APP="Puppet Server"
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
NEXTID=$(pvesh get /cluster/nextid)
color
catch_errors

function default_settings() {
  CT_TYPE="1"           # LXC container
  PW=""                 # empty = auto gen
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="yes"             # habilitar SSH
  VERB="no"
  echo_default
}

function install_puppet() {
  msg_info "Updating container and installing prerequisites"
  pct exec $CT_ID -- bash -c "apt-get update && apt-get upgrade -y && apt-get install -y wget gnupg2 apt-transport-https openjdk-17-jre-headless"
  
  msg_info "Adding Puppet repository and installing puppetserver"
  pct exec $CT_ID -- bash -c "wget https://apt.puppet.com/puppet7-release-${var_os}.deb -O /tmp/puppet7-release.deb"
  pct exec $CT_ID -- bash -c "dpkg -i /tmp/puppet7-release.deb"
  pct exec $CT_ID -- bash -c "apt-get update && apt-get install -y puppetserver"

  msg_info "Configuring Puppet Server memory (2GB)"
  pct exec $CT_ID -- bash -c "sed -i 's/JAVA_ARGS.*/JAVA_ARGS=\"-Xms2g -Xmx2g\"/' /etc/default/puppetserver"
  
  msg_info "Starting Puppet Server service"
  pct exec $CT_ID -- systemctl daemon-reload
  pct exec $CT_ID -- systemctl enable puppetserver
  pct exec $CT_ID -- systemctl start puppetserver

  msg_ok "Puppet Server instalado y en ejecución"
}

function start() {
  default_settings
  build_container
  install_puppet
  description
  msg_ok "Completed Successfully!\n"
  echo -e "${APP} should be reachable at port 8140 on the container IP.\nSSH access: ssh root@${IP} (if SSH enabled)"
}

start
