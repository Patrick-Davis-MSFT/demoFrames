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
param azurePrivateDnsName string = 'privatelink.blob.core.windows.net'

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



resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-07-01' = {
  name: '${name}-pe'
  location: location
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-plsc'
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(dnsResourceGroup)
  name: azurePrivateDnsName
}

// Update the private DNS zone group to reference the extern DNS zone
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-06-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output name string = storage.name
output primaryEndpoints object = storage.properties.primaryEndpoints
