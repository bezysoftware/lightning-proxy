#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "This script needs to be run as root"
  exit
fi

read -p "Enter your VM ssh username (satoshi): " VM_USERNAME
read -p "Enter your VM domain (example.com): " VM_DOMAIN

# run tunnel script locally on Pi
./setup-tunnel.sh $VM_USERNAME $VM_DOMAIN

# run server script remotely
ssh -t "$VM_USERNAME@$VM_DOMAIN" "sudo bash -s" < ./setup-server.sh