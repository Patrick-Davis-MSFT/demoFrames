Write-Host ""
Write-Host "Loading azd .env file from current environment"
Write-Host ""

foreach ($line in (& azd env get-values)) {
    if ($line -match "([^=]+)=(.*)") {
        $key = $matches[1]
        $value = $matches[2] -replace '^"|"$'
        Set-Item -Path "env:\$key" -Value $value
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to load environment variables from azd environment"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Load Special Values from keyvault $env:AZURE_COSMOS_CONNECTION_STRING_KEY and $env:REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING_KEY"
Write-Host "from keyvault $env:AZURE_KEY_VAULT_NAME"
Write-Host ""
# Python Env Variable
# to see these variables use   `import os; print(os.environ['AZURE_COSMOS_CONNECTION_STRING'])` these variables are not visable to the user
$tempCS = az keyvault secret show --name $env:AZURE_COSMOS_CONNECTION_STRING_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query value -o tsv
[Environment]::SetEnvironmentVariable("AZURE_COSMOS_CONNECTION_STRING", $tempCS)

# VITE Env Variable for the react app
# to see these variables in the code use `const appinsight = import.meta.env.VITE_APPLICATIONINSIGHTS_CONNECTION_STRING` consider these visable to the user

# Don't set the App Insights for local runs
#$temp = az keyvault secret show --name $env:VITE_APPLICATIONINSIGHTS_CONNECTION_STRING_KEY --vault-name $env:AZURE_KEY_VAULT_NAME --query "value" -o tsv
# Set-Item -Path "env:\VITE_APPLICATIONINSIGHTS_CONNECTION_STRING" -Value $temp

Write-Host 'Creating python virtual environment "api/api_env"'
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
  # fallback to python3 if python not found
  $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}
Start-Process -FilePath ($pythonCmd).Source -ArgumentList "-m venv ./api/api_env" -Wait -NoNewWindow

Write-Host ""
Write-Host "Restoring api python packages"
Write-Host ""

Set-Location api
$venvPythonPath = "./api_env/scripts/python.exe"
if (Test-Path -Path "/usr") {
  # fallback to Linux venv path
  $venvPythonPath = "./api_env/bin/python"
}

Start-Process -FilePath $venvPythonPath -ArgumentList "-m pip install -r requirements.txt" -Wait -NoNewWindow
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to restore api python packages"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Restoring web npm packages"
Write-Host ""
Set-Location ../web
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to restore web npm packages"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Starting web"
Write-Host ""
Start-Process npm -ArgumentList "run dev"
Start-Process http://localhost:5173/

Set-Location ../api
Start-Process -FilePath $venvPythonPath -ArgumentList "-m flask run --port=5000 --reload --debug" -Wait -NoNewWindow

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start api"
    exit $LASTEXITCODE
}
