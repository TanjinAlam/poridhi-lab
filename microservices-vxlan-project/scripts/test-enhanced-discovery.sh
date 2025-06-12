#!/bin/bash

# Enhanced Service Discovery Test Suite
# Tests the cross-datacenter service discovery functionality

set -e

BASE_URL="http://localhost:8500"
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Enhanced Service Discovery Test Suite${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local description=$2
    local expected_content=$3
    
    echo -n "Testing $description... "
    
    response=$(curl -s -w "%{http_code}" "$BASE_URL$endpoint")
    http_code=${response: -3}
    content=${response%???}
    
    if [ "$http_code" = "200" ]; then
        if [ -n "$expected_content" ]; then
            if echo "$content" | grep -q "$expected_content"; then
                echo -e "${GREEN}✅ PASS${NC}"
                return 0
            else
                echo -e "${RED}❌ FAIL (Content mismatch)${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}✅ PASS${NC}"
            return 0
        fi
    else
        echo -e "${RED}❌ FAIL (HTTP $http_code)${NC}"
        return 1
    fi
}

# Function to test headers
test_headers() {
    local endpoint=$1
    local description=$2
    local expected_header=$3
    
    echo -n "Testing $description headers... "
    
    headers=$(curl -I -s "$BASE_URL$endpoint")
    
    if echo "$headers" | grep -q "$expected_header"; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (Header missing)${NC}"
        return 1
    fi
}

# Test counters
total_tests=0
passed_tests=0

# Main discovery service tests
echo -e "${YELLOW}1. Core Discovery Service Tests${NC}"
echo "--------------------------------"

test_endpoint "/" "Main discovery endpoint" "multi-datacenter-service-discovery"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/services" "Service registry endpoint" "multi-datacenter-service-discovery"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/health" "Health check endpoint" "healthy"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/" "Main discovery service" "X-Discovery-Service"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

echo ""

# Cross-datacenter service queries
echo -e "${YELLOW}2. Cross-Datacenter Service Discovery Tests${NC}"
echo "--------------------------------------------"

test_endpoint "/api/dc1/services" "DC1 services query" "North-America"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/api/dc2/services" "DC2 services query" "Europe"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/api/dc3/services" "DC3 services query" "Asia-Pacific"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/dc1/services" "DC1 cross-DC query" "X-Cross-DC-Query"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/dc2/services" "DC2 cross-DC query" "X-Query-Source"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

echo ""

# Network topology and routing tests
echo -e "${YELLOW}3. Network Topology and Routing Tests${NC}"
echo "--------------------------------------"

test_endpoint "/api/routing" "Routing information" "inter_dc_backbone"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/api/topology" "Topology information" "multi_datacenter"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_endpoint "/api/health/global" "Global health status" "global_health"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/routing" "Routing info" "X-Routing-Info"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/topology" "Topology info" "X-Topology-Info"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

echo ""

# Gateway discovery tests
echo -e "${YELLOW}4. Gateway Discovery Tests${NC}"
echo "----------------------------"

test_endpoint "/api/services/gateways" "Gateway discovery" "service_type"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/services/gateways" "Gateway discovery" "X-Service-Type"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

echo ""

# Enhanced health monitoring tests
echo -e "${YELLOW}5. Enhanced Health Monitoring Tests${NC}"
echo "------------------------------------"

test_headers "/health" "Enhanced health check" "X-Service-Discovery-Version"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

test_headers "/api/health/global" "Global health monitoring" "X-Global-Health"
total_tests=$((total_tests + 1)); [ $? -eq 0 ] && passed_tests=$((passed_tests + 1))

echo ""

# Summary
echo -e "${BLUE}Test Results Summary${NC}"
echo -e "${BLUE}====================${NC}"
echo "Total Tests: $total_tests"
echo -e "Passed: ${GREEN}$passed_tests${NC}"
echo -e "Failed: ${RED}$((total_tests - passed_tests))${NC}"

if [ $passed_tests -eq $total_tests ]; then
    echo -e "${GREEN}🎉 All tests passed! Enhanced service discovery is working perfectly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please check the configuration.${NC}"
    exit 1
fi
