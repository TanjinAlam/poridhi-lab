#!/bin/bash

# Fallback Status Dashboard
# Shows real-time status of all failover mechanisms

echo "🔄 Multi-Datacenter Failover Status Dashboard"
echo "============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

get_service_status() {
    local url="$1"
    local timeout=3
    
    response=$(curl -s -w "%{http_code}" -m $timeout "$url" 2>/dev/null)
    http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}🟢 HEALTHY${NC}"
    elif [[ "$http_code" == "503" ]]; then
        echo -e "${YELLOW}🟡 DEGRADED${NC}"
    else
        echo -e "${RED}🔴 DOWN${NC}"
    fi
}

get_failover_status() {
    local url="$1"
    
    headers=$(curl -I -s -m 3 "$url" 2>/dev/null | grep -i "failover\|backup\|fallback")
    if [[ -n "$headers" ]]; then
        echo -e "${GREEN}✅ ENABLED${NC}"
    else
        echo -e "${RED}❌ DISABLED${NC}"
    fi
}

echo -e "\n${BLUE}📊 Gateway Status:${NC}"
echo "==================="
printf "%-15s %-15s %-15s %-15s\n" "Gateway" "Status" "Failover" "Last Check"
printf "%-15s %-15s %-15s %-15s\n" "-------" "------" "--------" "----------"

# DC1 Gateway
printf "%-15s " "DC1 (Primary)"
get_service_status "http://localhost:80/"
printf "%-15s " ""
get_failover_status "http://localhost:80/route/dc2/"
printf "%-15s\n" "$(date '+%H:%M:%S')"

# DC2 Gateway  
printf "%-15s " "DC2 (Secondary)"
get_service_status "http://localhost:8080/"
printf "%-15s " ""
get_failover_status "http://localhost:8080/route/dc1/"
printf "%-15s\n" "$(date '+%H:%M:%S')"

# DC3 Gateway
printf "%-15s " "DC3 (DR)"
get_service_status "http://localhost:8081/"
printf "%-15s " ""
get_failover_status "http://localhost:8081/route/dc1/"
printf "%-15s\n" "$(date '+%H:%M:%S')"

echo -e "\n${BLUE}🔄 Cross-DC Routing Status:${NC}"
echo "==========================="
printf "%-20s %-15s %-20s\n" "Route" "Status" "Fallback Available"
printf "%-20s %-15s %-20s\n" "-----" "------" "------------------"

# Test all cross-DC routes
routes=(
    "DC1→DC2:http://localhost:80/route/dc2/"
    "DC1→DC3:http://localhost:80/route/dc3/"
    "DC2→DC1:http://localhost:8080/route/dc1/"
    "DC2→DC3:http://localhost:8080/route/dc3/"
    "DC3→DC1:http://localhost:8081/route/dc1/"
    "DC3→DC2:http://localhost:8081/route/dc2/"
)

for route in "${routes[@]}"; do
    name=$(echo "$route" | cut -d':' -f1)
    url=$(echo "$route" | cut -d':' -f2-)
    
    printf "%-20s " "$name"
    get_service_status "$url"
    printf "%-20s " ""
    
    # Check for fallback headers
    fallback=$(curl -I -s -m 3 "$url" 2>/dev/null | grep -i "backup-available")
    if [[ -n "$fallback" ]]; then
        echo -e "${GREEN}✅ YES${NC}"
    else
        echo -e "${RED}❌ NO${NC}"
    fi
done

echo -e "\n${BLUE}🔍 Service Discovery Status:${NC}"
echo "============================"
printf "%-20s %-15s %-20s\n" "Endpoint" "Status" "Response Time"
printf "%-20s %-15s %-20s\n" "--------" "------" "-------------"

# Discovery service endpoints
discovery_endpoints=(
    "Direct:http://localhost:8500/"
    "Via DC1:http://localhost:80/api/discovery/"
    "Via DC2:http://localhost:8080/api/discovery/"
    "Via DC3:http://localhost:8081/api/discovery/"
)

for endpoint in "${discovery_endpoints[@]}"; do
    name=$(echo "$endpoint" | cut -d':' -f1)
    url=$(echo "$endpoint" | cut -d':' -f2-)
    
    printf "%-20s " "$name"
    
    start_time=$(date +%s%N)
    response=$(curl -s -w "%{http_code}" -m 3 "$url" 2>/dev/null)
    end_time=$(date +%s%N)
    
    http_code=$(echo "$response" | tail -n1)
    response_time=$(( (end_time - start_time) / 1000000 ))
    
    if [[ "$http_code" == "200" ]]; then
        echo -e "${GREEN}🟢 HEALTHY${NC}        ${response_time}ms"
    else
        echo -e "${RED}🔴 DOWN${NC}           N/A"
    fi
done

echo -e "\n${BLUE}💡 Resilient Routing Status:${NC}"
echo "============================"

# Test resilient endpoints
resilient_endpoints=(
    "DC1 Resilient:http://localhost:80/route/resilient/"
    "DC2 Resilient:http://localhost:8080/route/resilient/"
    "DC3 Resilient:http://localhost:8081/route/resilient/"
)

for endpoint in "${resilient_endpoints[@]}"; do
    name=$(echo "$endpoint" | cut -d':' -f1)
    url=$(echo "$endpoint" | cut -d':' -f2-)
    
    printf "%-20s " "$name"
    get_service_status "$url"
    
    # Check load balance headers
    headers=$(curl -I -s -m 3 "$url" 2>/dev/null | grep -i "load-balance")
    if [[ -n "$headers" ]]; then
        echo -e "   ${GREEN}Load Balanced${NC}"
    else
        echo -e "   ${YELLOW}Direct Route${NC}"
    fi
done

echo -e "\n${BLUE}⚙️  System Health Summary:${NC}"
echo "========================="

# Count healthy services
total_services=0
healthy_services=0

services=(
    "http://localhost:80/"
    "http://localhost:8080/"
    "http://localhost:8081/"
    "http://localhost:8082/"
    "http://localhost:8083/"
    "http://localhost:8084/"
    "http://localhost:8085/"
    "http://localhost:8086/"
    "http://localhost:8087/"
    "http://localhost:8500/"
)

for service in "${services[@]}"; do
    ((total_services++))
    response=$(curl -s -w "%{http_code}" -m 2 "$service" 2>/dev/null | tail -n1)
    if [[ "$response" == "200" ]]; then
        ((healthy_services++))
    fi
done

echo "Total Services: $total_services"
echo "Healthy Services: $healthy_services"
echo "Failed Services: $((total_services - healthy_services))"

if [[ $healthy_services -eq $total_services ]]; then
    echo -e "Overall Status: ${GREEN}🟢 ALL SYSTEMS OPERATIONAL${NC}"
elif [[ $healthy_services -gt $((total_services / 2)) ]]; then
    echo -e "Overall Status: ${YELLOW}🟡 DEGRADED - FAILOVER ACTIVE${NC}"
else
    echo -e "Overall Status: ${RED}🔴 CRITICAL - MULTIPLE FAILURES${NC}"
fi

echo -e "\n${BLUE}📅 Last Updated: $(date)${NC}"
echo "Refresh this dashboard: bash scripts/failover-dashboard.sh"
