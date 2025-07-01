# Deploy to Azure

This repository contains a Bicep template for deploying a Unifi Controller to Azure Container Instances.

## What gets deployed?

- Azure Storage Account with a file share for Unifi configuration
- Azure Container Instance running the Unifi Controller
- Public IP address and DNS name for accessing the Unifi Controller

## Deployment Options

### Option 1: Deploy to Azure Button (One-click deployment)

Click the button below to deploy this template to Azure:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fgithub.com%2Faadversteeg%2Fdeploy-to-azure%2Freleases%2Flatest%2Fdownload%2Fmain.json)

> **Note**: This button always deploys the latest stable release. You can find specific versions in the [Releases](https://github.com/aadversteeg/deploy-to-azure/releases) section.

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
# 1. If using the remote template directly from GitHub releases (recommended):
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-uri https://github.com/aadversteeg/deploy-to-azure/releases/latest/download/main.json \
  --parameters location=$LOCATION

# 2. Or if using the Bicep file locally:
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $DEPLOYMENT_NAME \
  --template-file main.bicep \
  --parameters location=$LOCATION

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
# 1. If using the remote template directly from GitHub releases (recommended):
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -Name $deploymentName `
  -TemplateUri "https://github.com/aadversteeg/deploy-to-azure/releases/latest/download/main.json" `
  -location $location

# 2. Or if using the Bicep file locally:
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -Name $deploymentName `
  -TemplateFile "main.bicep" `
  -location $location

# Get the deployment outputs
(Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName).Outputs
```

## Parameters

| Parameter | Description | Default Value |
|-----------|-------------|--------------|
| location | The Azure region to deploy resources to | Resource group's location |
| containerGroupName | The name of the container group | unifi-controller |
| storageAccountName | The name of the storage account | Unique generated name |
| fileShareName | The name of the file share | unifi-controller |
| timeZone | Time zone for the container | Europe/Amsterdam |
| fileShareSizeGB | File share size in GB | 5 |
| containerMemoryGB | Container memory in GB | 2 |

## Post-Deployment

After deployment completes:

1. Navigate to `https://<containerGroupFQDN>:8443` to access the Unifi Controller UI
2. Complete the initial setup process for your Unifi network

## How it works

This repository uses GitHub Actions to:
1. **Validate** (`validate.yml`) - Automatically validates and compiles the Bicep template on every push to main and every pull request
2. **Release** (`release.yml`) - Creates GitHub releases with the compiled ARM template when you create a version tag

The "Deploy to Azure" button always links to the latest released version, ensuring stable deployments.

**Important**: The first release must be created before the Deploy to Azure button will work, as it links to GitHub releases.

## Creating a Release

To create a new release:

1. Make your changes to the Bicep template
2. Commit and push your changes to main
3. Wait for the validation workflow to pass
4. Create a version tag:
   ```bash
   git tag 1.0.0  # or v1.0.0
   git push origin 1.0.0
   ```

The release workflow will:
- Compile the Bicep template to ARM JSON
- Create a GitHub release with:
  - `main.json` - ARM template ready for deployment
  - `main.bicep` - Source Bicep template
  - `main.parameters.json` - Parameters file
  - `main.parameters.example.json` - Example parameters with values
  - `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
  - ZIP package with all files
- The "Deploy to Azure" button automatically uses the latest release

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Test locally: `bicep build main.bicep`
5. Commit your changes (`git commit -m 'Add some feature'`)
6. Push to the branch (`git push origin feature/your-feature-name`)
7. Submit a pull request

The validate workflow will automatically check your Bicep template for errors.

## Workflow Status

![Validate Bicep](https://github.com/aadversteeg/deploy-to-azure/actions/workflows/validate.yml/badge.svg)
![Release](https://github.com/aadversteeg/deploy-to-azure/actions/workflows/release.yml/badge.svg)
