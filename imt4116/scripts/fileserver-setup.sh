#!/bin/bash

echo "Setup inside interface"
echo "\
network:
    version: 2
    ethernets:
        ens4:
            dhcp4: true" >> /etc/netplan/99-internal.yaml

echo "\
[Match]
Name=ens4

[Network]
DHCP=ipv4

[DHCP]
UseRoutes=false" >> /etc/systemd/network/10-netplan-ens4.network

systemctl daemon-reload
systemctl restart systemd-networkd
netplan apply

# Install Samba
apt-get update && apt -y install samba

echo "Creating a folder for samba to share..."
mkdir -p /srv/share && chmod 777 /srv/share

echo "Configuring samba to share that folder and only listen on inside interface"

sed -i "s|;   interfaces = 127.0.0.0/8 eth0|   interfaces = ens4|" /etc/samba/smb.conf
sed -i 's/;   bind interfaces only = yes/   bind interfaces only = yes/' /etc/samba/smb.conf

echo "\
[share] 
  path = /srv/share
  browseable = yes
  guest ok = yes
  read only = yes" >> /etc/samba/smb.conf

echo "Restarting samba"
systemctl restart smbd.service

echo "Finished!"
exit 0

