# Azure Deployment Configuration

This document explains how to configure the GitHub repository for automated Azure deployments.

## Prerequisites

1. An Azure Service Principal with appropriate permissions
2. GitHub repository with Actions enabled
3. Azure subscription

## Setting up GitHub Secrets

### 1. Create Service Principal (if not already done)

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-unifi-deployer" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth

# Or reset credentials for existing service principal
az ad app credential reset \
  --id <clientId> \
  --append \
  --display-name github-deployer-secret
```

### 2. Add GitHub Secret

1. Go to your GitHub repository
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the JSON output from the service principal creation command:

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<SECRET>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

**Important**: Copy the **entire JSON output** including all fields. The endpoint URLs are required for the Azure Login action to work correctly.

## Setting up Repository Variables

Repository variables allow you to configure deployment parameters without modifying the workflow.

### Required Variables

Go to Settings → Secrets and variables → Actions → Variables tab and add:

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_RESOURCE_GROUP` | Target resource group name | `unifi-controller-prod-rg` |

### Optional Variables

| Variable Name | Description | Default Value |
|--------------|-------------|---------------|
| `CONTAINER_GROUP_NAME` | Name for the container group | `unifi-controller` |
| `LOCATION` | Azure region | `westeurope` |
| `TIME_ZONE` | Container timezone | `Europe/Amsterdam` |
| `FILE_SHARE_SIZE_GB` | Storage share size in GB | `5` |
| `CONTAINER_MEMORY_GB` | Container memory in GB | `2` |

## Environments (Optional)

For better control, you can set up GitHub Environments:

1. Go to Settings → Environments
2. Create environments: `development`, `staging`, `production`
3. Add protection rules (e.g., required reviewers for production)
4. You can override variables per environment

## Deployment Workflow

The deployment workflow is triggered manually:

### Manual Deployment (Workflow Dispatch)
1. Go to Actions → Deploy to Azure
2. Click "Run workflow"
3. Select the environment (development/staging/production)
4. Click "Run workflow"

The workflow will:
- Validate the Bicep template
- Build it to ARM JSON
- Deploy to your specified Azure environment
- Provide a summary with access URLs

## Example Configuration

### Minimal Setup
```
Secrets:
- AZURE_CREDENTIALS: <service-principal-json>

Variables:
- AZURE_SUBSCRIPTION_ID: 12345678-1234-1234-1234-123456789012
- AZURE_RESOURCE_GROUP: my-unifi-rg
```

### Full Setup
```
Secrets:
- AZURE_CREDENTIALS: <service-principal-json>

Variables:
- AZURE_SUBSCRIPTION_ID: 12345678-1234-1234-1234-123456789012
- AZURE_RESOURCE_GROUP: unifi-prod-rg
- CONTAINER_GROUP_NAME: unifi-controller-prod
- LOCATION: northeurope
- TIME_ZONE: Europe/Oslo
- FILE_SHARE_SIZE_GB: 10
- CONTAINER_MEMORY_GB: 4
```

## Security Best Practices

1. **Limit Service Principal Scope**: Instead of subscription-wide contributor, limit to specific resource group:
   ```bash
   az ad sp create-for-rbac \
     --name "github-unifi-deployer" \
     --role contributor \
     --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>
   ```

2. **Use Environments**: Set up environment protection rules for production deployments

3. **Regular Credential Rotation**: Rotate service principal credentials periodically

4. **Audit Deployments**: All deployments are tagged with metadata for tracking

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify AZURE_CREDENTIALS secret is properly formatted JSON
   - Check service principal has necessary permissions

2. **Resource Group Not Found**
   - The workflow creates the resource group if it doesn't exist
   - Ensure service principal has permissions to create resource groups

3. **Variable Not Found**
   - Check variable names match exactly (case-sensitive)
   - Ensure variables are set at repository level, not environment level (unless using environments)

### Viewing Deployment Results

1. Check the workflow run in Actions tab
2. View the deployment summary in the workflow run
3. Access the UniFi Controller at the provided FQDN after deployment

## Support

For issues with:
- Azure deployment: Check Azure Portal activity log
- GitHub Actions: Check workflow logs
- UniFi Controller: Check container logs in Azure Portal
