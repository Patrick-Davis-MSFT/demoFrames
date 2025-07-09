@description('The location for all resources')
param location string = resourceGroup().location

@description('Virtual Network name')
param vnetName string

@description('Virtual Network address prefix')
param vnetAddressPrefix string = '10.0.0.0/20'

@description('Optional tags for all resources')
param tags object = {}

// NSG name is derived from vnet name
param nsgName string = '${vnetName}-nsg'

// Define subnet configurations
param subnets array 

// Create NSG
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Create Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
           networkSecurityGroup: {
          id: networkSecurityGroup.id
        }
        delegations: contains(subnet, 'delegations') ? subnet.delegations : []
      }
    }]
  }
}

// Outputs
@description('The resource ID of the created virtual network')
output vnetId string = virtualNetwork.id
output vnetname string = virtualNetwork.name

@description('The resource ID of the created NSG')
output nsgId string = networkSecurityGroup.id

@description('Array of subnet resource IDs')
output subnet array = [for (subnet, i) in subnets: virtualNetwork.properties.subnets[i]]
