Write-Host ""
Write-Host "Loading azd .env file from current environment"
Write-Host ""

$output = azd env get-values

foreach ($line in $output) {
  if (!$line.Contains('=')) {
    continue
  }

  $name, $value = $line.Split("=")
  $value = $value -replace '^\"|\"$'
  [Environment]::SetEnvironmentVariable($name, $value)
}

Write-Host "Environment variables set."

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # fallback to python3 if python not found
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}

Write-Host 'Creating python virtual environment "scripts/.venv" with ' $pythonCmd.Source
Start-Process -FilePath ($pythonCmd).Source -ArgumentList "-m venv ./scripts/.venv" -Wait -NoNewWindow

$venvPythonPath = "./scripts/.venv/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./scripts/.venv/bin/python"
}

Write-Host 'Installing dependencies from "requirements.txt" into virtual environment'
Start-Process -FilePath $venvPythonPath -ArgumentList "-m pip install -r ./scripts/requirements.txt" -Wait -NoNewWindow

Write-Host 'Setting kv policy for current user'
$currUser = az ad signed-in-user show --query "{id:id}" -o tsv

az role assignment create --assignee $currUser --role "Key Vault Secrets Officer" --scope "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:AZURE_RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$env:AZURE_KEY_VAULT_NAME"
az role assignment create --assignee $currUser --role "Key Vault Crypto Officer" --scope "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:AZURE_RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$env:AZURE_KEY_VAULT_NAME"

Write-Host 'Add Function Keys to Key Vault'
$functionKey = az functionapp keys list --name $env:AZURE_FUNCTION_APP_NAME --resource-group $env:AZURE_RESOURCE_GROUP --query "masterKey" -o tsv
if ($functionKey) {
    az keyvault secret set --name $env:AZURE_FUNCTION_APP_HOST_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --value $functionKey
  # Get all versions of the secret and disable all except the latest
  $secretVersions = az keyvault secret list-versions --name $env:AZURE_FUNCTION_APP_HOST_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query "[].id" -o tsv
  $latestVersion = az keyvault secret show --name $env:AZURE_FUNCTION_APP_HOST_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query "id" -o tsv

  foreach ($version in $secretVersions) {
      if ($version -ne $latestVersion) {
          $versionId = ($version -split "/")[-1]
          az keyvault secret set-attributes --name $env:AZURE_FUNCTION_APP_HOST_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --version $versionId --enabled false
      }
  }
}



$functionKey = az functionapp keys list --name $env:AZURE_FUNCTION_APP_NAME --resource-group $env:AZURE_RESOURCE_GROUP --query "functionKeys.default" -o tsv
if ($functionKey) {
  az keyvault secret set --name $env:AZURE_FUNCTION_APP_API_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --value $functionKey
  # Get all versions of the secret and disable all except the latest
  $secretVersions = az keyvault secret list-versions --name $env:AZURE_FUNCTION_APP_API_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query "[].id" -o tsv
  $latestVersion = az keyvault secret show --name $env:AZURE_FUNCTION_APP_API_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query "id" -o tsv

  foreach ($version in $secretVersions) {
      if ($version -ne $latestVersion) {
          $versionId = ($version -split "/")[-1]
          az keyvault secret set-attributes --name $env:AZURE_FUNCTION_APP_API_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --version $versionId --enabled false
      }
  }
}

# Get CosmosDB account URL for NoSQL API authentication
$cosmosAccountUrl = "https://$env:AZURE_COSMOS_ACCOUNT_NAME.documents.azure.com:443/"

Write-Host 'Getting current public IP address'
# Get the current public IP address of the user
$currentIP = (Invoke-RestMethod -Uri "https://api.ipify.org" -Method Get).Trim()
Write-Host "Current public IP address: $currentIP"

# Get current CosmosDB firewall configuration
Write-Host 'Checking current CosmosDB firewall configuration'
$currentFirewallRules = az cosmosdb show --resource-group $env:AZURE_RESOURCE_GROUP --name $env:AZURE_COSMOS_ACCOUNT_NAME --query "ipRules" -o json | ConvertFrom-Json

# Extract current IP addresses from the firewall rules
$currentIPs = @()
if ($currentFirewallRules) {
    $currentIPs = $currentFirewallRules | ForEach-Object { $_.ipAddressOrRange }
}

Write-Host "Current allowed IPs in CosmosDB: $($currentIPs -join ', ')"

# Check if current IP is already in the allowed list
$ipAlreadyAllowed = $currentIPs -contains $currentIP
$ipAlreadyAllowed = $true
if ($ipAlreadyAllowed) {
    Write-Host "Current IP address ($currentIP) is already allowed in CosmosDB firewall. Skipping firewall update."
} else {
    Write-Host 'Configuring CosmosDB firewall for selected networks with current IP address'
    # Configure CosmosDB to use selected networks mode and add current IP
    # Note: Azure portal IP (0.0.0.0) is added to allow Azure portal access
    $baseIPs = @("0.0.0.0", "4.210.172.107", "13.88.56.148", "13.91.105.215", "40.91.218.243")
    
    # Combine base IPs with current allowed IPs (excluding duplicates) and add current IP
    $allIPs = ($baseIPs + $currentIPs + $currentIP) | Sort-Object -Unique
    $ipRangeFilter = $allIPs -join ","

    az cosmosdb update --resource-group $env:AZURE_RESOURCE_GROUP --name $env:AZURE_COSMOS_ACCOUNT_NAME --ip-range-filter $ipRangeFilter

    # Enable public network access but restrict to selected networks
    az cosmosdb update --resource-group $env:AZURE_RESOURCE_GROUP --name $env:AZURE_COSMOS_ACCOUNT_NAME --enable-virtual-network false --enable-public-network true --network-acl-bypass "AzureServices"

    Write-Host "CosmosDB firewall updated. Allowed IPs: $ipRangeFilter"
}

$cosmosContributorRoleId = az cosmosdb sql role definition list --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --query "[?roleName=='Cosmos DB Built-in Data Contributor'].id" --output tsv

Write-Host 'Setting role for cosmosdb user '
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $currUser --scope $env:AZURE_COSMOS_ACCOUNT_ID
Write-Host 'Setting role for cosmosdb web and function app'
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $env:AZURE_WEB_APP_IDENTITY_PRINCIPAL_ID --scope $env:AZURE_COSMOS_ACCOUNT_ID
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $env:AZURE_FUNCTION_APP_IDENTITY_PRINCIPAL_ID --scope $env:AZURE_COSMOS_ACCOUNT_ID

az cosmosdb sql role assignment list --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME

Write-Host 'Running "uploadVersion.py" to upload version information to CosmosDB using managed identity'
$cwd = (Get-Location)
# Use the updated script with CosmosDB NoSQL API and managed identity authentication
Start-Process -FilePath $venvPythonPath -ArgumentList "./scripts/uploadVersion.py -a `"$cosmosAccountUrl`" -d $env:AZURE_COSMOS_DATABASE_NAME -c $env:AZURE_COSMOS_ABOUT_COLLECTION -f `"$cwd/data/appinfo.json`"" -Wait -NoNewWindow
