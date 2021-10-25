#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "This script needs to be run as root"
  exit
fi

if [ -n "$1" ]; then
  USERNAME=$1
  DOMAIN=$2
else
  read -p "Enter your ssh username (satoshi): " USERNAME
  read -p "Enter your domain (example.com): " DOMAIN
fi

export DOMAIN
export USERNAME

HOME="$(getent passwd $SUDO_USER | cut -d: -f6)"

# Generate SSH pair
ssh-keygen -t rsa -b 4096 -C "Umbrel" -f "$HOME/.ssh/id_rsa" -N ''
echo "******************************************************"
echo "****Permission the following public key in your VM****"
echo "******************************************************"
cat ~/.ssh/id_rsa.pub
read -p "Press enter to continue"

# Auto SSH
echo "Installing packages"
apt-get -y install autossh qrencode

echo "Copying the service definition"
envsubst < ./autossh-tunnel.service > /etc/systemd/system/autossh-tunnel.service

echo "Starting the service"
systemctl is-active --quiet autossh-tunnel.service && systemctl stop autossh-tunnel.service
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

#Final connection string
CERT="$(cat ~/umbrel/lnd/tls.cert | sed '1,1d' | sed '$ d' | tr '/+' '_-' | tr -d '=\n')"
MACAROON="$(cat ~/umbrel/lnd/data/chain/bitcoin/mainnet/admin.macaroon | base64 | tr '/+' '_-' | tr -d '=\n')"
CONNECTION_STRING="lndconnect://$DOMAIN:10009?cert=$CERT&macaroon=$MACAROON"

qrencode -m 2 -s 2 -t ansiutf8 "$CONNECTION_STRING"

echo "*********************************************************"
echo "**Scan the QR code above or use this connection string:**"
echo "*********************************************************"
echo $CONNECTION_STRING