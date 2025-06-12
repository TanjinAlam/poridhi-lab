#!/bin/bash

# Network Diagnostics Script for Multi-Datacenter VXLAN
# Author: DevOps Team
# Date: June 11, 2025

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Multi-Datacenter VXLAN Network Diagnostics ===${NC}"
echo ""

# Check VXLAN interfaces
echo -e "${YELLOW}1. VXLAN Interfaces:${NC}"
if ip link show type vxlan > /dev/null 2>&1; then
    ip link show type vxlan
    echo -e "${GREEN}✓ VXLAN interfaces found${NC}"
else
    echo -e "${RED}✗ No VXLAN interfaces found${NC}"
fi
echo ""

# Check bridge interfaces
echo -e "${YELLOW}2. Bridge Interfaces:${NC}"
if ip link show type bridge > /dev/null 2>&1; then
    ip link show type bridge
    echo -e "${GREEN}✓ Bridge interfaces found${NC}"
else
    echo -e "${RED}✗ No bridge interfaces found${NC}"
fi
echo ""

# Test datacenter connectivity
echo -e "${YELLOW}3. Datacenter Connectivity Test:${NC}"
test_connectivity() {
    local dc_name=$1
    local port=$2
    local url="http://localhost:${port}/"
    
    if curl -s --connect-timeout 3 "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ${dc_name} (Port ${port}): Reachable${NC}"
    else
        echo -e "${RED}✗ ${dc_name} (Port ${port}): Not reachable${NC}"
    fi
}

test_connectivity "DC1 Gateway" "80"
test_connectivity "DC2 Gateway" "8080" 
test_connectivity "DC3 Gateway" "8081"
test_connectivity "User Service" "8082"
test_connectivity "Discovery Service" "8500"
echo ""

# Check Docker containers
echo -e "${YELLOW}4. Container Status:${NC}"
if command -v docker > /dev/null 2>&1; then
    CONTAINERS=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(gateway|dc[1-3])")
    if [[ -n "$CONTAINERS" ]]; then
        echo "$CONTAINERS"
        echo -e "${GREEN}✓ Gateway containers are running${NC}"
    else
        echo -e "${YELLOW}! No gateway containers running${NC}"
    fi
else
    echo -e "${RED}✗ Docker not available${NC}"
fi
echo ""

echo -e "${BLUE}Network diagnostics completed.${NC}"