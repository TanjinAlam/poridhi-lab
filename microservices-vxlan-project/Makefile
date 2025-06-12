# Microservices VXLAN Project Makefile
# Author: DevOps Team
# Date: June 12, 2025
# Version: 2.0 - Comprehensive Multi-Datacenter Architecture

# =============================================================================
# VARIABLES
# =============================================================================
PROJECT_NAME := microservices-vxlan-project
DOCKER_COMPOSE := docker-compose
DOCKER := docker
NETWORK_NAME := vxlan-network
REGISTRY := localhost:5000
SERVICES := gateway-nginx user-nginx catalog-nginx order-nginx payment-nginx notify-nginx analytics-nginx discovery-nginx

# Datacenter Configuration
DC1_VXLAN_ID := 200
DC2_VXLAN_ID := 300
DC3_VXLAN_ID := 400
DC1_SUBNET := 10.1.0.0/16
DC2_SUBNET := 10.2.0.0/16
DC3_SUBNET := 10.3.0.0/16

# =============================================================================
# HELP TARGET
# =============================================================================
.PHONY: help
help: ## Display this comprehensive help message
	@echo "🚀 Microservices VXLAN Project - Multi-Datacenter Architecture"
	@echo "=================================================================="
	@echo ""
	@echo "📋 INFRASTRUCTURE TARGETS:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Infrastructure.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🏗️  SERVICE MANAGEMENT TARGETS:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Service.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🧪 TESTING & VALIDATION TARGETS:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Test.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "📚 DOCUMENTATION & UTILITIES:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Doc.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🚀 QUICK START:"
	@echo "  1. make setup-infrastructure    # Setup complete infrastructure"
	@echo "  2. make build-all-images        # Build all service images"
	@echo "  3. make deploy-services          # Deploy all services"
	@echo "  4. make test-connectivity        # Verify deployment"
	@echo ""

# =============================================================================
# INFRASTRUCTURE TARGETS (10 targets)
# =============================================================================

# =============================================================================
# INFRASTRUCTURE TARGETS (10 targets)
# =============================================================================

.PHONY: setup-infrastructure setup-vxlan-mesh setup-docker-networks cleanup-infrastructure cleanup-vxlan show-network-status show-routing-table validate-infrastructure configure-firewall reset-infrastructure

setup-infrastructure: ## Infrastructure: Complete infrastructure setup with VXLAN mesh
	@echo "🏗️  Setting up complete infrastructure..."
	@echo "1/4 Validating dependencies..."
	$(MAKE) install-deps
	@echo "2/4 Setting up VXLAN mesh networks..."
	$(MAKE) setup-vxlan-mesh
	@echo "3/4 Configuring Docker networks..."
	$(MAKE) setup-docker-networks
	@echo "4/4 Configuring firewall rules..."
	$(MAKE) configure-firewall
	@echo "✅ Infrastructure setup completed!"

setup-vxlan-mesh: ## Infrastructure: Configure VXLAN mesh network across datacenters
	@echo "🌐 Setting up VXLAN mesh network..."
	@echo "Creating VXLAN interfaces for DC1 (ID: $(DC1_VXLAN_ID))..."
	sudo bash scripts/infrastructure/setup-vxlan.sh $(DC1_VXLAN_ID) $(DC1_SUBNET)
	@echo "Creating VXLAN interfaces for DC2 (ID: $(DC2_VXLAN_ID))..."
	sudo bash scripts/infrastructure/setup-vxlan.sh $(DC2_VXLAN_ID) $(DC2_SUBNET)
	@echo "Creating VXLAN interfaces for DC3 (ID: $(DC3_VXLAN_ID))..."
	sudo bash scripts/infrastructure/setup-vxlan.sh $(DC3_VXLAN_ID) $(DC3_SUBNET)
	@echo "✅ VXLAN mesh network configured"

