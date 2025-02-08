#!/bin/bash

#############################################################################
# Network Setup and Configuration Script
# 
# This script implements a network topology with two isolated namespaces
# connected through a router namespace using Linux bridges.
#
# Author: [Your Name]
# Date: [Current Date]
#
# Technical Requirements:
# - Requires root privileges
# - Tested on Linux kernel version 5.x
# - Required packages: iproute2, bridge-utils, iptables
#
# IP Addressing Scheme:
# - Network 1 (br0): 10.11.0.0/24
#   * Bridge IP: 10.11.0.1
#   * NS1 IP: 10.11.0.2
#   * Router IP: 10.11.0.3
#
# - Network 2 (br1): 10.12.0.0/24
#   * Bridge IP: 10.12.0.1
#   * NS2 IP: 10.12.0.2
#   * Router IP: 10.12.0.3
#
# Usage: ./script.sh [setup|cleanup|ping|status]
#############################################################################

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Log file setup
LOG_FILE="/var/log/network_setup.log"
exec 1> >(tee -a "${LOG_FILE}")
exec 2>&1

# Function to check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root"
        exit 1
    fi
}

# Function to check required tools
check_requirements() {
    local required_tools=("ip" "bridge" "iptables")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "Required tool not found: $tool"
            exit 1
        fi
    done
}

# Function to show current status
show_status() {
    echo "Current Network Status"
    echo "====================="
    
    echo -e "\nNetwork Namespaces:"
    ip netns list
    
    echo -e "\nBridge Status:"
    bridge link show
    
    echo -e "\nInterface Status:"
    ip -all netns exec ip addr show
    
    echo -e "\nRouting Tables:"
    for ns in ns1 ns2 router-ns; do
        if ip netns list | grep -q "$ns"; then
            echo -e "\n$ns routing table:"
            ip netns exec "$ns" ip route list
        fi
    done
    
    echo -e "\nIPtables Rules:"
    iptables -L FORWARD -n -v
}


# Cleanup function
cleanup_network() {
    echo "Starting network cleanup..."
    
    # Remove iptables rules
    echo "Removing iptables rules..."
    sudo iptables -D FORWARD -i br0 -j ACCEPT 2>/dev/null
    sudo iptables -D FORWARD -o br0 -j ACCEPT 2>/dev/null
    sudo iptables -D FORWARD -i br1 -j ACCEPT 2>/dev/null
    sudo iptables -D FORWARD -o br1 -j ACCEPT 2>/dev/null
    
    # Delete veth pairs
    echo "Removing veth pairs..."
    sudo ip link del v-red 2>/dev/null
    sudo ip link del v-blue 2>/dev/null
    sudo ip link del v1-bridge 2>/dev/null
    sudo ip link del v2-bridge 2>/dev/null
    
    # Delete network namespaces
    echo "Removing network namespaces..."
    sudo ip netns del ns1 2>/dev/null
    sudo ip netns del ns2 2>/dev/null
    sudo ip netns del router-ns 2>/dev/null
    
    # Delete bridges
    echo "Removing bridges..."
    sudo ip link set br0 down 2>/dev/null
    sudo ip link set br1 down 2>/dev/null
    sudo ip link del br0 type bridge 2>/dev/null
    sudo ip link del br1 type bridge 2>/dev/null
    
    # Reset IP forwarding
    echo "Resetting IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=0 >/dev/null
    
    # Verify cleanup
    verify_cleanup
}

# Function to verify cleanup
verify_cleanup() {
    echo "Verifying cleanup..."
    remaining_ns=$(ip netns list 2>/dev/null)
    remaining_bridges=$(bridge link show 2>/dev/null)
    
    if [ -n "$remaining_ns" ]; then
        echo "Warning: Some network namespaces still exist:"
        echo "$remaining_ns"
    fi
    
    if [ -n "$remaining_bridges" ]; then
        echo "Warning: Some bridge connections still exist:"
        echo "$remaining_bridges"
    fi
    
    echo "Cleanup completed."
}

# Function to test connectivity
test_connectivity() {
    echo "Testing network connectivity..."
    
    # Test ns1 to ns2
    echo "Testing ping from ns1 to ns2 (10.12.0.2):"
    sudo ip netns exec ns1 ping -c 3 10.12.0.2
    
    # Test ns2 to ns1
    echo "Testing ping from ns2 to ns1 (10.11.0.2):"
    sudo ip netns exec ns2 ping -c 3 10.11.0.2
    
    # Test connectivity to router
    echo "Testing ping from ns1 to router (10.11.0.3):"
    sudo ip netns exec ns1 ping -c 3 10.11.0.3
    
    echo "Testing ping from ns2 to router (10.12.0.3):"
    sudo ip netns exec ns2 ping -c 3 10.12.0.3
    
    # Show current routes
    echo -e "\nCurrent routes in ns1:"
    sudo ip netns exec ns1 ip route
    echo -e "\nCurrent routes in ns2:"
    sudo ip netns exec ns2 ip route
    echo -e "\nCurrent routes in router-ns:"
    sudo ip netns exec router-ns ip route
}

