# Setup Guide for Microservices VXLAN Project

## Introduction
This setup guide provides step-by-step instructions for installing and configuring the Microservices VXLAN Project. Follow the instructions carefully to ensure a successful setup.

## Prerequisites
Before you begin, ensure you have the following installed on your machine:
- Docker
- Docker Compose
- Git
- A Unix-based operating system (Linux or macOS is recommended)

## Clone the Repository
Start by cloning the project repository to your local machine:

```bash
git clone https://github.com/yourusername/microservices-vxlan-project.git
cd microservices-vxlan-project
```

## Build Docker Images
Navigate to the `dockerfiles` directory and build the Docker images for the microservices:

```bash
cd dockerfiles
docker build -t gateway-nginx -f Dockerfile.gateway-nginx .
docker build -t user-nginx -f Dockerfile.user-nginx .
docker build -t catalog-nginx -f Dockerfile.catalog-nginx .
docker build -t order-nginx -f Dockerfile.order-nginx .
docker build -t payment-nginx -f Dockerfile.payment-nginx .
docker build -t notify-nginx -f Dockerfile.notify-nginx .
docker build -t analytics-nginx -f Dockerfile.analytics-nginx .
docker build -t discovery-nginx -f Dockerfile.discovery-nginx .
```

## Configure Network Settings
Before deploying the services, configure the network settings using the provided scripts. Run the following commands:

```bash
cd configs/network
bash vxlan-config.sh
bash routing-tables.conf
bash firewall-rules.sh
```

## Deploy Services
To deploy the microservices, run the deployment script located in the `scripts/deployment` directory:

```bash
cd ../../scripts/deployment
bash deploy-services.sh
```

## Accessing the Services
Once the services are up and running, you can access them through the gateway NGINX. The default port is `80`. Open your web browser and navigate to:

```
http://localhost
```

## Conclusion
You have successfully set up the Microservices VXLAN Project. For further information on usage and troubleshooting, refer to the other documentation files in the `docs` directory.