#!/bin/bash

# Function to get the primary network interface
get_primary_interface() {
    ip route | grep default | awk '{print $5}' | head -n 1
}

# Enable IPv6 in sysctl.conf and configure IP forwarding if necessary
echo "Configuring sysctl for IPv6..."
sudo sed -i '/net.ipv6.conf.all.accept_ra/d' /etc/sysctl.conf
sudo sed -i '/net.ipv6.conf.eth0.accept_ra/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_ra = 2" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.eth0.accept_ra = 2" | sudo tee -a /etc/sysctl.conf

# Apply sysctl changes
echo "Applying sysctl changes..."
sudo sysctl -p

# Get the primary network interface
INTERFACE=$(get_primary_interface)
if [ -z "$INTERFACE" ]; then
    echo "No network interface found. Exiting."
    exit 1
fi

# Configure network script for eth0 with IPv6 settings
echo "Configuring network script for $INTERFACE..."
sudo sed -i '/IPV6INIT/d' /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
sudo sed -i '/IPV6ADDR/d' /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
sudo sed -i '/IPV6_AUTOCONF/d' /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
sudo sed -i '/IPV6ADDR_SECONDARIES/d' /etc/sysconfig/network-scripts/ifcfg-$INTERFACE

echo 'IPV6INIT="yes"' | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
echo 'IPV6ADDR="2001:19f0:5801:c6e:5400:5ff:fe04:4980/64"' | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
echo 'IPV6_AUTOCONF="yes"' | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-$INTERFACE
echo 'IPV6ADDR_SECONDARIES="2001:19f0:4400:7835:5400:5ff:fe04:292c/64"' | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-$INTERFACE

# Restart networking service to apply changes
echo "Restarting networking service..."
sudo service network restart

# Verify IPv6 configuration and connectivity to gateway and public address
echo "Verifying IPv6 configuration..."
ip -6 addr show dev $INTERFACE

echo "Checking connectivity to the gateway..."
ping_result=$(ping6 -c 4 2001:19f0:5801:c6e::1)
if [[ $? -ne 0 ]]; then
    echo "Failed to reach the gateway at 2001:19f0:5801:c6e::1."
else
    echo "Successfully reached the gateway at 2001:19f0:5801:c6e::1."
fi

echo "Checking connectivity to a public IPv6 address..."
public_ping_result=$(ping6 -c 4 2001:4860:4860::8888)
if [[ $? -ne 0 ]]; then
    echo "Failed to reach the public IPv6 address at 2001:4860:4860::8888."
else
    echo "Successfully reached the public IPv6 address at 2001:4860:4860::8888."
fi

echo "IPv6 configuration completed."
