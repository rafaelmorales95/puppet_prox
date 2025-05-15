#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
 ____                  _             
|  _ \ _ __ ___  _   _| |_ ___  ___  
| |_) | '__/ _ \| | | | __/ _ \/ __| 
|  __/| | | (_) | |_| | ||  __/\__ \ 
|_|   |_|  \___/ \__,_|\__\___||___/ 
                                    
Puppet Server Installer for Proxmox LXC
EOF
}
header_info
APP="Puppet"
var_disk="6"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW="P@ssw0rd!"
  CT_ID=$NEXTID
  HN="puppet-server"
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  SSH="yes"
  VERB="no"
  echo_default
}

function post_install() {
  LXC_CMD="pct exec $CTID --"

  msg_info "Actualizando contenedor"
  $LXC_CMD apt-get update
  $LXC_CMD apt-get upgrade -y

  msg_info "Instalando dependencias básicas y SSH"
  $LXC_CMD apt-get install -y sudo wget curl gnupg2 lsb-release openssh-server

  msg_info "Creando usuario SSH: puppetadmin"
  $LXC_CMD useradd -m -s /bin/bash puppetadmin
  echo "puppetadmin:P@ssw0rd!" | $LXC_CMD chpasswd
  $LXC_CMD usermod -aG sudo puppetadmin

  msg_info "Habilitando SSH"
  $LXC_CMD systemctl enable ssh
  $LXC_CMD systemctl restart ssh

  msg_info "Agregando repositorio oficial de Puppet"
  $LXC_CMD wget https://apt.puppet.com/puppet7-release-bookworm.deb -O /tmp/puppet.deb
  $LXC_CMD dpkg -i /tmp/puppet.deb
  $LXC_CMD apt-get update

  msg_info "Instalando Puppet Server y Agent"
  $LXC_CMD apt-get install -y puppetserver puppet-agent

  msg_info "Habilitando servicios de Puppet"
  $LXC_CMD systemctl enable puppetserver
  $LXC_CMD systemctl start puppetserver
  $LXC_CMD systemctl enable puppet
  $LXC_CMD systemctl start puppet

  msg_ok "Puppet Server instalado correctamente"
}

start
build_container
post_install

msg_ok "Instalación completada correctamente 🎉"

IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')
echo -e "\nAcceso por SSH:"
echo -e "  Usuario: puppetadmin"
echo -e "  Contraseña: P@ssw0rd!"
echo -e "  IP: $IP"
echo -e "  Puerto SSH: 22"
echo -e "  Puppet Server está escuchando en el puerto 8140\n"
echo -e "Para firmar certificados de agentes:"
echo -e "  sudo /opt/puppetlabs/bin/puppetserver ca sign --all\n"
