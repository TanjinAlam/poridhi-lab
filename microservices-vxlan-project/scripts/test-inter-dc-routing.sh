#!/bin/bash

# Inter-Datacenter Routing Test Script
# Tests cross-datacenter communication and routing capabilities

echo "🌐 Inter-Datacenter Routing Test Suite"
echo "========================================"

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n "Testing $name... "
    response=$(curl -s "$url" 2>/dev/null)
    
    if [[ $response == *"$expected"* ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "  Expected: $expected"
        echo "  Got: $response"
        return 1
    fi
}

# Test direct datacenter access
echo -e "\n${BLUE}📍 Testing Direct Datacenter Access:${NC}"
test_endpoint "DC1 Direct" "http://localhost:80/" "API Gateway - DC1"
test_endpoint "DC2 Direct" "http://localhost:8080/" "API Gateway - DC2"
test_endpoint "DC3 Direct" "http://localhost:8081/" "API Gateway - DC3"

# Test cross-datacenter proxy routing
echo -e "\n${BLUE}🌐 Testing Cross-Datacenter Proxy Routing:${NC}"
test_endpoint "DC1→DC2 Proxy" "http://localhost:80/route/dc2/" "API Gateway - DC2"
test_endpoint "DC1→DC3 Proxy" "http://localhost:80/route/dc3/" "API Gateway - DC3"
test_endpoint "DC2→DC1 Proxy" "http://localhost:8080/route/dc1/" "API Gateway - DC1"
test_endpoint "DC2→DC3 Proxy" "http://localhost:8080/route/dc3/" "API Gateway - DC3"
test_endpoint "DC3→DC1 Proxy" "http://localhost:8081/route/dc1/" "API Gateway - DC1"
test_endpoint "DC3→DC2 Proxy" "http://localhost:8081/route/dc2/" "API Gateway - DC2"

# Test service discovery routing
echo -e "\n${BLUE}🔍 Testing Service Discovery Routing:${NC}"
test_endpoint "Discovery Direct" "http://localhost:8500/" '"total_services"'
test_endpoint "Discovery via DC1" "http://localhost:80/api/discovery/" '"total_services"'
test_endpoint "Discovery via DC2" "http://localhost:8080/api/discovery/" '"total_services"'
test_endpoint "Discovery via DC3" "http://localhost:8081/api/discovery/" '"total_services"'

# Test enhanced health endpoints
echo -e "\n${BLUE}🏥 Testing Enhanced Health Endpoints:${NC}"
test_endpoint "DC1 Health" "http://localhost:80/health" '"inter_dc_routing"'
test_endpoint "DC2 Health" "http://localhost:8080/health" '"inter_dc_routing"'
test_endpoint "DC3 Health" "http://localhost:8081/health" '"inter_dc_routing"'

# Test routing information endpoints
echo -e "\n${BLUE}📊 Testing Routing Information:${NC}"
test_endpoint "DC1 Routing Info" "http://localhost:80/api/routing" '"routing_table"'
test_endpoint "DC2 Routing Info" "http://localhost:8080/api/routing" '"routing_table"'
test_endpoint "DC3 Routing Info" "http://localhost:8081/api/routing" '"routing_table"'
test_endpoint "Discovery Routing" "http://localhost:8500/api/routing" '"inter_dc_backbone"'

# Test cross-datacenter service queries
echo -e "\n${BLUE}🔎 Testing Cross-Datacenter Service Discovery:${NC}"
test_endpoint "DC1 Services" "http://localhost:8500/api/dc1/services" '"gateway:80"'
test_endpoint "DC2 Services" "http://localhost:8500/api/dc2/services" '"payment:8085"'
test_endpoint "DC3 Services" "http://localhost:8500/api/dc3/services" '"discovery:8500"'

echo -e "\n${YELLOW}📋 Network Topology Summary:${NC}"
echo "  DC1 Backbone: 192.168.100.10"
echo "  DC2 Backbone: 192.168.100.20"
echo "  DC3 Backbone: 192.168.100.30"
echo "  Discovery:    192.168.100.40"
echo "  Backbone Net: 192.168.100.0/24"

echo -e "\n${GREEN}🎯 Inter-Datacenter Routing Test Complete!${NC}"
