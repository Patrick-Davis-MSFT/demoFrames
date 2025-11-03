import os
import logging
from azure.cosmos import CosmosClient, exceptions
from azure.identity import DefaultAzureCredential
from azure.core.exceptions import ClientAuthenticationError

# Configure logging
logger = logging.getLogger(__name__)

class versionCheck():
    """
    Version checker class that queries CosmosDB NoSQL using managed identity authentication.
    
    This implementation uses the CosmosDB SQL API instead of MongoDB API and leverages
    DefaultAzureCredential for secure, managed identity-based authentication.
    """
    
    def __init__(self, cosmosAccountUrl, cosmosDB, cosmosContainer):
        """
        Initialize the version checker with CosmosDB NoSQL parameters.
        
        Args:
            cosmosAccountUrl (str): CosmosDB account URL (e.g., https://myaccount.documents.azure.com:443/)
            cosmosDB (str): Database name
            cosmosContainer (str): Container name
        """
        self.cosmosAccountUrl = cosmosAccountUrl
        self.cosmosDB = cosmosDB
        self.cosmosContainer = cosmosContainer
        self._client = None
        
    def _get_cosmos_client(self):
        """
        Create and cache a CosmosDB client using DefaultAzureCredential.
        
        Returns:
            CosmosClient: Authenticated CosmosDB client
            
        Raises:
            ClientAuthenticationError: If authentication fails
            Exception: If client creation fails
        """
        if self._client is None:
            try:
                # Use DefaultAzureCredential which automatically handles:
                # - Managed Identity (when running in Azure)
                # - Azure CLI credentials (for local development)
                # - Environment variables, VS Code credentials, etc.
                credential = DefaultAzureCredential()
                
                # Create CosmosDB client with managed identity authentication
                self._client = CosmosClient(url=self.cosmosAccountUrl, credential=credential)
                logger.info("Successfully created CosmosDB client using DefaultAzureCredential")
                
            except ClientAuthenticationError as e:
                logger.error(f"Authentication failed: {e}")
                raise
            except Exception as e:
                logger.error(f"Failed to create CosmosDB client: {e}")
                raise
                
        return self._client
        
    def run(self):
        """
        Retrieve the latest version document from CosmosDB.
        
        Returns:
            dict: The latest document based on deploy_datetime, or None if no documents found
            
        Raises:
            Exception: If query fails or connection issues occur
        """
        try:
            # Get authenticated CosmosDB client
            client = self._get_cosmos_client()
            
            # Get database and container references
            database = client.get_database_client(self.cosmosDB)
            container = database.get_container_client(self.cosmosContainer)
            
            # Query for the latest document by deploy_datetime
            # Using SQL query for better performance and flexibility
            query = "SELECT * FROM c ORDER BY c.deploy_datetime DESC OFFSET 0 LIMIT 1"
            
            items = list(container.query_items(
                query=query,
                enable_cross_partition_query=True
            ))
            
            if items:
                document = items[0]
                logger.info(f"Retrieved latest version document with deploy_datetime: {document.get('deploy_datetime', 'N/A')}")
                return document
            else:
                logger.warning("No version documents found in the container")
                return None
                
        except exceptions.CosmosResourceNotFoundError as e:
            logger.error(f"Database or container not found: {e}")
            raise
        except exceptions.CosmosHttpResponseError as e:
            logger.error(f"CosmosDB HTTP error: {e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error during version check: {e}")
            raise
            
    def get_app_info(self):
        """
        Convenience method to get application name and version from the latest document.
        
        Returns:
            dict: Dictionary with appName and appVersion, or default values if not found
        """
        try:
            document = self.run()
            if document:
                return {
                    'appName': document.get('appName', 'Unknown'),
                    'appVersion': document.get('appVersion', '0.0.0'),
                    'deploy_datetime': document.get('deploy_datetime', 'Unknown')
                }
            else:
                return {
                    'appName': 'Unknown',
                    'appVersion': '0.0.0',
                    'deploy_datetime': 'Unknown'
                }
        except Exception as e:
            logger.error(f"Failed to get app info: {e}")
            return {
                'appName': 'Error',
                'appVersion': 'Error',
                'deploy_datetime': 'Error'
            }
