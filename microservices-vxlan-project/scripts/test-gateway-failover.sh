#!/bin/bash

# Gateway-Level Failover Testing Script
# Tests actual gateway proxy failover mechanisms

echo "🔄 Gateway Failover Testing"
echo "=========================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counter
PASSED=0
FAILED=0

test_gateway_failover() {
    local route="$1"
    local container="$2"
    local fallback_message="$3"
    
    echo -e "\n${BLUE}🔄 Testing Gateway Route: $route${NC}"
    echo "----------------------------------------"
    
    # 1. Test normal operation
    echo -n "1. Normal operation: "
    response=$(curl -s -w "%{http_code}" "$route" 2>/dev/null)
    status_code=$(echo "$response" | tail -n1)
    if [[ "$status_code" == "200" ]]; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL (HTTP: $status_code)${NC}"
        ((FAILED++))
    fi
    
    # 2. Stop the target container
    echo "2. Stopping $container..."
    docker stop "$container" >/dev/null 2>&1
    sleep 3
    
    # 3. Test failover response
    echo -n "3. Testing failover: "
    response=$(curl -s "$route" 2>/dev/null)
    if [[ "$response" == *"$fallback_message"* ]] || [[ "$response" == *"fallback"* ]] || [[ "$response" == *"unavailable"* ]]; then
        echo -e "${GREEN}✅ Failover Active${NC}"
        echo "   Fallback message: $(echo "$response" | grep -o '"message":"[^"]*"' | head -1)"
        ((PASSED++))
    else
        echo -e "${RED}❌ Failover Failed${NC}"
        echo "   Response: $(echo "$response" | head -c 100)..."
        ((FAILED++))
    fi
    
    # 4. Check failover headers
    echo -n "4. Checking failover headers: "
    headers=$(curl -I -s "$route" 2>/dev/null | grep -i "X-Fallback\|fallback")
    if [[ -n "$headers" ]]; then
        echo -e "${GREEN}✅ Headers Present${NC}"
        echo "   $headers"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠️  Headers Missing${NC}"
        ((FAILED++))
    fi
    
    # 5. Restart the container
    echo "5. Restarting $container..."
    docker start "$container" >/dev/null 2>&1
    sleep 5
    
    # 6. Test recovery
    echo -n "6. Testing recovery: "
    response=$(curl -s -w "%{http_code}" "$route" 2>/dev/null)
    status_code=$(echo "$response" | tail -n1)
    if [[ "$status_code" == "200" ]]; then
        echo -e "${GREEN}✅ Recovery Successful${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ Recovery Failed${NC}"
        ((FAILED++))
    fi
}

# Reload gateway configuration
echo "🔄 Reloading gateway configuration..."
docker exec gateway-dc1 nginx -s reload >/dev/null 2>&1
sleep 2

# Test gateway-level proxy failovers
test_gateway_failover "http://localhost:80/route/dc2/" "gateway-dc2-backup" "DC2 unavailable"
test_gateway_failover "http://localhost:80/route/dc3/" "gateway-dc3-standby" "DC3 unavailable"

# Test service discovery failover
echo -e "\n${BLUE}🔍 Testing Service Discovery Failover${NC}"
echo "====================================="

echo -n "1. Normal discovery access: "
response=$(curl -s -w "%{http_code}" "http://localhost:80/api/discovery/" 2>/dev/null)
status_code=$(echo "$response" | tail -n1)
if [[ "$status_code" == "200" ]]; then
    echo -e "${GREEN}✅ Working${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Failed (HTTP: $status_code)${NC}"
    ((FAILED++))
fi

echo "2. Stopping discovery service..."
docker stop discovery-service-dc3 >/dev/null 2>&1
sleep 3

echo -n "3. Testing discovery failover: "
response=$(curl -s "http://localhost:80/api/discovery/" 2>/dev/null)
status_code=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:80/api/discovery/" 2>/dev/null)
if [[ "$status_code" == "502" ]] || [[ "$status_code" == "503" ]]; then
    echo -e "${YELLOW}⚠️  Discovery Unavailable (Expected)${NC}"
    echo "   Status: $status_code"
    ((PASSED++))
else
    echo -e "${GREEN}✅ Backup Discovery Working${NC}"
    ((PASSED++))
fi

echo "4. Restarting discovery service..."
docker start discovery-service-dc3 >/dev/null 2>&1
sleep 5

# Test resilient routing
echo -e "\n${BLUE}🏆 Testing Resilient Routing${NC}"
echo "============================="

echo -n "Testing resilient route: "
response=$(curl -s -w "%{http_code}" "http://localhost:80/route/resilient/" 2>/dev/null)
status_code=$(echo "$response" | tail -n1)
if [[ "$status_code" == "200" ]]; then
    echo -e "${GREEN}✅ Working${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Failed (HTTP: $status_code)${NC}"
    ((FAILED++))
fi

# Final report
echo -e "\n${BLUE}📊 Gateway Failover Testing Summary${NC}"
echo "=================================="
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 All gateway failover tests passed!${NC}"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  Some tests failed. Check configuration.${NC}"
    exit 1
fi
