#!/bin/bash

# Deploy UniFi Controller to Azure - Simple Script
# Uses ghcr.io/jacobalberty/unifi-docker:latest

set -e

# Default values
RESOURCE_GROUP="${RESOURCE_GROUP:-unifi-controller-rg}"
LOCATION="${LOCATION:-westeurope}"
CONTAINER_GROUP_NAME="${CONTAINER_GROUP_NAME:-unifi-controller}"

echo "🚀 Deploying UniFi Controller to Azure"
echo "======================================"
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Container Group: $CONTAINER_GROUP_NAME"
echo ""

# Check if logged in to Azure
echo "📌 Checking Azure login status..."
if ! az account show &>/dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

echo "✅ Logged in to Azure"
echo ""

# Create resource group
echo "📦 Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

# Deploy the template
echo ""
echo "🔧 Deploying UniFi Controller..."
DEPLOYMENT_OUTPUT=$(az deployment group create \
    --name "unifi-deploy-$(date +%Y%m%d%H%M%S)" \
    --resource-group "$RESOURCE_GROUP" \
    --template-file main.bicep \
    --parameters \
        location="$LOCATION" \
        containerGroupName="$CONTAINER_GROUP_NAME" \
    --query properties.outputs \
    -o json)

# Extract outputs
FQDN=$(echo "$DEPLOYMENT_OUTPUT" | jq -r .containerFQDN.value)
IP=$(echo "$DEPLOYMENT_OUTPUT" | jq -r .containerIPv4Address.value)
URL=$(echo "$DEPLOYMENT_OUTPUT" | jq -r .accessUrl.value)

echo ""
echo "✅ Deployment Complete!"
echo "======================"
echo ""
echo "📍 Access Information:"
echo "   URL: $URL"
echo "   FQDN: $FQDN"
echo "   IP: $IP"
echo ""
echo "📝 Next Steps:"
echo "   1. Wait 2-3 minutes for container to initialize"
echo "   2. Access UniFi Controller at: $URL"
echo "   3. Complete the setup wizard"
echo "   4. Configure automatic backups"
echo ""
echo "⚠️  Remember: Data is stored in EmptyDir volumes."
echo "   Regular backups are recommended!"
