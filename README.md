# Deploy to Azure

This repository contains a Bicep template for deploying a Unifi Controller to Azure Container Instances.

## What gets deployed?

- Azure Storage Account with a blob container for Unifi configuration
- Azure Container Instance running the Unifi Controller
- Public IP address and DNS name for accessing the Unifi Controller

## Deployment Options

### Option 1: Deploy to Azure Button (One-click deployment)

Click the button below to deploy this template to Azure:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faadversteeg%2Fdeploy-to-azure%2Fmain%2Fmain.json)

### Option 2: Deploy using Azure CLI

You can also deploy this template using the Azure CLI. Here are the required commands:

```bash
# Login to Azure
az login

# Set variables
RESOURCE_GROUP_NAME="unifi-controller-rg"
LOCATION="westeurope"  # Change to your preferred Azure region
DEPLOYMENT_NAME="unifi-controller-deployment"

# Create Resource Group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Deploy the template
# 1. If using the remote template directly from GitHub:
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-uri https://raw.githubusercontent.com/aadversteeg/deploy-to-azure/main/main.json \
  --parameters resourceGroupName=$RESOURCE_GROUP_NAME location=$LOCATION

# 2. Or if using the Bicep file locally:
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-file main.bicep \
  --parameters resourceGroupName=$RESOURCE_GROUP_NAME location=$LOCATION

# Get the deployment outputs
az deployment group show \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --query properties.outputs
```

After deployment, you'll receive output with the FQDN and IP address for accessing your Unifi Controller.

### Option 3: Deploy Using PowerShell

You can also deploy using Azure PowerShell:

```powershell
# Login to Azure
Connect-AzAccount

# Set variables
$resourceGroupName = "unifi-controller-rg"
$location = "westeurope"  # Change to your preferred Azure region
$deploymentName = "unifi-controller-deployment"

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy the template
# 1. If using the remote template directly from GitHub:
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -Name $deploymentName `
  -TemplateUri "https://raw.githubusercontent.com/aadversteeg/deploy-to-azure/main/main.json" `
  -resourceGroupName $resourceGroupName `
  -location $location

# 2. Or if using the Bicep file locally:
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -Name $deploymentName `
  -TemplateFile "main.bicep" `
  -resourceGroupName $resourceGroupName `
  -location $location

# Get the deployment outputs
(Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName).Outputs
```

## Parameters

| Parameter | Description |
|-----------|-------------|
| resourceGroupName | The name of the resource group to deploy resources into |
| location | The Azure region to deploy resources to (defaults to the resource group's location) |
| storageAccountName | The name of the storage account (defaults to a unique name) |
| storageSku | The SKU for the storage account (defaults to Standard_LRS) |
| containerName | The name of the blob container (defaults to unifi-controller) |

## Post-Deployment

After deployment completes:

1. Navigate to `https://<containerGroupFQDN>:8443` to access the Unifi Controller UI
2. Complete the initial setup process for your Unifi network

## How it works

This repository uses GitHub Actions to automatically compile the Bicep template (`main.bicep`) to an ARM template (`main.json`) whenever changes are pushed to the repository. The "Deploy to Azure" button then links to this JSON file for deployment.

## Setting up GitHub Actions

To make the GitHub Actions workflow work properly:

1. Push this repository to GitHub:
   ```
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/aadversteeg/deploy-to-azure.git
   git push -u origin main
   ```

2. In your GitHub repository, go to **Settings > Actions > General**:
   - Under "Workflow permissions", select "Read and write permissions"
   - Click "Save"

Now, whenever you make changes to the Bicep file and push it to GitHub, the workflow will automatically compile it to a JSON ARM template.
