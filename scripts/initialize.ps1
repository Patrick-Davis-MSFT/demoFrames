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

$functionKey = az functionapp keys list --name $env:AZURE_FUNCTION_APP_NAME --resource-group $env:AZURE_RESOURCE_GROUP --query "functionKeys.default" -o tsv
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


$tempCS = az keyvault secret show --name "AZURE-COSMOS-CONNECTION-STRING" --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
[Environment]::SetEnvironmentVariable("AZURE_COSMOS_CONNECTION_STRING", $tempCS)

$cosmosContributorRoleId = az cosmosdb sql role definition list --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --query "[?roleName=='Cosmos DB Built-in Data Contributor'].id" --output tsv

Write-Host 'Setting role for cosmosdb user '
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $currUser --scope "/subscriptions/aaaa0a0a-bb1b-cc2c-dd3d-eeeeee4e4e4e/resourceGroups/msdocs-identity-example/providers/Microsoft.DocumentDB/databaseAccounts/msdocs-identity-example-nosql"
Write-Host 'Setting role for cosmosdb web and function app'
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $env:AZURE_WEB_APP_IDENTITY_PRINCIPAL_ID --scope "/subscriptions/aaaa0a0a-bb1b-cc2c-dd3d-eeeeee4e4e4e/resourceGroups/msdocs-identity-example/providers/Microsoft.DocumentDB/databaseAccounts/msdocs-identity-example-nosql"
az cosmosdb sql role assignment create --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME --role-definition-id $cosmosContributorRoleId --principal-id $env:AZURE_FUNCTION_APP_IDENTITY_PRINCIPAL_ID --scope "/subscriptions/aaaa0a0a-bb1b-cc2c-dd3d-eeeeee4e4e4e/resourceGroups/msdocs-identity-example/providers/Microsoft.DocumentDB/databaseAccounts/msdocs-identity-example-nosql"

az cosmosdb sql role assignment list --resource-group $env:AZURE_RESOURCE_GROUP --account-name $env:AZURE_COSMOS_ACCOUNT_NAME


Write-Host 'Running "uploadVerion.py" to specify the version in cosmosdb'
$cwd = (Get-Location)
# Todo: Fix auth for the user
Start-Process -FilePath $venvPythonPath -ArgumentList "./scripts/uploadVersion.py -f `"$cwd/data/appinfo.json`" -d $env:AZURE_COSMOS_DATABASE_NAME -c $env:AZURE_COSMOS_ABOUT_COLLECTION -k $env:AZURE_COSMOS_CONNECTION_STRING " -Wait -NoNewWindow
