# Azure Service Principal Configuration

## Sample AZURE_CREDENTIALS Secret Format

When you run the Azure CLI command to create or reset service principal credentials:

```bash
az ad sp create-for-rbac \
  --name "github-unifi-deployer" \
  --role contributor \
  --scopes /subscriptions/<subscription-id> \
  --sdk-auth
```

Or:

```bash
az ad app credential reset \
  --id <clientId> \
  --append \
  --display-name github-deployer-secret \
  --sdk-auth
```

You'll receive output in this format:

```json
{
  "clientId": "00000000-0000-0000-0000-000000000000",
  "clientSecret": "your-client-secret-here",
  "subscriptionId": "00000000-0000-0000-0000-000000000000",
  "tenantId": "00000000-0000-0000-0000-000000000000",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

**Note**: The additional endpoint URLs are included when using the `--sdk-auth` flag and are required for the Azure Login GitHub Action to work correctly across different Azure environments.

## Important Notes

1. **Copy the entire JSON object** including the curly braces
2. **Save the secret immediately** - you cannot retrieve it later
3. **Use --sdk-auth flag** to get the correct JSON format
4. **Do not commit this file** - it's for reference only

## Setting in GitHub

1. Go to your repository's Settings
2. Navigate to Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the entire JSON object
6. Click "Add secret"

## Security Recommendations

- Limit the service principal's scope to the specific resource group
- Rotate credentials periodically
- Use separate service principals for different environments
- Enable audit logging in Azure to track deployments
