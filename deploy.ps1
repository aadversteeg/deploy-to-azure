# Deploy UniFi Controller to Azure - PowerShell Script
# Uses ghcr.io/jacobalberty/unifi-docker:latest

param(
    [string]$ResourceGroup = "unifi-controller-rg",
    [string]$Location = "westeurope",
    [string]$ContainerGroupName = "unifi-controller"
)

Write-Host "🚀 Deploying UniFi Controller to Azure" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup"
Write-Host "Location: $Location"
Write-Host "Container Group: $ContainerGroupName"
Write-Host ""

# Check if logged in to Azure
Write-Host "📌 Checking Azure login status..." -ForegroundColor Yellow
try {
    $account = Get-AzContext
    if (-not $account) {
        throw "Not logged in"
    }
    Write-Host "✅ Logged in to Azure as: $($account.Account)" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'Connect-AzAccount' first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Create resource group
Write-Host "📦 Creating resource group..." -ForegroundColor Yellow
$rg = New-AzResourceGroup -Name $ResourceGroup -Location $Location -Force
Write-Host "✅ Resource group created/confirmed" -ForegroundColor Green

# Deploy the template
Write-Host ""
Write-Host "🔧 Deploying UniFi Controller..." -ForegroundColor Yellow

$deploymentName = "unifi-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"
$deployment = New-AzResourceGroupDeployment `
    -Name $deploymentName `
    -ResourceGroupName $ResourceGroup `
    -TemplateFile "main.bicep" `
    -location $Location `
    -containerGroupName $ContainerGroupName

# Extract outputs
$fqdn = $deployment.Outputs.containerFQDN.Value
$ip = $deployment.Outputs.containerIPv4Address.Value
$url = $deployment.Outputs.accessUrl.Value

Write-Host ""
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "======================" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Access Information:" -ForegroundColor Cyan
Write-Host "   URL: $url" -ForegroundColor White
Write-Host "   FQDN: $fqdn" -ForegroundColor White
Write-Host "   IP: $ip" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Wait 2-3 minutes for container to initialize"
Write-Host "   2. Access UniFi Controller at: $url"
Write-Host "   3. Complete the setup wizard"
Write-Host "   4. Configure automatic backups"
Write-Host ""
Write-Host "⚠️  Remember: Data is stored in EmptyDir volumes." -ForegroundColor Yellow
Write-Host "   Regular backups are recommended!" -ForegroundColor Yellow
