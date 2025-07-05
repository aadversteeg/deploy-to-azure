# Deploy to Azure

This repository contains a Bicep template for deploying a UniFi Controller to Azure Container Instances.

## Architecture

This solution deploys a **single container** with:
- UniFi Network Application with embedded MongoDB
- EmptyDir volumes for data persistence (survives container restarts)
- Azure Files for backup storage only

## What gets deployed?

- Azure Container Instance running UniFi Network Application v8
- Azure Storage Account with file share for backups
- Public IP address and DNS name for accessing the UniFi Controller
- EmptyDir volumes for MongoDB and application data

## Why this approach?

- **Simple**: Single container with embedded MongoDB
- **Reliable**: Avoids Azure Files compatibility issues with MongoDB
- **Fast**: EmptyDir volumes provide better I/O performance
- **Safe**: Backups stored in durable Azure Files storage

## Deployment Options

### Option 1: Deploy to Azure Button (One-click deployment)

Click the button below to deploy this template to Azure:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Faadversteeg.github.io%2Fdeploy-to-azure%2Flatest%2Fmain.json)

> **Note**: This button always deploys the latest stable release. You can find specific versions in the [Releases](https://github.com/aadversteeg/deploy-to-azure/releases) section.

### Option 2: Deploy using Azure CLI

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP_NAME="unifi-controller-rg"
LOCATION="westeurope"  # Change to your preferred Azure region
DEPLOYMENT_NAME="unifi-controller-deployment"

# Create Resource Group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Deploy the template directly from GitHub Pages
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-uri https://aadversteeg.github.io/deploy-to-azure/latest/main.json \
  --parameters location=$LOCATION

# Get the deployment outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --query properties.outputs
```

### Option 3: Deploy using PowerShell

```powershell
# Login to Azure
Connect-AzAccount

# Set variables
$resourceGroupName = "unifi-controller-rg"
$location = "westeurope"  # Change to your preferred Azure region
$deploymentName = "unifi-controller-deployment"

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy the template from GitHub Pages
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -Name $deploymentName `
  -TemplateUri "https://aadversteeg.github.io/deploy-to-azure/latest/main.json" `
  -location $location

# Get the deployment outputs
(Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName).Outputs
```

### Option 4: Manual Deployment via Azure Portal

1. Download the `main.json` file from the [latest release](https://github.com/aadversteeg/deploy-to-azure/releases/latest)
2. Go to the [Azure Portal](https://portal.azure.com)
3. Search for "Deploy a custom template"
4. Click "Build your own template in the editor"
5. Click "Load file" and select the downloaded `main.json`
6. Click "Save"
7. Fill in the required parameters:
   - **Resource Group**: Create new or select existing
   - **Location**: Your preferred Azure region
   - Other parameters as needed (see Parameters section below)
8. Click "Review + create"
9. Click "Create"

## Parameters

| Parameter | Description | Default Value |
|-----------|-------------|--------------|
| location | The Azure region to deploy resources to | Resource group's location |
| containerGroupName | The name of the container group | unifi-controller |
| storageAccountName | The name of the storage account for backups | Unique generated name |
| timeZone | Time zone for the container | Europe/Amsterdam |
| containerMemoryGB | Container memory in GB | 3 |
| containerCpuCores | Container CPU cores | 2 |

## Post-Deployment

After deployment completes:

1. Navigate to `https://<containerGroupFQDN>:8443` to access the UniFi Controller UI
2. Complete the initial setup process for your UniFi network
3. Configure automatic backups in the UniFi settings

## Data Persistence

- **Application Data**: Stored in EmptyDir volumes (persists during container restarts)
- **Backups**: Stored in Azure Files for durable storage
- **Important**: EmptyDir data is lost if the container group is deleted - ensure regular backups!

## Ports

The following ports are exposed:

| Port | Protocol | Purpose |
|------|----------|---------|
| 8443 | TCP | UniFi web admin port |
| 8080 | TCP | UniFi device communication |
| 3478 | UDP | UniFi STUN port |
| 10001 | UDP | AP discovery |
| 8843 | TCP | UniFi guest portal HTTPS |
| 6789 | TCP | UniFi mobile speed test |

## CI/CD Pipeline

This repository uses GitHub Actions for:
- **Validation** (`validate.yml`) - Validates the Bicep template on every push
- **Deploy** (`deploy.yml`) - Direct deployment to Azure (manual trigger)
- **Release** (`release.yml`) - Creates releases with compiled ARM templates

## Creating a Release

To create a new release:

1. Make your changes to the Bicep template
2. Commit and push your changes to main
3. Wait for the validation workflow to pass
4. Create a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

## Direct Deployment from GitHub

For direct deployment using GitHub Actions, see [DEPLOYMENT_CONFIG.md](DEPLOYMENT_CONFIG.md).

## Workflow Status

![Validate Bicep](https://github.com/aadversteeg/deploy-to-azure/actions/workflows/validate.yml/badge.svg)
![Deploy to Azure](https://github.com/aadversteeg/deploy-to-azure/actions/workflows/deploy.yml/badge.svg)
![Release](https://github.com/aadversteeg/deploy-to-azure/actions/workflows/release.yml/badge.svg)
