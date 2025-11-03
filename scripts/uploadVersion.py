
import json
from datetime import datetime
import os
import sys
import uuid
import argparse
import logging
from azure.core.exceptions import AzureError, ClientAuthenticationError, ResourceExistsError
from azure.cosmos import CosmosClient, exceptions
from azure.identity import DefaultAzureCredential

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def create_cosmos_client(account_url):
    """
    Create a CosmosDB client using DefaultAzureCredential for authentication.
    This uses managed identity when running in Azure, or the current user's identity locally.
    """
    try:
        # Use DefaultAzureCredential which automatically handles:
        # - Managed Identity (when running in Azure)
        # - Azure CLI credentials (for local development)
        # - Visual Studio Code credentials
        # - Environment variables
        credential = DefaultAzureCredential()
        
        # Create CosmosDB client with managed identity authentication
        client = CosmosClient(url=account_url, credential=credential)
        logger.info("Successfully created CosmosDB client using DefaultAzureCredential")
        return client
        
    except ClientAuthenticationError as e:
        logger.error(f"Authentication failed: {e}")
        raise
    except Exception as e:
        logger.error(f"Failed to create CosmosDB client: {e}")
        raise

def upsert_document(client, database_name, container_name, document_data):
    """
    Upsert a document to the specified CosmosDB container.
    """
    try:
        # Get database reference
        database = client.get_database_client(database_name)
        logger.info(f"Connected to database: {database_name}")
        
        # Get container reference
        container = database.get_container_client(container_name)
        logger.info(f"Connected to container: {container_name}")
        
        # Add unique id if not present
        if 'id' not in document_data:
            document_data['id'] = str(uuid.uuid4())
        
        # Upsert the document (insert or update if exists)
        response = container.upsert_item(body=document_data)
        logger.info(f"Successfully upserted document with id: {response['id']}")
        
        return response
        
    except exceptions.CosmosResourceNotFoundError as e:
        logger.error(f"Database or container not found: {e}")
        raise
    except exceptions.CosmosHttpResponseError as e:
        logger.error(f"CosmosDB HTTP error: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error during document upsert: {e}")
        raise

if __name__ == "__main__": 
    parser = argparse.ArgumentParser(
        description='Upload version information to CosmosDB NoSQL using managed identity authentication'
    )
    parser.add_argument('-a', '--account-url', help='CosmosDB account URL (e.g., https://myaccount.documents.azure.com:443/)', required=True)
    parser.add_argument('-d', '--dbname', help='CosmosDB database name', required=True)
    parser.add_argument('-c', '--containername', help='CosmosDB container name', required=True)
    parser.add_argument('-f', '--filename', help='JSON file to upload', required=True)
    parser.add_argument('--partition-key', help='Partition key value (optional)', default=None)

    args = parser.parse_args()
    
    try:
        # Validate input file exists
        if not os.path.exists(args.filename):
            logger.error(f"File not found: {args.filename}")
            sys.exit(1)
        
        # Create CosmosDB client using managed identity
        logger.info("Initializing CosmosDB client...")
        client = create_cosmos_client(args.account_url)
        
        # Load and prepare document data
        logger.info(f"Loading data from file: {args.filename}")
        with open(args.filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Add deployment timestamp
        current_datetime = datetime.now()
        data['deploy_datetime'] = current_datetime.isoformat()
        
        # Add partition key if specified
        if args.partition_key:
            data['partitionKey'] = args.partition_key
        
        # Upsert the document
        logger.info("Uploading document to CosmosDB...")
        result = upsert_document(client, args.dbname, args.containername, data)
        
        logger.info("Document upload completed successfully")
        print(f"Document uploaded with ID: {result['id']}")
        
    except KeyboardInterrupt:
        logger.info("Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Upload failed: {e}")
        sys.exit(1)