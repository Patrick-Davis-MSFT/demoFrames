metadata description = 'Assigns an Azure Key Vault access policy.'

param keyVaultName string
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Assign Key Vault Secrets Officer role if principalId is provided
resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (principalId != '') {
  name: guid(keyVault.id, principalId, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role ID
    principalId: principalId
  }
}

// Assign Key Vault Secrets Officer role if principalId is provided
resource keyVaultRoleAssignment2 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (principalId != '') {
  name: guid(keyVault.id, principalId, 'Key Vault Certificate User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba') // Key Vault Secrets User role ID
    principalId: principalId
  }
}

// Assign Key Vault Secrets Officer role if principalId is provided
resource keyVaultRoleAssignment3 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (principalId != '') {
  name: guid(keyVault.id, principalId, 'Key Vault Crypto User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '12338af0-0e69-4776-bea7-57ae8d297424') // Key Vault Secrets User role ID
    principalId: principalId
  }
}
