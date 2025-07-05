#!/bin/bash

# Diagnostic script for UniFi Container deployment

RESOURCE_GROUP="${1:-unifi-controller-rg}"
CONTAINER_GROUP="${2:-unifi-controller}"

echo "🔍 UniFi Container Diagnostics"
echo "=============================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Container Group: $CONTAINER_GROUP"
echo ""

# Check if container group exists
echo "📦 Checking container group status..."
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --query "{Status:instanceView.state, RestartCount:containers[0].instanceView.restartCount, CurrentState:containers[0].instanceView.currentState}" \
    -o table 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ Container group not found or error accessing it"
    exit 1
fi

echo ""
echo "📜 Container Logs (last 50 lines):"
echo "=================================="
az container logs \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --tail 50

echo ""
echo "🔧 Container Details:"
echo "===================="
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --query "{Image:containers[0].image, Memory:containers[0].resources.requests.memoryInGB, CPU:containers[0].resources.requests.cpu, State:containers[0].instanceView.currentState.state, ExitCode:containers[0].instanceView.currentState.exitCode, StartTime:containers[0].instanceView.currentState.startTime}" \
    -o table

echo ""
echo "🌐 Network Details:"
echo "=================="
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --query "{FQDN:ipAddress.fqdn, IP:ipAddress.ip, Type:ipAddress.type}" \
    -o table

echo ""
echo "💾 Volume Mounts:"
echo "================"
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --query "containers[0].volumeMounts" \
    -o table

echo ""
echo "🔄 Events (last 10):"
echo "==================="
az container show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CONTAINER_GROUP" \
    --query "instanceView.events[-10:]" \
    -o table
