#!/bin/bash
apt -y update
apt -y upgrade
apt -y autoremove
apt -y install munin-node
rm /etc/munin/plugins/interrupts /etc/munin/plugins/irqstats