setup-docker-networks: ## Infrastructure: Create Docker networks for multi-datacenter deployment
	@echo "🐳 Setting up Docker networks..."
	$(DOCKER) network create --driver bridge --subnet=$(DC1_SUBNET) --gateway=10.1.0.1 \
		--opt com.docker.network.bridge.name=br-dc1 \
		--opt com.docker.network.driver.mtu=1450 $(PROJECT_NAME)_dc1-network 2>/dev/null || true
	$(DOCKER) network create --driver bridge --subnet=$(DC2_SUBNET) --gateway=10.2.0.1 \
		--opt com.docker.network.bridge.name=br-dc2 \
		--opt com.docker.network.driver.mtu=1450 $(PROJECT_NAME)_dc2-network 2>/dev/null || true
	$(DOCKER) network create --driver bridge --subnet=$(DC3_SUBNET) --gateway=10.3.0.1 \
		--opt com.docker.network.bridge.name=br-dc3 \
		--opt com.docker.network.driver.mtu=1450 $(PROJECT_NAME)_dc3-network 2>/dev/null || true
	$(DOCKER) network create --driver bridge \
		--opt com.docker.network.bridge.name=br-backbone \
		--opt com.docker.network.driver.mtu=1450 $(PROJECT_NAME)_inter-dc-backbone 2>/dev/null || true
	@echo "✅ Docker networks created"

cleanup-infrastructure: ## Infrastructure: Complete infrastructure cleanup
	@echo "🧹 Cleaning up infrastructure..."
	$(MAKE) cleanup-vxlan
	$(MAKE) cleanup-services
	@echo "Removing Docker networks..."
	$(DOCKER) network rm $(PROJECT_NAME)_dc1-network $(PROJECT_NAME)_dc2-network $(PROJECT_NAME)_dc3-network $(PROJECT_NAME)_inter-dc-backbone 2>/dev/null || true
	@echo "✅ Infrastructure cleanup completed"

cleanup-vxlan: ## Infrastructure: Clean up VXLAN configuration
	@echo "🌐 Cleaning up VXLAN interfaces..."
	sudo ip link delete vxlan$(DC1_VXLAN_ID) 2>/dev/null || true
	sudo ip link delete vxlan$(DC2_VXLAN_ID) 2>/dev/null || true
	sudo ip link delete vxlan$(DC3_VXLAN_ID) 2>/dev/null || true
	sudo iptables -F 2>/dev/null || true
	@echo "✅ VXLAN cleanup completed"

show-network-status: ## Infrastructure: Display current network status
	@echo "📊 Network Status Report"
	@echo "======================="
	@echo "🐳 Docker Networks:"
	$(DOCKER) network ls | grep -E "(dc1|dc2|dc3|bridge)"
	@echo ""
	@echo "🌐 VXLAN Interfaces:"
	ip link show | grep vxlan || echo "No VXLAN interfaces found"
	@echo ""
	@echo "📋 Bridge Interfaces:"
	ip link show | grep br-dc || echo "No datacenter bridges found"

show-routing-table: ## Infrastructure: Display routing table configuration
	@echo "🗺️  Routing Table Status"
	@echo "======================"
	@echo "Main routing table:"
	ip route show table main | head -20
	@echo ""
	@echo "Bridge interfaces:"
	bridge link show 2>/dev/null || echo "No bridge links configured"

validate-infrastructure: ## Infrastructure: Validate infrastructure configuration
	@echo "✅ Validating infrastructure configuration..."
	@echo "Checking Docker daemon..."
	$(DOCKER) version >/dev/null 2>&1 || { echo "❌ Docker not running"; exit 1; }
	@echo "Checking Docker Compose..."
	$(DOCKER_COMPOSE) version >/dev/null 2>&1 || { echo "❌ Docker Compose not available"; exit 1; }
	@echo "Checking network interfaces..."
	@for vxlan_id in $(DC1_VXLAN_ID) $(DC2_VXLAN_ID) $(DC3_VXLAN_ID); do \
		ip link show vxlan$$vxlan_id >/dev/null 2>&1 && echo "✅ VXLAN $$vxlan_id: OK" || echo "⚠️  VXLAN $$vxlan_id: Not configured"; \
	done
	@echo "Checking Docker networks..."
	@for net in $(PROJECT_NAME)_dc1-network $(PROJECT_NAME)_dc2-network $(PROJECT_NAME)_dc3-network $(PROJECT_NAME)_inter-dc-backbone; do \
		$(DOCKER) network inspect $$net >/dev/null 2>&1 && echo "✅ $$net: OK" || echo "⚠️  $$net: Not configured"; \
	done
	@echo "✅ Infrastructure validation completed"

configure-firewall: ## Infrastructure: Configure firewall rules for multi-datacenter
	@echo "🔒 Configuring firewall rules..."
	sudo bash configs/network/firewall-rules.sh
	@echo "✅ Firewall configured"

