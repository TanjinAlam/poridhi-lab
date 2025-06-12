#!/bin/bash

# VXLAN Configuration Script

# Set the VXLAN interface name
VXLAN_INTERFACE="vxlan0"

# Set the VXLAN ID
VXLAN_ID=100

# Set the local IP address
LOCAL_IP="192.168.1.1"

# Set the remote IP address (for example, the IP of the other end of the VXLAN tunnel)
REMOTE_IP="192.168.1.2"

# Create the VXLAN interface
ip link add $VXLAN_INTERFACE type vxlan id $VXLAN_ID dev eth0 remote $REMOTE_IP local $LOCAL_IP ttl 255

# Bring up the VXLAN interface
ip link set up dev $VXLAN_INTERFACE

# Assign an IP address to the VXLAN interface
ip addr add 10.0.0.1/24 dev $VXLAN_INTERFACE

# Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Add a route for the remote VXLAN subnet
ip route add 10.0.0.0/24 dev $VXLAN_INTERFACE

# Display the VXLAN interface configuration
ip addr show $VXLAN_INTERFACE

# Display the routing table
ip route show

# End of script