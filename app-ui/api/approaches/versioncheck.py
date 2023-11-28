import os
from pymongo import MongoClient


class versionCheck():
    def __init__(self, cosmosEndpoint, cosmosDB, cosmosCollection, cosmosConnectionString):
        self.cosmosEndpoint = cosmosEndpoint
        self.cosmosDB = cosmosDB
        self.cosmosCollection = cosmosCollection
        self.cosmosConnectionString = cosmosConnectionString
        
    def run(self): 
        client = MongoClient(self.cosmosConnectionString)   
        # get a database and container
        database = client[self.cosmosDB]
        collection = database[self.cosmosCollection]
        document = collection.find_one(sort=[("deploy_datetime", -1)])
        return document
