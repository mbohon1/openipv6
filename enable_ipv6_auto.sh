#!/bin/bash

# Function to get the primary network interface
get_primary_interface() {
    ip route | grep default | awk '{print $5}' | head -n 1
}

# Enable IPv6 in sysctl.conf
echo "Enabling IPv6 in sysctl.conf..."
sudo sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
sudo sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 0" | sudo tee -a /etc/sysctl.conf

# Apply sysctl changes
echo "Applying sysctl changes..."
sudo sysctl -p

# Get the primary network interface
INTERFACE=$(get_primary_interface)
if [ -z "$INTERFACE" ]; then
    echo "No network interface found. Exiting."
    exit 1
fi

# Enable IPv6 on the interface directly
echo "Enabling IPv6 on interface $INTERFACE..."
sudo ip link set dev $INTERFACE up
sudo sysctl -w net.ipv6.conf.$INTERFACE.disable_ipv6=0

# Configure static IPv6 address and gateway
IPV6_ADDRESS="2001:19f0:5801:0c6e:5400:05ff:fe04:4980/64"
IPV6_GATEWAY="2001:19f0:5801:0c6e::1"

echo "Configuring static IPv6 address and gateway for interface $INTERFACE..."
sudo ip -6 addr add $IPV6_ADDRESS dev $INTERFACE
sudo ip -6 route add default via $IPV6_GATEWAY dev $INTERFACE

# Verify IPv6 configuration
echo "Verifying IPv6 configuration..."
ip -6 addr show dev $INTERFACE

echo "IPv6 configuration completed."
