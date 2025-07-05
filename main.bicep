@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name for the container group')
param containerGroupName string = 'unifi-controller'

@description('Time zone for the container')
param timeZone string = 'Europe/Amsterdam'

@description('Container memory in GB')
param containerMemoryGB int = 3

@description('Container CPU cores')
param containerCpuCores int = 2

// Single Container with UniFi Controller (includes embedded MongoDB)
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'unifi-controller'
        properties: {
          image: 'jacobalberty/unifi:v8.6.9'
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
              name: 'RUNAS_UID0'
              value: 'true'
            }
            {
              name: 'UNIFI_STDOUT'
              value: 'true'
            }
            {
              name: 'JVM_INIT_HEAP_SIZE'
              value: '512M'
            }
            {
              name: 'JVM_MAX_HEAP_SIZE'
              value: '1024M'
            }
            {
              name: 'BIND_PRIV'
              value: 'false'
            }
          ]
          volumeMounts: [
            {
              name: 'unifi-data'
              mountPath: '/unifi'
            }
            {
              name: 'unifi-run'
              mountPath: '/var/run/unifi'
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
        name: 'unifi-run'
        emptyDir: {}
      }
    ]
  }
}

output containerIPv4Address string = containerGroup.properties.ipAddress.ip
output containerFQDN string = containerGroup.properties.ipAddress.fqdn
output accessUrl string = 'https://${containerGroup.properties.ipAddress.fqdn}:8443'
output deploymentNotes string = 'UniFi Controller v8.6.9 with embedded MongoDB from Docker Hub'
