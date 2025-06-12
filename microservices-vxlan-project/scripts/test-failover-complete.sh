#!/bin/bash

# Comprehensive Failover Testing Script
# Tests all failover mechanisms across all datacenters

echo "🔄 Comprehensive Multi-Datacenter Failover Testing"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
PASSED=0
FAILED=0

test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n "Testing $name... "
    response=$(curl -s -w "%{http_code}" "$url" 2>/dev/null | tail -n1)
    
    if [[ "$response" == "200" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAIL (HTTP: $response)${NC}"
        ((FAILED++))
        return 1
    fi
}

test_failover_scenario() {
    local service_name="$1"
    local container_name="$2"
    local test_url="$3"
    local fallback_url="$4"
    
    echo -e "\n${BLUE}🔄 Testing $service_name Failover Scenario${NC}"
    echo "----------------------------------------"
    
    # 1. Test normal operation
    echo -n "1. Normal operation: "
    if test_endpoint "$service_name" "$test_url" "200"; then
        echo "   Service is running normally"
    fi
    
    # 2. Stop the service
    echo "2. Stopping $service_name..."
    docker stop "$container_name" >/dev/null 2>&1
    sleep 3
    
    # 3. Test failover
    echo -n "3. Testing failover mechanism: "
    response=$(curl -s "$fallback_url" 2>/dev/null)
    if [[ "$response" == *"fallback"* ]] || [[ "$response" == *"degraded"* ]] || [[ "$response" == *"unavailable"* ]]; then
        echo -e "${GREEN}✅ Failover Active${NC}"
        echo "   Fallback response received"
        ((PASSED++))
    else
        echo -e "${RED}❌ Failover Failed${NC}"
        echo "   Expected fallback response not received"
        ((FAILED++))
    fi
    
    # 4. Test fallback headers
    echo -n "4. Checking failover headers: "
    headers=$(curl -I -s "$fallback_url" 2>/dev/null | grep -i "fallback\|degraded\|backup")
    if [[ -n "$headers" ]]; then
        echo -e "${GREEN}✅ Headers Present${NC}"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  Headers Missing${NC}"
        ((FAILED++))
    fi
    
    # 5. Restart the service
    echo "5. Restarting $service_name..."
    docker start "$container_name" >/dev/null 2>&1
    sleep 5
    
    # 6. Test recovery
    echo -n "6. Testing service recovery: "
    if test_endpoint "$service_name Recovery" "$test_url" "200"; then
        echo "   Service recovered successfully"
    fi
}

test_cross_dc_failover() {
    echo -e "\n${BLUE}🌐 Testing Cross-Datacenter Failover${NC}"
    echo "====================================="
    
    # Test DC1 → DC2 failover
    echo -e "\n${YELLOW}Testing DC1 → DC2 Failover:${NC}"
    test_endpoint "DC1 → DC2 Normal" "http://localhost:80/route/dc2/" "200"
    
    echo "Stopping DC2 Gateway..."
    docker stop gateway-dc2-backup >/dev/null 2>&1
    sleep 3
    
    echo -n "Testing DC1 → DC2 Failover: "
    response=$(curl -s "http://localhost:80/route/dc2/" 2>/dev/null)
    if [[ "$response" == *"DC2 unavailable"* ]] || [[ "$response" == *"fallback"* ]]; then
        echo -e "${GREEN}✅ Failover Working${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Failover Failed${NC}"
        ((FAILED++))
    fi
    
    echo "Restarting DC2 Gateway..."
    docker start gateway-dc2-backup >/dev/null 2>&1
    sleep 5
    
    # Test DC1 → DC3 failover
    echo -e "\n${YELLOW}Testing DC1 → DC3 Failover:${NC}"
    test_endpoint "DC1 → DC3 Normal" "http://localhost:80/route/dc3/" "200"
    
    echo "Stopping DC3 Gateway..."
    docker stop gateway-dc3-standby >/dev/null 2>&1
    sleep 3
    
    echo -n "Testing DC1 → DC3 Failover: "
    response=$(curl -s "http://localhost:80/route/dc3/" 2>/dev/null)
    if [[ "$response" == *"DC3 unavailable"* ]] || [[ "$response" == *"fallback"* ]]; then
        echo -e "${GREEN}✅ Failover Working${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Failover Failed${NC}"
        ((FAILED++))
    fi
    
    echo "Restarting DC3 Gateway..."
    docker start gateway-dc3-standby >/dev/null 2>&1
    sleep 5
}

test_resilient_routing() {
    echo -e "\n${BLUE}🏆 Testing Resilient Load-Balanced Routing${NC}"
    echo "=========================================="
    
    # Test resilient routing from each datacenter
    for dc in 1 2 3; do
        case $dc in
            1) port="80"; name="DC1" ;;
            2) port="8080"; name="DC2" ;;
            3) port="8081"; name="DC3" ;;
        esac
        
        echo -n "Testing $name resilient routing: "
        response=$(curl -s "http://localhost:$port/route/resilient/" 2>/dev/null)
        if [[ -n "$response" ]]; then
            echo -e "${GREEN}✅ Working${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Failed${NC}"
            ((FAILED++))
        fi
    done
}

test_service_discovery_failover() {
    echo -e "\n${BLUE}🔍 Testing Service Discovery Failover${NC}"
    echo "====================================="
    
    # Test discovery service access from each gateway
    for dc in 1 2 3; do
        case $dc in
            1) port="80"; name="DC1" ;;
            2) port="8080"; name="DC2" ;;
            3) port="8081"; name="DC3" ;;
        esac
        
        echo -n "Testing $name → Discovery: "
        response=$(curl -s "http://localhost:$port/api/discovery/" 2>/dev/null)
        if [[ "$response" == *"service"* ]] || [[ "$response" == *"discovery"* ]]; then
            echo -e "${GREEN}✅ Connected${NC}"
            ((PASSED++))
        else
            echo -e "${RED}❌ Failed${NC}"
            ((FAILED++))
        fi
    done
    
    # Test discovery service direct failover
    echo "Testing Discovery Service Failover..."
    test_failover_scenario "Discovery Service" "discovery-service-dc3" "http://localhost:8500/" "http://localhost:8500/"
}

# Run all tests
echo -e "${BLUE}Starting comprehensive failover testing...${NC}\n"

# Test individual service failovers
test_failover_scenario "User Service" "user-service-dc1" "http://localhost:8082/" "http://localhost:8082/"
test_failover_scenario "Payment Service" "payment-service-dc2" "http://localhost:8085/" "http://localhost:8085/"
test_failover_scenario "Order Service" "order-service-dc1" "http://localhost:8084/" "http://localhost:8084/"

# Test cross-datacenter failovers
test_cross_dc_failover

# Test resilient routing
test_resilient_routing

# Test service discovery failover
test_service_discovery_failover

# Final report
echo -e "\n${BLUE}📊 Failover Testing Summary${NC}"
echo "=========================="
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All failover tests passed! Your system is resilient!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  Some tests failed. Check your configuration.${NC}"
    exit 1
fi
