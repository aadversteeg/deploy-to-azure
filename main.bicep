@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name for the container group')
param containerGroupName string = 'unifi-controller'

@description('Name of the storage account for backups')
param storageAccountName string = 'stor${uniqueString(resourceGroup().id)}'

@description('Time zone for the container')
param timeZone string = 'Europe/Amsterdam'

@description('Container memory in GB for UniFi')
param containerMemoryGB int = 2

@description('Container CPU cores for UniFi')
param containerCpuCores int = 1

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

// Container Instance with UniFi Controller and MongoDB sidecar
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'unifi-controller'
        properties: {
          image: 'lscr.io/linuxserver/unifi-network-application:latest'
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
              name: 'MONGO_USER'
              value: 'unifi'
            }
            {
              name: 'MONGO_PASS'
              value: 'unifipassword'
            }
            {
              name: 'MONGO_HOST'
              value: 'localhost'
            }
            {
              name: 'MONGO_PORT'
              value: '27017'
            }
            {
              name: 'MONGO_DBNAME'
              value: 'unifi'
            }
            {
              name: 'MEM_LIMIT'
              value: '1024'
            }
            {
              name: 'MEM_STARTUP'
              value: '1024'
            }
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
            {
              name: 'unifi-backups'
              mountPath: '/config/data/backup'
            }
          ]
        }
      }
      {
        name: 'mongodb'
        properties: {
          image: 'docker.io/library/mongo:4.4'
          ports: [
            {
              port: 27017
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: json('0.5')
              memoryInGB: json('1')
            }
          }
          environmentVariables: [
            {
              name: 'MONGO_INITDB_ROOT_USERNAME'
              value: 'unifi'
            }
            {
              name: 'MONGO_INITDB_ROOT_PASSWORD'
              value: 'unifipassword'
            }
            {
              name: 'MONGO_INITDB_DATABASE'
              value: 'unifi'
            }
          ]
          volumeMounts: [
            {
              name: 'mongodb-data'
              mountPath: '/data/db'
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
        name: 'unifi-config'
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
output deploymentNotes string = 'UniFi with MongoDB sidecar. Data in EmptyDir, backups in Azure Files.'
