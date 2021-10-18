#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "This script needs to be run as root"
  exit
fi

# nettools for debugging
# e.g. sudo netstat -tulpn | grep LISTEN
apt-get install net-tools

# allow port forwarding from outside the server
if test -f /etc/ssh/sshd_config.d/gatewayports.conf
then
  echo "GatewayPorts already configured"
else
  echo "Configuring GatewayPorts"
  "GatewayPorts yes" > /etc/ssh/sshd_config.d/gatewayports.conf
  systemctl restart ssh.service
fi