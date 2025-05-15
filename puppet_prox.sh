#!/usr/bin/env bash
set -e

# Variables LXC
CTID=105
HOSTNAME="puppetserver"
STORAGE="local-lvm"
TEMPLATE="debian-12-standard_12.0-1_amd64.tar.zst"
BRIDGE="vmbr0"
DISK_SIZE="8G"
RAM="2048"
CPU="2"

# Usuario SSH dentro del LXC
USER="puppetadmin"
PASS="Puppet123!"

echo "==> Creando contenedor LXC Debian 12 con ID $CTID..."

pct create $CTID $STORAGE:templates/$TEMPLATE \
  --hostname $HOSTNAME \
  --memory $RAM \
  --cores $CPU \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --rootfs $STORAGE:$DISK_SIZE \
  --swap 512 \
  --unprivileged 0 \
  --password $PASS

echo "==> Iniciando contenedor..."
pct start $CTID

echo "==> Esperando que el contenedor arranque..."
sleep 15

echo "==> Instalando Puppetserver dentro del contenedor..."

# Ejecutar comandos dentro del LXC
pct exec $CTID -- bash -c "
  set -e
  apt update
  apt install -y wget gnupg2 curl lsb-release apt-transport-https software-properties-common openssh-server

  wget https://apt.puppet.com/puppet7-release-$(lsb_release -cs).deb -O /tmp/puppet-release.deb
  dpkg -i /tmp/puppet-release.deb
  apt update
  apt install -y puppetserver

  # Configurar memoria puppetserver
  sed -i 's/-Xms2g/-Xms2g/' /etc/default/puppetserver
  sed -i 's/-Xmx2g/-Xmx2g/' /etc/default/puppetserver

  systemctl enable puppetserver
  systemctl start puppetserver

  # Crear usuario
  id $USER || useradd -m -s /bin/bash $USER
  echo \"$USER:$PASS\" | chpasswd

  # Permitir acceso ssh por password
  sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
  systemctl restart ssh
"

IP=$(pct exec $CTID -- hostname -I | awk '{print $1}')

echo "==> Contenedor creado y Puppetserver instalado."
echo "Conéctate via SSH:"
echo "ssh $USER@$IP"
echo "Contraseña: $PASS"
echo "Puppetserver corre en el puerto 8140."