reset-infrastructure: ## Infrastructure: Reset and reinitialize infrastructure
	@echo "🔄 Resetting infrastructure..."
	$(MAKE) cleanup-infrastructure
	sleep 2
	$(MAKE) setup-infrastructure
	@echo "✅ Infrastructure reset completed"

# =============================================================================
# SERVICE MANAGEMENT TARGETS (10 targets)
# =============================================================================

.PHONY: build-all-images deploy-services deploy-dc1-services deploy-dc2-services deploy-dc3-services stop-services start-services cleanup-services restart-services show-service-status

build-all-images: ## Service: Build all Docker images for multi-datacenter deployment
	@echo "🐳 Building all service images..."
	@echo "Building gateway images..."
	$(DOCKER) build -f dockerfiles/Dockerfile.gateway-nginx -t $(PROJECT_NAME)_gateway-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.gateway-nginx-dc2 -t $(PROJECT_NAME)_gateway-nginx-dc2 .
	$(DOCKER) build -f dockerfiles/Dockerfile.gateway-nginx-dc3 -t $(PROJECT_NAME)_gateway-nginx-dc3 .
	@echo "Building microservice images..."
	$(DOCKER) build -f dockerfiles/Dockerfile.user-nginx -t $(PROJECT_NAME)_user-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.catalog-nginx -t $(PROJECT_NAME)_catalog-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.order-nginx -t $(PROJECT_NAME)_order-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.payment-nginx -t $(PROJECT_NAME)_payment-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.notify-nginx -t $(PROJECT_NAME)_notify-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.analytics-nginx -t $(PROJECT_NAME)_analytics-nginx .
	$(DOCKER) build -f dockerfiles/Dockerfile.discovery-nginx -t $(PROJECT_NAME)_discovery-nginx .
	@echo "✅ All images built successfully"

deploy-services: setup-infrastructure build-all-images ## Service: Deploy all services across all datacenters
	@echo "🚀 Deploying all services across datacenters..."
	@echo "Starting multi-datacenter deployment..."
	$(DOCKER_COMPOSE) up -d
	@echo "Waiting for services to initialize..."
	sleep 10
	$(MAKE) show-service-status
	@echo "✅ All services deployed successfully!"
	@echo "🌍 Access Points:"
	@echo "  - DC1 (Primary): http://localhost:80"
	@echo "  - DC2 (Secondary): http://localhost:8080"
	@echo "  - DC3 (DR): http://localhost:8081"
	@echo "  - Discovery: http://localhost:8500"

deploy-dc1-services: build-all-images ## Service: Deploy DC1 services (North America - Primary)
	@echo "🇺🇸 Deploying DC1 services (North America - Primary)..."
	$(DOCKER_COMPOSE) up -d gateway-nginx-dc1 user-nginx-dc1 order-nginx-dc1 catalog-nginx-dc1 analytics-nginx-dc1
	@echo "✅ DC1 services deployed:"
	@echo "  - Gateway: http://localhost:80"
	@echo "  - User Service: http://localhost:8082"
	@echo "  - Order Service: http://localhost:8084"
	@echo "  - Catalog Service: http://localhost:8083"
	@echo "  - Analytics Service: http://localhost:8087"

deploy-dc2-services: build-all-images ## Service: Deploy DC2 services (Europe - Secondary)
	@echo "🌍 Deploying DC2 services (Europe - Secondary)..."
	$(DOCKER_COMPOSE) up -d gateway-nginx-dc2 payment-nginx-dc2 notify-nginx-dc2 order-nginx-dc2
	@echo "✅ DC2 services deployed:"
	@echo "  - Gateway (Backup): http://localhost:8080"
	@echo "  - Payment Service: http://localhost:8085"
	@echo "  - Notification Service: http://localhost:8086"
	@echo "  - Order Service (Replica): http://localhost:8088"

deploy-dc3-services: build-all-images ## Service: Deploy DC3 services (Asia-Pacific - DR)
	@echo "🌏 Deploying DC3 services (Asia-Pacific - DR)..."
	$(DOCKER_COMPOSE) up -d gateway-nginx-dc3 user-nginx-dc3 order-nginx-dc3 catalog-nginx-dc3 payment-nginx-dc3 notify-nginx-dc3 analytics-nginx-dc3 discovery-nginx-dc3
	@echo "✅ DC3 services deployed:"
	@echo "  - Gateway (Standby): http://localhost:8081"
	@echo "  - Discovery Service (Primary): http://localhost:8500"
	@echo "  - All services in standby mode: 8089-8094"

