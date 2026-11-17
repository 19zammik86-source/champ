#!/bin/bash
hostnamectl set-hostname gw-core.ssa.prof; exec bash
useradd master
passwd master
usermod -aG wheel master
echo "master ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/master
mkdir -p /etc/net/ifaces/ens19 /etc/net/ifaces/ens20 /etc/net/ifaces/ens21 /etc/net/ifaces/dummy0
echo "TYPE=eth" > /etc/net/ifaces/ens19/options
echo "TYPE=eth" > /etc/net/ifaces/ens20/options
echo "TYPE=eth" > /etc/net/ifaces/ens21/options
echo "TYPE=dummy" > /etc/net/ifaces/dummy0/options
echo "84.212.78.1/27" > /etc/net/ifaces/ens19/ipv4address  
echo "63.27.18.1/23" > /etc/net/ifaces/ens20/ipv4address   
echo "34.95.33.1/24" > /etc/net/ifaces/ens21/ipv4address   
echo "44.44.44.44/32" > /etc/net/ifaces/dummy0/ipv4address 
systemctl restart network
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g" /etc/net/sysctl.conf
systemctl restart network
apt-get update && apt-get install -y frr
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
sed -i 's/isisd=no/isisd=yes/g' /etc/frr/daemons
systemctl enable --now frr
ss -tulpn | grep -E 'bgp|isis'
vtysh
configure terminal
router isis 1
 is-type level-1
 net 49.0000.0440.4404.4044.00
 metric-style wide
 exit
interface dummy0
 ip router isis 1
 exit
interface ens19
 ip router isis 1
 exit
interface ens20
 ip router isis 1
 exit
interface ens21
 ip router isis 1
 exit
router bgp 64499
 bgp router-id 44.44.44.44
 no bgp ebgp-requires-policy
 neighbor 11.11.11.11 remote-as 64499
 neighbor 22.22.22.22 remote-as 64499
 neighbor 33.33.33.33 remote-as 64499
 address-family ipv4 unicast
  neighbor 11.11.11.11 default-originate
  neighbor 22.22.22.22 default-originate
  neighbor 33.33.33.33 default-originate
  exit
 exit
exit
write
exit
nft add table ip nat
nft add chain ip nat postrouting '{ type nat hook postrouting priority 0; }'
nft add rule ip nat postrouting ip saddr 78.23.0.0/16 oifname "ens18" counter masquerade
nft add rule ip nat postrouting ip saddr 212.78.93.0/24 oifname "ens18" counter masquerade
nft list ruleset | tee -a /etc/nftables/nftables.nft
nft flush ruleset
systemctl enable --now nftables.service
nft list ruleset

