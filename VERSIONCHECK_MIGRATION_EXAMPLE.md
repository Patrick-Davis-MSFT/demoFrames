# VersionCheck Migration Guide

## Overview
The `versionCheck` class has been updated to use CosmosDB NoSQL API with managed identity authentication instead of MongoDB API with connection strings.

## Key Changes

### Old Implementation (MongoDB API)
```python
from approaches.versioncheck import versionCheck

# Old way - using connection string
checker = versionCheck(
    cosmosEndpoint="https://myaccount.documents.azure.com:443/",
    cosmosDB="mydatabase", 
    cosmosCollection="mycollection",
    cosmosConnectionString="mongodb://username:password@host:port/..."
)
result = checker.run()
```

### New Implementation (CosmosDB NoSQL API)
```python
from approaches.versioncheck import versionCheck

# New way - using managed identity
checker = versionCheck(
    cosmosAccountUrl="https://myaccount.documents.azure.com:443/",
    cosmosDB="mydatabase",
    cosmosContainer="mycollection"  # Note: renamed from cosmosCollection
)
result = checker.run()

# Additional convenience method
app_info = checker.get_app_info()
print(f"App: {app_info['appName']} v{app_info['appVersion']} deployed at {app_info['deploy_datetime']}")
```

## Parameter Changes
- **Removed**: `cosmosEndpoint` and `cosmosConnectionString` 
- **Added**: `cosmosAccountUrl` (full URL including port)
- **Renamed**: `cosmosCollection` → `cosmosContainer`

## New Features
1. **Managed Identity Authentication**: No connection strings needed
2. **Better Error Handling**: Comprehensive exception handling with logging
3. **SQL Query Support**: Uses CosmosDB SQL API for better performance
4. **Convenience Method**: `get_app_info()` for easy access to app details
5. **Connection Caching**: Reuses client connections for efficiency

## Required Environment Variables
Ensure these environment variables are available:
- Azure authentication will work automatically with:
  - Managed Identity (in Azure)
  - Azure CLI credentials (local development)
  - Environment variables (`AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_TENANT_ID`)

## Error Handling
The new implementation includes comprehensive error handling:
```python
try:
    checker = versionCheck(cosmos_url, db_name, container_name)
    result = checker.run()
    if result:
        print(f"Latest version: {result.get('appVersion')}")
    else:
        print("No version information found")
except Exception as e:
    print(f"Error checking version: {e}")
```

## Migration Steps
1. Update calling code to use new parameter names
2. Remove connection string retrieval logic
3. Ensure managed identity permissions are set up
4. Test with the new authentication method

## Dependencies
Required packages (already in requirements.txt):
- `azure-cosmos>=4.9.0`
- `azure-identity>=1.23.0`
- `azure-core`

## Security Benefits
- No connection strings to manage or rotate
- Uses Azure AD authentication with audit trails
- Supports principle of least privilege with RBAC
- Automatic credential refresh