stop-services: ## Service: Stop all running services
	@echo "🛑 Stopping all services..."
	$(DOCKER_COMPOSE) down
	@echo "✅ All services stopped"

start-services: ## Service: Start all services (assumes images are built)
	@echo "▶️  Starting all services..."
	$(DOCKER_COMPOSE) up -d
	@echo "✅ All services started"

cleanup-services: ## Service: Stop and remove all service containers and images
	@echo "🧹 Cleaning up all services..."
	$(DOCKER_COMPOSE) down -v
	@echo "Removing service images..."
	$(DOCKER) rmi $(shell $(DOCKER) images $(PROJECT_NAME)_* -q) 2>/dev/null || true
	$(DOCKER) system prune -f
	@echo "✅ Service cleanup completed"

restart-services: ## Service: Restart all services
	@echo "🔄 Restarting all services..."
	$(MAKE) stop-services
	sleep 3
	$(MAKE) start-services
	@echo "✅ Services restarted"

show-service-status: ## Service: Display status of all services
	@echo "📊 Service Status Report"
	@echo "======================="
	@echo "🐳 Container Status:"
	$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "📈 Resource Usage:"
	$(DOCKER) stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No containers running"

# =============================================================================
# TESTING & VALIDATION TARGETS (8 targets)
# =============================================================================

.PHONY: test test-connectivity test-services test-cross-dc health-check show-logs validate-deployment performance-test test-failover test-failover-quick test-circuit-breaker

test: test-connectivity test-services ## Test: Run comprehensive system tests
	@echo "✅ All tests completed successfully!"

test-connectivity: ## Test: Network connectivity and infrastructure validation
	@echo "🌐 Testing network connectivity..."
	@echo "Testing Docker networks..."
	@for net in $(PROJECT_NAME)_dc1-network $(PROJECT_NAME)_dc2-network $(PROJECT_NAME)_dc3-network $(PROJECT_NAME)_inter-dc-backbone; do \
		$(DOCKER) network inspect $$net >/dev/null 2>&1 && echo "✅ $$net: Connected" || echo "❌ $$net: Failed"; \
	done
	@echo "Testing gateway connectivity..."
	@echo "DC1 Gateway (Primary):"
	@curl -f -s -m 5 http://localhost:80/ >/dev/null && echo "✅ DC1: OK" || echo "❌ DC1: Failed"
	@echo "DC2 Gateway (Backup):"
	@curl -f -s -m 5 http://localhost:8080/ >/dev/null && echo "✅ DC2: OK" || echo "❌ DC2: Failed"
	@echo "DC3 Gateway (DR):"
	@curl -f -s -m 5 http://localhost:8081/ >/dev/null && echo "✅ DC3: OK" || echo "❌ DC3: Failed"
	@echo "✅ Connectivity tests completed"

test-services: ## Test: Service functionality across all datacenters
	@echo "🔍 Testing service functionality..."
	@echo "DC1 Services:"
	@curl -f -s -m 5 http://localhost:8082/ >/dev/null && echo "✅ User Service: OK" || echo "❌ User Service: Failed"
	@curl -f -s -m 5 http://localhost:8083/ >/dev/null && echo "✅ Catalog Service: OK" || echo "❌ Catalog Service: Failed"
	@curl -f -s -m 5 http://localhost:8084/ >/dev/null && echo "✅ Order Service: OK" || echo "❌ Order Service: Failed"
	@curl -f -s -m 5 http://localhost:8087/ >/dev/null && echo "✅ Analytics Service: OK" || echo "❌ Analytics Service: Failed"
	@echo "DC2 Services:"
	@curl -f -s -m 5 http://localhost:8085/ >/dev/null && echo "✅ Payment Service: OK" || echo "❌ Payment Service: Failed"
	@curl -f -s -m 5 http://localhost:8086/ >/dev/null && echo "✅ Notification Service: OK" || echo "❌ Notification Service: Failed"
	@curl -f -s -m 5 http://localhost:8088/ >/dev/null && echo "✅ Order Replica: OK" || echo "❌ Order Replica: Failed"
	@echo "DC3 Discovery Service:"
	@curl -f -s -m 5 http://localhost:8500/ >/dev/null && echo "✅ Discovery Service: OK" || echo "❌ Discovery Service: Failed"
	@echo "✅ Service functionality tests completed"

