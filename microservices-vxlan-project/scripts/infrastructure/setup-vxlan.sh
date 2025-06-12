#!/bin/bash

# VXLAN Network Setup Script for Multi-Datacenter Microservices
# Author: DevOps Team
# Date: June 11, 2025

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
UDP_PORT=4789
MULTICAST_GROUP="239.1.1.1"

# Datacenter-specific VXLAN configurations
DC1_VXLAN_ID=200
DC1_SUBNET="10.1.0.0/16"
DC1_GATEWAY="10.1.0.1"
DC1_INTERFACE="vxlan200"
DC1_BRIDGE="br-dc1"

DC2_VXLAN_ID=300
DC2_SUBNET="10.2.0.0/16"
DC2_GATEWAY="10.2.0.1"
DC2_INTERFACE="vxlan300"
DC2_BRIDGE="br-dc2"

DC3_VXLAN_ID=400
DC3_SUBNET="10.3.0.0/16"
DC3_GATEWAY="10.3.0.1"
DC3_INTERFACE="vxlan400"
DC3_BRIDGE="br-dc3"

echo -e "${BLUE}Setting up VXLAN network infrastructure...${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Check if VXLAN module is available
if ! modinfo vxlan > /dev/null 2>&1; then
    echo -e "${RED}VXLAN kernel module not available${NC}"
    exit 1
fi

# Load VXLAN module
echo -e "${YELLOW}Loading VXLAN kernel module...${NC}"
modprobe vxlan

# Create VXLAN interfaces for each datacenter
create_vxlan_datacenter() {
    local DC_ID=$1
    local VXLAN_ID=$2
    local VXLAN_INTERFACE=$3
    local BRIDGE_INTERFACE=$4
    local GATEWAY_IP=$5
    local SUBNET=$6
    
    echo -e "${YELLOW}Creating VXLAN infrastructure for DC${DC_ID}...${NC}"
    
    # Remove existing interfaces if they exist
    if ip link show ${VXLAN_INTERFACE} > /dev/null 2>&1; then
        echo -e "${YELLOW}VXLAN interface ${VXLAN_INTERFACE} already exists, deleting...${NC}"
        ip link delete ${VXLAN_INTERFACE}
    fi
    
    if ip link show ${BRIDGE_INTERFACE} > /dev/null 2>&1; then
        echo -e "${YELLOW}Bridge interface ${BRIDGE_INTERFACE} already exists, deleting...${NC}"
        ip link delete ${BRIDGE_INTERFACE}
    fi
    
    # Create VXLAN interface
    ip link add ${VXLAN_INTERFACE} type vxlan \
        id ${VXLAN_ID} \
        group ${MULTICAST_GROUP} \
        dstport ${UDP_PORT} \
        dev $(ip route | grep default | awk '{print $5}' | head -n1)
    
    # Create bridge interface
    ip link add name ${BRIDGE_INTERFACE} type bridge
    
    # Add VXLAN to bridge
    ip link set ${VXLAN_INTERFACE} master ${BRIDGE_INTERFACE}
    
    # Bring interfaces up
    ip link set ${VXLAN_INTERFACE} up
    ip link set ${BRIDGE_INTERFACE} up
    
    # Configure bridge IP
    ip addr add ${GATEWAY_IP}/16 dev ${BRIDGE_INTERFACE}
    
    echo -e "${GREEN}DC${DC_ID} VXLAN infrastructure created successfully${NC}"
    echo "  VXLAN ID: ${VXLAN_ID}"
    echo "  Interface: ${VXLAN_INTERFACE}"
    echo "  Bridge: ${BRIDGE_INTERFACE}"
    echo "  Gateway: ${GATEWAY_IP}"
    echo "  Subnet: ${SUBNET}"
    echo ""
}

# Create VXLAN infrastructure for each datacenter
create_vxlan_datacenter "1" ${DC1_VXLAN_ID} ${DC1_INTERFACE} ${DC1_BRIDGE} ${DC1_GATEWAY} ${DC1_SUBNET}
create_vxlan_datacenter "2" ${DC2_VXLAN_ID} ${DC2_INTERFACE} ${DC2_BRIDGE} ${DC2_GATEWAY} ${DC2_SUBNET}
create_vxlan_datacenter "3" ${DC3_VXLAN_ID} ${DC3_INTERFACE} ${DC3_BRIDGE} ${DC3_GATEWAY} ${DC3_SUBNET}

# Enable IP forwarding
echo -e "${YELLOW}Enabling IP forwarding...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward

# Enable IP forwarding
echo -e "${YELLOW}Enabling IP forwarding...${NC}"
echo 1 > /proc/sys/net/ipv4/ip_forward

# Create inter-datacenter routing
echo -e "${YELLOW}Setting up inter-datacenter routing...${NC}"
ip route add ${DC1_SUBNET} via ${DC1_GATEWAY} dev ${DC1_BRIDGE} 2>/dev/null || true
ip route add ${DC2_SUBNET} via ${DC2_GATEWAY} dev ${DC2_BRIDGE} 2>/dev/null || true
ip route add ${DC3_SUBNET} via ${DC3_GATEWAY} dev ${DC3_BRIDGE} 2>/dev/null || true

# Display network configuration
echo -e "${GREEN}Multi-Datacenter VXLAN network setup completed!${NC}"
echo ""
echo -e "${BLUE}=== Datacenter Network Configuration ===${NC}"
echo ""
echo -e "${BLUE}DC1 (North America - Primary):${NC}"
echo "  VXLAN ID: ${DC1_VXLAN_ID}"
echo "  Interface: ${DC1_INTERFACE}"
echo "  Bridge: ${DC1_BRIDGE}"
echo "  Subnet: ${DC1_SUBNET}"
echo "  Gateway: ${DC1_GATEWAY}"
echo ""
echo -e "${BLUE}DC2 (Europe - Secondary):${NC}"
echo "  VXLAN ID: ${DC2_VXLAN_ID}"
echo "  Interface: ${DC2_INTERFACE}"
echo "  Bridge: ${DC2_BRIDGE}"
echo "  Subnet: ${DC2_SUBNET}"
echo "  Gateway: ${DC2_GATEWAY}"
echo ""
echo -e "${BLUE}DC3 (Asia-Pacific - DR):${NC}"
echo "  VXLAN ID: ${DC3_VXLAN_ID}"
echo "  Interface: ${DC3_INTERFACE}"
echo "  Bridge: ${DC3_BRIDGE}"
echo "  Subnet: ${DC3_SUBNET}"
echo "  Gateway: ${DC3_GATEWAY}"
echo ""
echo -e "${BLUE}Verification Commands:${NC}"
echo "ip link show type vxlan"
echo "bridge link show"
echo "ip route show"

exit 0