
import json
from datetime import datetime
import os
import sys
import uuid
import argparse
from azure.core.exceptions import AzureError
from azure.cosmos import CosmosClient, PartitionKey
from pymongo import MongoClient

if __name__ == "__main__": 
    parser = argparse.ArgumentParser(description='Upload the value specified to the Cosmos DB container specified')
    parser.add_argument('-d', '--dbname', help='cosmos db name', required=True)
    parser.add_argument('-c', '--containername', help='cosmos container name', required=True)
    parser.add_argument('-k', '--konnectionString', help='Mongo Connection String', required=True)
    
    parser.add_argument('-f', '--filename', help='upsert file', required=True)

    args = parser.parse_args()
    # Set up the connection to Azure Cosmos DB
    client = MongoClient(args.konnectionString)

    # Create a database and container
    database_name = args.dbname
    container_name = args.containername
    database = client[database_name]
    collection = database[container_name]

    # Insert data into the container
    with open(args.filename) as f:
        data = json.load(f)
    # Get current date and time
    current_datetime = datetime.now()

    # Convert current date and time to a string
    current_datetime_str = current_datetime.isoformat()
    data['deploy_datetime'] = current_datetime_str
    collection.insert_one(data)