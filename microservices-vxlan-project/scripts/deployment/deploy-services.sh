#!/bin/bash

# This script automates the deployment of the microservices.

# Define the services to be deployed
services=(
    "gateway-nginx"
    "user-nginx"
    "catalog-nginx"
    "order-nginx"
    "payment-nginx"
    "notify-nginx"
    "analytics-nginx"
    "discovery-nginx"
)

# Function to build and deploy a service
deploy_service() {
    service_name=$1
    echo "Deploying $service_name..."
    
    # Build the Docker image
    docker build -t "$service_name" -f "../dockerfiles/Dockerfile.$service_name" .
    
    # Run the Docker container
    docker run -d --name "$service_name" "$service_name"
    
    echo "$service_name deployed successfully."
}

# Loop through each service and deploy
for service in "${services[@]}"; do
    deploy_service "$service"
done

echo "All services deployed successfully."