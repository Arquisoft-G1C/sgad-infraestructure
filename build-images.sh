#!/bin/bash

# ============================================
# SGAD - Build All Docker Images Script
# ============================================
# This script builds Docker images for all SGAD microservices
# Run this script from the parent directory containing all repos

set -e

echo "🏗️  Building SGAD Docker Images..."
echo "======================================"

# Get the parent directory (assumes all repos are in the same parent folder)
PARENT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "📂 Parent directory: $PARENT_DIR"
echo ""

# Define services with their paths and image names
# Format: "directory_name:image_name"
SERVICES=(
    "sgad-auth-service:sgad-auth-service:latest"
    "sgad-api-gateway:sgad-api-gateway:latest"
    "sgad-referee-management:sgad-referee-service:latest"
    "sgad-availability-service:sgad-availability-service:latest"
    "sgad-match-management:sgad-match-service:latest"
    "sgad-frontend:sgad-frontend:latest"
)

# Build each service
for SERVICE in "${SERVICES[@]}"; do
    SERVICE_DIR="${SERVICE%%:*}"
    IMAGE_NAME="${SERVICE#*:}"
    SERVICE_PATH="$PARENT_DIR/$SERVICE_DIR"
    
    if [ -d "$SERVICE_PATH" ]; then
        echo "🔨 Building $IMAGE_NAME from $SERVICE_DIR..."
        cd "$SERVICE_PATH"
        
        if [ -f "Dockerfile" ]; then
            docker build -t "$IMAGE_NAME" .
            echo "✅ Successfully built $IMAGE_NAME"
        else
            echo "⚠️  Warning: Dockerfile not found in $SERVICE_PATH"
        fi
        echo ""
    else
        echo "⚠️  Warning: Directory $SERVICE_PATH not found"
        echo ""
    fi
done

echo "======================================"
echo "✅ All images built successfully!"
echo ""
echo "📋 Built images:"
docker images | grep sgad-

echo ""
echo "▶️  You can now run: docker-compose up -d"

