@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name for the container group')
param containerGroupName string = 'unifi-controller'

@description('Name of the storage account for backups')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('Time zone for the container')
param timeZone string = 'Europe/Amsterdam'

@description('Container memory in GB')
param containerMemoryGB int = 3

@description('Container CPU cores')
param containerCpuCores int = 2

// Storage account for backups only
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
    minimumTlsVersion: 'TLS1_2'
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource backupShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileService
  name: 'unifi-backups'
  properties: {
    shareQuota: 10
    accessTier: 'TransactionOptimized'
    enabledProtocols: 'SMB'
  }
}

// Container Instance with UniFi Controller
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'unifi-controller'
        properties: {
          image: 'jacobalberty/unifi:latest'
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
            {
              port: 8843
              protocol: 'TCP'
            }
            {
              port: 6789
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: json(string(containerCpuCores))
              memoryInGB: json(string(containerMemoryGB))
            }
          }
          environmentVariables: [
            {
              name: 'TZ'
              value: timeZone
            }
            {
              name: 'UNIFI_UID'
              value: '1000'
            }
            {
              name: 'UNIFI_GID'
              value: '1000'
            }
            {
              name: 'BIND_PRIV'
              value: 'false'
            }
            {
              name: 'DB_MONGO_LOCAL'
              value: 'true'
            }
            {
              name: 'DB_MONGO_URL'
              value: 'mongodb://127.0.0.1:27017/unifi'
            }
            {
              name: 'STATDB_MONGO_URL'
              value: 'mongodb://127.0.0.1:27017/unifi_stat'
            }
            {
              name: 'UNIFI_DB_NAME'
              value: 'unifi'
            }
          ]
          volumeMounts: [
            {
              name: 'unifi-data'
              mountPath: '/usr/lib/unifi/data'
            }
            {
              name: 'unifi-logs'
              mountPath: '/usr/lib/unifi/logs'
            }
            {
              name: 'mongodb-data'
              mountPath: '/usr/lib/unifi/data/db'
            }
            {
              name: 'unifi-backups'
              mountPath: '/usr/lib/unifi/data/backup'
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
        {
          port: 8843
          protocol: 'TCP'
        }
        {
          port: 6789
          protocol: 'TCP'
        }
      ]
      dnsNameLabel: 'unifi-${uniqueString(resourceGroup().id)}'
    }
    volumes: [
      {
        name: 'unifi-data'
        emptyDir: {}
      }
      {
        name: 'unifi-logs'
        emptyDir: {}
      }
      {
        name: 'mongodb-data'
        emptyDir: {}
      }
      {
        name: 'unifi-backups'
        azureFile: {
          shareName: backupShare.name
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
output backupShareName string = backupShare.name
output accessUrl string = 'https://${containerGroup.properties.ipAddress.fqdn}:8443'
output deploymentNotes string = 'Single container with embedded MongoDB. Data in EmptyDir, backups in Azure Files.'
