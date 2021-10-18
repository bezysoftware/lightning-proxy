#!/bin/bash

export DOMAIN="bezysoftware.cz"
export USERNAME="bezysoftware"

if [ "$EUID" -ne 0 ]
  then echo "This script needs to be run as root"
  exit
fi

HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"

# Generate SSH pair
ssh-keygen -t rsa -b 4096 -C "Umbrel" -f "$HOME/.ssh/id_rsa" -N ''
echo "Use the following public key in your VM:"
cat ~/.ssh/id_rsa.pub
read -p "Press enter to continue"

# Auto SSH
echo "Installing autossh"
apt-get install autossh

echo "Copying the service definition"
envsubst < ./autossh-tunnel.service > /etc/systemd/system/autossh-tunnel.service

echo "Starting the service"
systemctl daemon-reload
systemctl start autossh-tunnel.service
systemctl enable autossh-tunnel.service

#LND config
if grep -Fxq "tlsextradomain=$DOMAIN" ~/umbrel/lnd/lnd.conf
then
  echo "LND is already configured"
else
  echo "Configuring LND"
  sed -i.BAK "/^\[Application Options\]/a\tlsextradomain=$DOMAIN" ~/umbrel/lnd/lnd.conf
  LND_CONTAINER=$(docker ps | grep "lnd:" | cut -d" " -f1)
  docker restart $LND_CONTAINER
fi