# Deploy to Azure - UniFi Controller

This repository contains a Bicep template for deploying a UniFi Controller to Azure Container Instances.

## Architecture

This solution deploys:
- **Single container** running UniFi Network Application with embedded MongoDB
- Uses the official GitHub Container Registry image: `ghcr.io/jacobalberty/unifi-docker:latest`
- EmptyDir volume for data storage
- Public IP address with DNS name

## Features

- ✅ Simple single-container deployment
- ✅ No Docker Hub rate limiting (uses GitHub Container Registry)
- ✅ Embedded MongoDB (no separate database container needed)
- ✅ Automatic DNS name generation
- ✅ All required UniFi ports exposed

## Quick Deploy

### Deploy to Azure Button

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Faadversteeg.github.io%2Fdeploy-to-azure%2Flatest%2Fmain.json)

### Azure CLI

```bash
# Set variables
RESOURCE_GROUP_NAME="unifi-controller-rg"
LOCATION="westeurope"

# Create Resource Group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Deploy template
az deployment group create \
  --resource-group $RESOURCE_GROUP_NAME \
  --template-file main.bicep \
  --parameters location=$LOCATION
```

### PowerShell

```powershell
# Set variables
$resourceGroupName = "unifi-controller-rg"
$location = "westeurope"

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile "main.bicep" `
  -location $location
```

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| location | Azure region for deployment | Resource group location |
| containerGroupName | Name of the container group | unifi-controller |
| timeZone | Container timezone | Europe/Amsterdam |
| containerMemoryGB | Memory allocation in GB | 2 |
| containerCpuCores | CPU cores allocation | 1 |

## Exposed Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8443 | TCP | UniFi web admin port (HTTPS) |
| 8080 | TCP | UniFi device communication |
| 3478 | UDP | UniFi STUN port |
| 10001 | UDP | AP discovery |
| 8843 | TCP | UniFi guest portal HTTPS |
| 6789 | TCP | UniFi mobile speed test |

## Post-Deployment

1. Wait 2-3 minutes for the container to fully initialize
2. Access the UniFi Controller at: `https://<containerFQDN>:8443`
3. Complete the initial setup wizard
4. Adopt your UniFi devices

## Data Persistence

⚠️ **Important**: This deployment uses EmptyDir volumes. Data persists through container restarts but will be **lost** if the container group is deleted. For production use, consider:
- Regular backups through the UniFi interface
- Exporting your configuration periodically
- Taking snapshots of your controller settings

## Container Image

This deployment uses the official jacobalberty UniFi Docker image from GitHub Container Registry:
- Image: `ghcr.io/jacobalberty/unifi-docker:latest`
- Repository: https://github.com/jacobalberty/unifi-docker
- No Docker Hub rate limiting issues
- Includes embedded MongoDB

## Troubleshooting

### Container Won't Start
- Check the container logs in Azure Portal
- Ensure sufficient memory/CPU allocation
- Verify all required ports are available

### Can't Access Web Interface
- Wait 2-3 minutes after deployment
- Check the FQDN in deployment outputs
- Ensure you're using HTTPS on port 8443
- Accept the self-signed certificate warning

### Performance Issues
- Increase memory allocation (3-4 GB recommended for larger deployments)
- Increase CPU cores for better performance
- Monitor container metrics in Azure Portal

## Security Considerations

- Change default credentials immediately after setup
- Consider implementing Azure Network Security Groups
- Use Azure Firewall for additional protection
- Enable UniFi's built-in security features

## License

This project is licensed under the MIT License - see the LICENSE file for details.
