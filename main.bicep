@description('The Azure region to deploy resources to')
param location string = resourceGroup().location

@description('The name of the storage account to deploy')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('The SKU for the storage account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param storageSku string = 'Standard_LRS'

@description('Specifies the file share name for the UniFi configuration')
param fileShareName string = 'unifi-controller'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageSku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 14
    }
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  parent: fileService
  name: fileShareName
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: 'unifi-controller'
  location: location
  properties: {
    containers: [
      {
        name: 'unifi-controller'
        properties: {
          image: 'linuxserver/unifi-controller:latest'
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
              memoryInGB: 1.5
              cpu: 1
            }
          }
          environmentVariables: [
            {
              name: 'PUID'
              value: '1000'
            }
            {
              name: 'PGID'
              value: '1000'
            }
          ]
          volumeMounts: [
            {
              name: 'unifi-config'
              mountPath: '/config'
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
          storageAccountKey: listKeys(storageAccount.id, '2021-08-01').keys[0].value
        }
      }
    ]
  }
}

output storageAccountName string = storageAccount.name
output containerGroupFQDN string = containerGroup.properties.ipAddress.fqdn
output containerGroupIP string = containerGroup.properties.ipAddress.ip