# Function to check command success
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Function to verify interface is up
verify_interface() {
    local ns=$1
    local interface=$2
    local state=$(ip netns exec $ns ip link show $interface 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
    if [ "$state" != "UP" ]; then
        echo "Warning: Interface $interface in namespace $ns is not UP"
        return 1
    fi
    return 0
}

# Function to setup network
setup_network() {
    echo "Starting network setup..."

    # Create and configure br0
    echo "Creating bridge br0..."
    sudo ip link add br0 type bridge
    check_command "br0 creation"
    sudo ip link set dev br0 up
    sudo ip addr add 10.11.0.1/24 dev br0

    # Create and configure br1
    echo "Creating bridge br1..."
    sudo ip link add br1 type bridge
    check_command "br1 creation"
    sudo ip link set dev br1 up
    sudo ip addr add 10.12.0.1/24 dev br1

    # Create namespaces
    echo "Creating network namespaces..."
    sudo ip netns add ns1
    check_command "ns1 creation"
    sudo ip netns exec ns1 ip link set lo up

    sudo ip netns add ns2
    check_command "ns2 creation"
    sudo ip netns exec ns2 ip link set lo up

    sudo ip netns add router-ns
    check_command "router-ns creation"
    sudo ip netns exec router-ns ip link set lo up

    # Create and configure veth for ns1
    echo "Configuring ns1 networking..."
    sudo ip link add v-red-ns type veth peer name v-red
    check_command "veth creation for ns1"
    sudo ip link set dev v-red-ns netns ns1
    sudo ip link set dev v-red master br0
    sudo ip netns exec ns1 ip address add 10.11.0.2/24 dev v-red-ns
    sudo ip netns exec ns1 ip link set dev v-red-ns up
    sudo ip link set dev v-red up
    verify_interface "ns1" "v-red-ns"

    # Create and configure veth for ns2
    echo "Configuring ns2 networking..."
    sudo ip link add v-blue-ns type veth peer name v-blue
    check_command "veth creation for ns2"
    sudo ip link set dev v-blue-ns netns ns2
    sudo ip link set dev v-blue master br1
    sudo ip netns exec ns2 ip address add 10.12.0.2/24 dev v-blue-ns
    sudo ip netns exec ns2 ip link set dev v-blue-ns up
    sudo ip link set dev v-blue up
    verify_interface "ns2" "v-blue-ns"

    # Configure router connections
    echo "Configuring router networking..."
    setup_router_connections

    # Enable IP forwarding
    echo "Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo ip netns exec router-ns sysctl -w net.ipv4.ip_forward=1

    # Configure iptables and routing
    configure_networking

    # Verify setup
    verify_setup
}

# Function to setup router connections
setup_router_connections() {
    sudo ip link add v1-router type veth peer name v1-bridge
    sudo ip link add v2-router type veth peer name v2-bridge

    # Connect router-ns to br0
    sudo ip link set dev v1-router netns router-ns
    sudo ip link set dev v1-bridge master br0
    sudo ip netns exec router-ns ip addr add 10.11.0.3/24 dev v1-router
    sudo ip netns exec router-ns ip link set dev v1-router up
    sudo ip link set dev v1-bridge up

    # Connect router-ns to br1
    sudo ip link set dev v2-router netns router-ns
    sudo ip link set dev v2-bridge master br1
    sudo ip netns exec router-ns ip addr add 10.12.0.3/24 dev v2-router
    sudo ip netns exec router-ns ip link set dev v2-router up
    sudo ip link set dev v2-bridge up
}

# Function to configure networking
configure_networking() {
    # Configure iptables
    sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
    sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT
    sudo iptables --append FORWARD --in-interface br1 --jump ACCEPT
    sudo iptables --append FORWARD --out-interface br1 --jump ACCEPT

    # Configure routing
    sudo ip netns exec ns1 ip route add default via 10.11.0.3
    sudo ip netns exec ns2 ip route add default via 10.12.0.3
}

# Function to verify setup
verify_setup() {
    echo "Verifying setup..."
    
    # Show network state
    echo "Network state:"
    bridge link show
    ip -all netns list
}


# Function to validate setup
validate_setup() {
    local errors=0
    
    # Check namespace existence
    for ns in ns1 ns2 router-ns; do
        if ! ip netns list | grep -q "$ns"; then
            echo "Error: Namespace $ns not found"
            errors=$((errors + 1))
        fi
    done
    
    # Check bridge existence
    for br in br0 br1; do
        if ! ip link show "$br" &>/dev/null; then
            echo "Error: Bridge $br not found"
            errors=$((errors + 1))
        fi
    done
    
    # Check routing
    if ! ip netns exec ns1 ip route | grep -q "default via 10.11.0.3"; then
        echo "Error: Default route in ns1 not properly configured"
        errors=$((errors + 1))
    fi
    
    if ! ip netns exec ns2 ip route | grep -q "default via 10.12.0.3"; then
        echo "Error: Default route in ns2 not properly configured"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        echo "Setup validation successful"
        return 0
    else
        echo "Setup validation failed with $errors errors"
        return 1
    fi
}

# Main execution
main() {
    check_root
    check_requirements
    
    case "$1" in
        "setup")
            setup_network
            validate_setup
            ;;
        "cleanup")
            cleanup_network
            ;;
        "ping")
            test_connectivity
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Usage: $0 [setup|cleanup|ping|status]"
            echo "  setup   - Set up network configuration"
            echo "  cleanup - Clean up network configuration"
            echo "  ping    - Test network connectivity"
            echo "  status  - Show current network status"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"