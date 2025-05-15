#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE

function header_info {
clear
cat <<"EOF"
 ____                  _             
|  _ \ _ __ ___  _   _| |_ ___  ___  
| |_) | '__/ _ \| | | | __/ _ \/ __| 
|  __/| | | (_) | |_| | ||  __/\__ \ 
|_|   |_|  \___/ \__,_|\__\___||___/ 
                                    
Puppet Open Source Server & Agent Installer
EOF
}
header_info
echo -e "Loading..."

APP="Puppet"
var_disk="4"
var_cpu="2"
var_ram="1024"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
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
  SSH="no"
  VERB="no"
  echo_default
}

function install_puppet() {
  msg_info "Updating apt and installing prerequisites"
  apt-get update
  apt-get install -y wget gnupg2 curl lsb-release

  msg_info "Adding Puppet repository"
  wget https://apt.puppet.com/puppet7-release-$(lsb_release -cs).deb -O puppet-release.deb
  dpkg -i puppet-release.deb
  apt-get update

  msg_info "Installing Puppet Server and Agent"
  apt-get install -y puppetserver puppet-agent

  msg_info "Configuring Puppet Server to start at boot"
  systemctl enable puppetserver
  systemctl start puppetserver

  msg_info "Configuring Puppet Agent to start at boot"
  systemctl enable puppet
  systemctl start puppet

  msg_ok "Puppet Server and Agent installation completed"
}

start
build_container
install_puppet

msg_ok "Completed Successfully!\n"
echo -e "${APP} is installed and running.\nAccess the Puppet server at port 8140.\n"
echo -e "Default Puppet master configuration is in /etc/puppetlabs/puppet/puppet.conf\n"
echo -e "To sign agent certificates, use: puppetserver ca sign --all\n"