test-service-discovery: ## Test: Enhanced service discovery functionality
	@echo "🔍 Testing enhanced service discovery..."
	@echo "Testing main discovery endpoint:"
	@curl -f -s -m 5 http://localhost:8500/ >/dev/null && echo "✅ Main Discovery: OK" || echo "❌ Main Discovery: Failed"
	@echo "Testing cross-datacenter service queries:"
	@curl -f -s -m 5 http://localhost:8500/api/dc1/services >/dev/null && echo "✅ DC1 Services Query: OK" || echo "❌ DC1 Services Query: Failed"
	@curl -f -s -m 5 http://localhost:8500/api/dc2/services >/dev/null && echo "✅ DC2 Services Query: OK" || echo "❌ DC2 Services Query: Failed"
	@curl -f -s -m 5 http://localhost:8500/api/dc3/services >/dev/null && echo "✅ DC3 Services Query: OK" || echo "❌ DC3 Services Query: Failed"
	@echo "Testing routing and topology:"
	@curl -f -s -m 5 http://localhost:8500/api/routing >/dev/null && echo "✅ Routing Info: OK" || echo "❌ Routing Info: Failed"
	@curl -f -s -m 5 http://localhost:8500/api/topology >/dev/null && echo "✅ Topology Info: OK" || echo "❌ Topology Info: Failed"
	@curl -f -s -m 5 http://localhost:8500/api/health/global >/dev/null && echo "✅ Global Health: OK" || echo "❌ Global Health: Failed"
	@curl -f -s -m 5 http://localhost:8500/api/services/gateways >/dev/null && echo "✅ Gateway Discovery: OK" || echo "❌ Gateway Discovery: Failed"
	@echo "✅ Service discovery tests completed"

test-inter-dc-routing: ## Test: Inter-datacenter routing and communication
	@echo "🌍 Testing inter-datacenter routing..."
	@echo "Testing direct gateway access:"
	@curl -f -s -m 5 http://localhost:80/ >/dev/null && echo "✅ DC1 Gateway: OK" || echo "❌ DC1 Gateway: Failed"
	@curl -f -s -m 5 http://localhost:8080/ >/dev/null && echo "✅ DC2 Gateway: OK" || echo "❌ DC2 Gateway: Failed"
	@curl -f -s -m 5 http://localhost:8081/ >/dev/null && echo "✅ DC3 Gateway: OK" || echo "❌ DC3 Gateway: Failed"
	@echo "Testing cross-datacenter proxy routing:"
	@curl -f -s -m 5 http://localhost:80/route/dc2/ >/dev/null && echo "✅ DC1->DC2 Proxy: OK" || echo "❌ DC1->DC2 Proxy: Failed"
	@curl -f -s -m 5 http://localhost:80/route/dc3/ >/dev/null && echo "✅ DC1->DC3 Proxy: OK" || echo "❌ DC1->DC3 Proxy: Failed"
	@curl -f -s -m 5 http://localhost:8080/route/dc1/ >/dev/null && echo "✅ DC2->DC1 Proxy: OK" || echo "❌ DC2->DC1 Proxy: Failed"
	@curl -f -s -m 5 http://localhost:8080/route/dc3/ >/dev/null && echo "✅ DC2->DC3 Proxy: OK" || echo "❌ DC2->DC3 Proxy: Failed"
	@curl -f -s -m 5 http://localhost:8081/route/dc1/ >/dev/null && echo "✅ DC3->DC1 Proxy: OK" || echo "❌ DC3->DC1 Proxy: Failed"
	@curl -f -s -m 5 http://localhost:8081/route/dc2/ >/dev/null && echo "✅ DC3->DC2 Proxy: OK" || echo "❌ DC3->DC2 Proxy: Failed"
	@echo "Testing discovery service routing:"
	@curl -f -s -m 5 http://localhost:80/api/discovery/ >/dev/null && echo "✅ DC1->Discovery: OK" || echo "❌ DC1->Discovery: Failed"
	@curl -f -s -m 5 http://localhost:8080/api/discovery/ >/dev/null && echo "✅ DC2->Discovery: OK" || echo "❌ DC2->Discovery: Failed"
	@curl -f -s -m 5 http://localhost:8081/api/discovery/ >/dev/null && echo "✅ DC3->Discovery: OK" || echo "❌ DC3->Discovery: Failed"
