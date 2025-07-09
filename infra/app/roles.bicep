

param resourceID string

// Assign the "Storage Blob Data Contributor" role (role definition id: ba92f5b4-2d11-453d-a403-e96b0029c9fe)
resource blobContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceID, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: resourceID
  }
}


resource kvSecretsReadRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceID, '21090545-7ca7-4776-b22c-e363652d74d2')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '21090545-7ca7-4776-b22c-e363652d74d2')
    principalId: resourceID
  }
}

resource arcPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceID, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: resourceID
  }
}
