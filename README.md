[Česky zde](README_cs.md)

# Lightning server proxy
Set of scripts to expose private lightning server (e.g. Umbrel one) through public proxy server

## Motivation
You have your bitcoin/lightning node setup on your home server (Raspberry Pi) and you want to access it externally using a wallet on your phone. Chances are you're using a solution like [Umbrel](https://getumbrel.com/) which orchestrates everything for you and gives you onion addresses to connect to. On your phone you install [Zap](https://github.com/LN-Zap/) or similar and connect to your node using that onion address. Everything works. 

Then you actually come to a cafe, order and want to pay. You pull out your phone, launch Zap, and wait for Tor to establish a connection. For 30s. Maybe you panic and restart the app. You wait again. People are lining up behind you. All sweaty you capitulate and end up paying by card. 

Or perhaps you're not behind Tor, but have your server behind a router and you don't want to setup port forwarding. Or you don't have a static IP address at all.

Or you want to use LN-URL.

## Solution
The solution is to have a publicly accessible server with static IP that you can use to forward incoming traffic to a specific port to your home server (Raspberry). Obviously the connection needs to be initiated from your end towards the public server. Best way to do that is to use SSH. From high level it will look like this:

![Overview](img/overview.png)

Where you get your server is up to you - one possible choice would be to use Azure VM (e.g. [Standard_B2s](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable) - 2 vcpus, 4 GiB memory ~ 28€/month, but the are also cheaper options).

You're also going to need your own domain, e.g. `example.com` which you point to your VM's IP **static** address (setting `A record` at your registrar's administration).

## Setup

For simplicity I'm going to assume you already have a domain pointed to your VM in Azure and an Umbrel instance running on Raspberry Pi.

1. Clone this repo to your Pi: 
```bash
ssh umbrel@umbrel.local
git clone git@github.com:bezysoftware/lightning-proxy.git
```
2. Run the setup script and follow instructions
```bash
cd ./lightning-proxy/scripts
sudo ./setup.sh
```

What it does:
1. Generates a new SSH key pair and prints the public key you need to permission on the VM (e.g. in your Azure Portal VM Reset Password page)
2. Sets up a [AutoSSH](https://www.everythingcli.org/ssh-tunnelling-for-fun-and-profit-autossh/) service which tunnels the **10009** port to the VM
3. Forces LND to regenerate its certificate and include your domain in it (it restarts LND's docker container)
4. Gives you a LND connection string / QR code you can scan with your wallet

![QR Code](img/qr.png)

5. On your proxy VM it allows forwarding ports from outside of the server (by default SSH only allows forwarding ports from localhost)

It also installs `net-tools` so you can use `netstat` to monitor bound ports (useful for debugging), e.g.:
```bash
sudo netstat -tulpn | grep LISTEN
``` 

## Thoughts, issues, ideas?
If you have any concerns or ideas how to automate the whole process even more (auto provision custom VM, generate connection string in the script etc.) raise an issue / PR.