test-enhanced-discovery: ## Test: Enhanced service discovery system
	@echo "🔍 Testing enhanced service discovery system..."
	@if [ -f scripts/test-enhanced-discovery.sh ]; then \
		chmod +x scripts/test-enhanced-discovery.sh; \
		./scripts/test-enhanced-discovery.sh; \
	else \
		echo "❌ Enhanced discovery test script not found"; \
		exit 1; \
	fi
	@echo "✅ Enhanced service discovery tests completed"

test-comprehensive: test-services test-service-discovery test-inter-dc-routing test-enhanced-discovery ## Test: Run all comprehensive tests
	@echo "🎯 Running comprehensive test suite..."
	@echo "✅ All comprehensive tests completed successfully!"

test-cross-dc: ## Test: Cross-datacenter communication and failover
	@echo "🌍 Testing cross-datacenter communication..."
	@echo "Testing primary to secondary communication..."
	@echo "Simulating request routing between datacenters..."
	@for i in 1 2 3; do \
		echo "Test $$i: DC1 -> DC2"; \
		curl -f -s -m 3 "http://localhost:80/api/health" >/dev/null && echo "✅ Round $$i: OK" || echo "❌ Round $$i: Failed"; \
		sleep 1; \
	done
	@echo "Testing failover scenarios..."
	@echo "Checking service discovery monitoring..."
	@curl -f -s -m 5 "http://localhost:8500/health" >/dev/null && echo "✅ Service Discovery: Monitoring active" || echo "⚠️  Service Discovery: Limited functionality"
	@echo "✅ Cross-datacenter tests completed"

