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
$currUser = az ad signed-in-user show --query id

az keyvault set-policy --name $env:AZURE_KEY_VAULT_NAME --object-id $currUser --secret-permissions get list set delete recover backup restore purge
$tempCS = az keyvault secret show --name "AZURE-COSMOS-CONNECTION-STRING" --vault-name "kv-i25ipilok42la" --query value -o tsv
[Environment]::SetEnvironmentVariable("AZURE_COSMOS_CONNECTION_STRING", $tempCS)
Write-Host 'Running "uploadVerion.py" to specify the version in cosmosdb'
$cwd = (Get-Location)
# Todo: Fix auth for the user
Start-Process -FilePath $venvPythonPath -ArgumentList "./scripts/uploadVersion.py -f `"$cwd/data/appinfo.json`" -d $env:AZURE_COSMOS_DATABASE_NAME -c $env:AZURE_COSMOS_ABOUT_COLLECTION -k $env:AZURE_COSMOS_CONNECTION_STRING " -Wait -NoNewWindow