#!/bin/bash

# This script sets up firewall rules for the network.

# Define the firewall rules
FIREWALL_RULES=(
    "iptables -A INPUT -p tcp --dport 80 -j ACCEPT"   # Allow HTTP
    "iptables -A INPUT -p tcp --dport 443 -j ACCEPT"  # Allow HTTPS
    "iptables -A INPUT -p tcp --dport 8080 -j ACCEPT"  # Allow custom service port
    "iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT"  # Allow established connections
    "iptables -A INPUT -j DROP"  # Drop all other incoming traffic
)

# Apply the firewall rules
for rule in "${FIREWALL_RULES[@]}"; do
    eval $rule
done

echo "Firewall rules have been set up successfully."