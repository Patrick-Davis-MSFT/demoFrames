metadata description = 'Creates an Azure storage account.'
param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Cool'
  'Hot'
  'Premium' ])
param accessTier string = 'Hot'
param allowBlobPublicAccess bool = false
param allowCrossTenantReplication bool = true
param allowSharedKeyAccess bool = true
param containers array = []
param defaultToOAuthAuthentication bool = false
param deleteRetentionPolicy object = {}
@allowed([ 'AzureDnsZone', 'Standard' ])
param dnsEndpointType string = 'Standard'
param kind string = 'StorageV2'
param minimumTlsVersion string = 'TLS1_2'
param supportsHttpsTrafficOnly bool = true
param networkAcls object = {
  bypass: 'AzureServices'
  defaultAction: 'Allow'
}
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'
param sku object = { name: 'Standard_LRS' }

@description('The name of the virtual network')
param vnetName string

@description('The name of the subnet')
param subnetName string

@description('The Resource Group of the DNS Zone')
param dnsResourceGroup string
@description('The name of the DNS Zone')
param azurePrivateDnsNameBlob string = 'privatelink.blob.${environment().suffixes.storage}'
param azurePrivateDnsNameQueue string = 'privatelink.queue.${environment().suffixes.storage}'
param azurePrivateDnsNameFile string = 'privatelink.file.${environment().suffixes.storage}'
param azurePrivateDnsNameTable string = 'privatelink.table.${environment().suffixes.storage}'

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: sku
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: allowBlobPublicAccess
    allowCrossTenantReplication: allowCrossTenantReplication
    allowSharedKeyAccess: allowSharedKeyAccess
    defaultToOAuthAuthentication: defaultToOAuthAuthentication
    dnsEndpointType: dnsEndpointType
    minimumTlsVersion: minimumTlsVersion
    networkAcls: networkAcls
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {
      deleteRetentionPolicy: deleteRetentionPolicy
    }
    resource container 'containers' = [for container in containers: {
      name: container.name
      properties: {
        publicAccess: contains(container, 'publicAccess') ? container.publicAccess : 'None'
      }
    }]
  }
}



resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: '${name}-blob-pe'
  location: location
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-blob-plsc'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneBlob 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsNameBlob
}

// Update the private DNS zone group to reference the extern DNS zone
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpointBlob
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob'
        properties: {
          privateDnsZoneId: privateDnsZoneBlob.id
        }
      }
    ]
  }
}


resource privateEndpointQueue 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: '${name}-queue-pe'
  location: location
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-queue-plsc'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneQueue 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsNameQueue
}

// Update the private DNS zone group to reference the extern DNS zone
resource privateDnsZoneGroupQueue 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpointQueue
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-queue'
        properties: {
          privateDnsZoneId: privateDnsZoneQueue.id
        }
      }
    ]
  }
}

resource privateEndpointFile 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: '${name}-file-pe'
  location: location
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-file-plsc'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneFile 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsNameFile
}

// Update the private DNS zone group to reference the extern DNS zone
resource privateDnsZoneGroupFile 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpointFile
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file'
        properties: {
          privateDnsZoneId: privateDnsZoneFile.id
        }
      }
    ]
  }
}



resource privateEndpointTable 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: '${name}-table-pe'
  location: location
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-table-plsc'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneTable 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsNameTable
}

// Update the private DNS zone group to reference the extern DNS zone
resource privateDnsZoneGroupTable 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpointTable
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-table'
        properties: {
          privateDnsZoneId: privateDnsZoneTable.id
        }
      }
    ]
  }
}

output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
