metadata description = 'Creates an Azure Key Vault.'
param name string
param location string = resourceGroup().location
param tags object = {}
param vnetName string = ''
param subnetName string = ''
param privateAccess bool = !empty(vnetName) && !empty(subnetName)
param enablePrivateEndpoint bool = !empty(vnetName) && !empty(subnetName)
param principalId string = ''
param dnsResourceGroup string
param azurePrivateDnsName string = 'privatelink.vaultcore.azure.net'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    publicNetworkAccess: privateAccess ? 'Disabled' : 'Enabled'
    networkAcls: privateAccess ? {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    } : {}
  }
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (principalId != '') {
  name: guid(keyVault.id, principalId, 'Key Vault Secrets Officer')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7') // Key Vault Secrets Officer role ID
    principalId: principalId
  }
}


/*// Private DNS Zone for Key Vault
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (enablePrivateEndpoint) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

// Link the Private DNS Zone to the VNet
resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (enablePrivateEndpoint) {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', vnetName)
    }
  }
}*/



// Create Private Endpoint for Key Vault
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (enablePrivateEndpoint) {
  name: '${name}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: '${resourceId(dnsResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-plsc'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
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

// Create DNS Zone Group for the private endpoint
resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (enablePrivateEndpoint) {
  parent: privateEndpoint
  name: 'keyvault-dns-group'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'keyvault-dns-config'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

output endpoint string = keyVault.properties.vaultUri
output name string = keyVault.name