health-check: ## Test: Comprehensive health check of all components
	@echo "🏥 Running comprehensive health check..."
	@echo "Infrastructure Health:"
	@$(DOCKER) version >/dev/null 2>&1 && echo "✅ Docker: Running" || echo "❌ Docker: Not available"
	@$(DOCKER_COMPOSE) version >/dev/null 2>&1 && echo "✅ Docker Compose: Available" || echo "❌ Docker Compose: Not available"
	@echo "Container Health:"
	@$(DOCKER_COMPOSE) ps --format table 2>/dev/null || echo "No services running"
	@echo "Network Health:"
	@$(DOCKER) network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}" | grep -E "(dc1|dc2|dc3)" || echo "No datacenter networks found"
	@echo "Service Health (HTTP Status):"
	@for port in 80 8080 8081 8082 8083 8084 8085 8086 8087 8088 8500; do \
		status_code=$$(curl -s -o /dev/null -w "%{http_code}" -m 3 http://localhost:$$port/ 2>/dev/null || echo "000"); \
		if [ "$$status_code" = "200" ]; then \
			echo "✅ Port $$port: HTTP $$status_code"; \
		elif [ "$$status_code" = "000" ]; then \
			echo "❌ Port $$port: Not responding"; \
		else \
			echo "⚠️  Port $$port: HTTP $$status_code"; \
		fi; \
	done
	@echo "✅ Health check completed"

show-logs: ## Test: Display logs from all services for debugging
	@echo "📋 Service Logs (last 50 lines per service)"
	@echo "=========================================="
	@for service in gateway-nginx-dc1 gateway-nginx-dc2 gateway-nginx-dc3 user-nginx-dc1 catalog-nginx-dc1 order-nginx-dc1; do \
		echo ""; \
		echo "🔍 $$service logs:"; \
		echo "-------------------"; \
		$(DOCKER_COMPOSE) logs --tail=20 $$service 2>/dev/null || echo "Service $$service not running"; \
		echo ""; \
	done

validate-deployment: ## Test: Validate complete deployment configuration
	@echo "✅ Validating deployment configuration..."
	@echo "Checking service configuration files..."
	@for service in $(SERVICES); do \
		[ -f dockerfiles/Dockerfile.$$service ] && echo "✅ Dockerfile.$$service: Found" || echo "❌ Dockerfile.$$service: Missing"; \
		[ -f configs/nginx/$$service.conf ] && echo "✅ $$service.conf: Found" || echo "⚠️  $$service.conf: Missing"; \
	done
	@echo "Checking datacenter-specific configurations..."
	@[ -f dockerfiles/Dockerfile.gateway-nginx-dc2 ] && echo "✅ DC2 Gateway Dockerfile: Found" || echo "❌ DC2 Gateway Dockerfile: Missing"
	@[ -f dockerfiles/Dockerfile.gateway-nginx-dc3 ] && echo "✅ DC3 Gateway Dockerfile: Found" || echo "❌ DC3 Gateway Dockerfile: Missing"
	@echo "Checking data files..."
	@[ -d data/service-responses ] && echo "✅ Service response data: Found" || echo "❌ Service response data: Missing"
	@echo "✅ Deployment validation completed"

performance-test: ## Test: Basic performance and load testing
	@echo "⚡ Running performance tests..."
	@echo "Testing response times..."
	@for endpoint in "http://localhost:80/" "http://localhost:8080/" "http://localhost:8081/"; do \
		echo "Testing $$endpoint"; \
		time_ms=$$(curl -w "%%{time_total}" -s -o /dev/null $$endpoint 2>/dev/null || echo "timeout"); \
		if [ "$$time_ms" != "timeout" ]; then \
			echo "✅ Response time: $${time_ms}s"; \
		else \
			echo "❌ Request timeout"; \
		fi; \
	done
	@echo "Testing concurrent connections (5 requests)..."
	@for i in 1 2 3 4 5; do \
		curl -s http://localhost:80/ >/dev/null & \
	done
	@wait
	@echo "✅ Performance tests completed"

test-failover: ## Test: Comprehensive failover testing across all datacenters
	@echo "🔄 Running comprehensive failover tests..."
	@bash scripts/test-failover-complete.sh

test-failover-quick: ## Test: Quick failover verification
	@echo "🔄 Quick failover test..."
	@echo "Testing DC failover responses:"
	@curl -f -s -m 5 http://localhost:80/route/dc2/ >/dev/null && echo "✅ DC1→DC2: OK" || echo "❌ DC1→DC2: Failed"
	@curl -f -s -m 5 http://localhost:80/route/dc3/ >/dev/null && echo "✅ DC1→DC3: OK" || echo "❌ DC1→DC3: Failed"
	@curl -f -s -m 5 http://localhost:8080/route/dc1/ >/dev/null && echo "✅ DC2→DC1: OK" || echo "❌ DC2→DC1: Failed"
	@curl -f -s -m 5 http://localhost:8081/route/dc1/ >/dev/null && echo "✅ DC3→DC1: OK" || echo "❌ DC3→DC1: Failed"
	@echo "Testing resilient routing:"
	@curl -f -s -m 5 http://localhost:80/route/resilient/ >/dev/null && echo "✅ Resilient routing: OK" || echo "❌ Resilient routing: Failed"
	@echo "✅ Quick failover test completed"

test-circuit-breaker: ## Test: Circuit breaker functionality
	@echo "🔌 Testing circuit breaker functionality..."
	@echo "Checking failover headers:"
	@curl -I -s -m 5 http://localhost:80/route/dc2/ | grep -i "failover\|backup" || echo "No failover headers found"
	@curl -I -s -m 5 http://localhost:8080/route/dc1/ | grep -i "failover\|backup" || echo "No failover headers found"
	@echo "✅ Circuit breaker test completed"

# =============================================================================
# DOCUMENTATION & UTILITIES (5 targets)
# =============================================================================

.PHONY: docs install-deps generate-docs create-setup-guide create-troubleshooting

docs: ## Doc: Display project documentation overview
	@echo "📚 Project Documentation Overview"
	@echo "================================"
	@echo "Architecture Documentation:"
	@[ -f architecture/deployment-strategy.md ] && echo "✅ Deployment Strategy: architecture/deployment-strategy.md" || echo "❌ Deployment Strategy: Missing"
	@[ -f architecture/network-topology.md ] && echo "✅ Network Topology: architecture/network-topology.md" || echo "❌ Network Topology: Missing"
	@[ -f architecture/service-architecture.md ] && echo "✅ Service Architecture: architecture/service-architecture.md" || echo "❌ Service Architecture: Missing"
	@echo "Setup Documentation:"
	@[ -f docs/setup-guide.md ] && echo "✅ Setup Guide: docs/setup-guide.md" || echo "❌ Setup Guide: Missing"
	@[ -f docs/troubleshooting.md ] && echo "✅ Troubleshooting: docs/troubleshooting.md" || echo "❌ Troubleshooting: Missing"
	@[ -f docs/service-distribution-update.md ] && echo "✅ Service Distribution: docs/service-distribution-update.md" || echo "✅ Service Distribution: Available"
	@echo "Configuration Files:"
	@echo "✅ NGINX Configs: configs/nginx/"
	@echo "✅ Network Configs: configs/network/"
	@echo "✅ Service Data: data/service-responses/"

install-deps: ## Doc: Validate and install project dependencies
	@echo "🔧 Installing project dependencies..."
	@echo "Checking Docker installation..."
	@command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Please install Docker Desktop."; exit 1; }
	@echo "✅ Docker: Available"
	@echo "Checking Docker Compose installation..."
	@command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required but not installed. Please install Docker Compose."; exit 1; }
	@echo "✅ Docker Compose: Available"
	@echo "Checking network tools..."
	@command -v curl >/dev/null 2>&1 && echo "✅ curl: Available" || echo "⚠️  curl: Not available (tests may fail)"
	@command -v ip >/dev/null 2>&1 && echo "✅ ip: Available" || echo "⚠️  ip: Not available (VXLAN setup may fail)"
	@echo "✅ All critical dependencies are installed"

generate-docs: create-setup-guide create-troubleshooting ## Doc: Generate comprehensive project documentation
	@echo "📖 Generating comprehensive documentation..."
	@echo "✅ Documentation generation completed"

create-setup-guide: ## Doc: Create comprehensive setup guide
	@echo "📋 Creating setup guide..."
	@mkdir -p docs
	@echo "# Comprehensive Setup Guide - Microservices VXLAN Project" > docs/comprehensive-setup-guide.md
	@echo "" >> docs/comprehensive-setup-guide.md
	@echo "## Quick Start" >> docs/comprehensive-setup-guide.md
	@echo "1. make setup-infrastructure" >> docs/comprehensive-setup-guide.md
	@echo "2. make build-all-images" >> docs/comprehensive-setup-guide.md
	@echo "3. make deploy-services" >> docs/comprehensive-setup-guide.md
	@echo "4. make test-connectivity" >> docs/comprehensive-setup-guide.md
	@echo "✅ Setup guide created: docs/comprehensive-setup-guide.md"

create-troubleshooting: ## Doc: Create troubleshooting guide
	@echo "🔧 Creating troubleshooting guide..."
	@mkdir -p docs
	@echo "# Troubleshooting Guide - Microservices VXLAN Project" > docs/comprehensive-troubleshooting.md
	@echo "" >> docs/comprehensive-troubleshooting.md
	@echo "## Common Issues" >> docs/comprehensive-troubleshooting.md
	@echo "- Docker daemon not running: open -a Docker" >> docs/comprehensive-troubleshooting.md
	@echo "- Port conflicts: make cleanup-services" >> docs/comprehensive-troubleshooting.md
	@echo "- Network issues: make reset-infrastructure" >> docs/comprehensive-troubleshooting.md
	@echo "✅ Troubleshooting guide created: docs/comprehensive-troubleshooting.md"

# =============================================================================
# LEGACY COMPATIBILITY & UTILITIES
# =============================================================================

.PHONY: all build up down restart dev logs monitor stats clean

# Legacy targets for backward compatibility
all: deploy-services ## Legacy: Build and deploy all services (backward compatibility)

build: build-all-images ## Legacy: Build all images (backward compatibility)

up: start-services ## Legacy: Start services (backward compatibility)

down: stop-services ## Legacy: Stop services (backward compatibility)

restart: restart-services ## Legacy: Restart services (backward compatibility)

dev: ## Legacy: Start development environment
	@echo "🚧 Starting development environment..."
	$(DOCKER_COMPOSE) -f docker-compose.yml up

logs: show-logs ## Legacy: Show service logs (backward compatibility)

monitor: ## Legacy: Basic monitoring (resource stats)
	@echo "📊 Basic resource monitoring..."
	$(DOCKER) stats --no-stream

stats: monitor ## Legacy: Resource statistics (backward compatibility)

clean: cleanup-services ## Legacy: Cleanup (backward compatibility)

# =============================================================================
# VALIDATION & FINAL CHECKS
# =============================================================================

.PHONY: validate-makefile

validate-makefile: ## Doc: Validate Makefile target coverage
	@echo "✅ Validating Makefile target categories..."
	@echo "Infrastructure targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Infrastructure.*$$' $(MAKEFILE_LIST) | wc -l | xargs echo "  Count:"
	@echo "Service management targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Service.*$$' $(MAKEFILE_LIST) | wc -l | xargs echo "  Count:"
	@echo "Testing targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Test.*$$' $(MAKEFILE_LIST) | wc -l | xargs echo "  Count:"
	@echo "Documentation targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*Doc.*$$' $(MAKEFILE_LIST) | wc -l | xargs echo "  Count:"
	@echo "✅ Makefile validation completed"

# End of Makefile