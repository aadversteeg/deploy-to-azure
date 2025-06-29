@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name for the container group')
param containerGroupName string = 'unifi-controller'

@description('Name of the storage account')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('Name of the file share')
param fileShareName string = 'unifi-controller'

@description('Time zone for the container')
param timeZone string = 'Europe/Amsterdam'

@description('File share size in GB')
param fileShareSizeGB int = 5

@description('Container memory in GB')
param containerMemoryGB int = 2

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileService
  name: fileShareName
  properties: {
    shareQuota: fileShareSizeGB * 1024
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'unifi-${uniqueString(resourceGroup().id)}'
        properties: {
          image: 'ghcr.io/jacobalberty/unifi-docker:v8.1'
          ports: [
            {
              port: 8443
              protocol: 'TCP'
            }
            {
              port: 8080
              protocol: 'TCP'
            }
            {
              port: 3478
              protocol: 'UDP'
            }
            {
              port: 10001
              protocol: 'UDP'
            }
          ]
          resources: {
            requests: {
              cpu: json('1')
              memoryInGB: json(string(containerMemoryGB))
            }
          }
          environmentVariables: [
            {
              name: 'TZ'
              value: timeZone
            }
          ]
          volumeMounts: [
            {
              name: 'unifi-config'
              mountPath: '/unifi'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Always'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          port: 8443
          protocol: 'TCP'
        }
        {
          port: 8080
          protocol: 'TCP'
        }
        {
          port: 3478
          protocol: 'UDP'
        }
        {
          port: 10001
          protocol: 'UDP'
        }
      ]
      dnsNameLabel: 'unifi-controller-${uniqueString(resourceGroup().id)}'
    }
    volumes: [
      {
        name: 'unifi-config'
        azureFile: {
          shareName: fileShare.name
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
  }
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
output containerFQDN string = containerGroup.properties.ipAddress.fqdn
output storageAccountName string = storageAccount.name
