import os
from werkzeug.utils import secure_filename
import io
import mimetypes
import time
import logging
import threading
import queue
import sys
import re
import base64
import html
from io import BytesIO
from flask import Flask, request, jsonify, send_file, abort, Response, send_from_directory
from azure.identity import DefaultAzureCredential
from approaches.versioncheck import versionCheck
from approaches.httpCall import httpCall

AZURE_FUNCTIONS_KEY = os.environ.get("AZURE_FUNCTION_APP_API_KEY", "AZURE_FUNCTION_APP_API_KEY") or "AZURE_FUNCTION_APP_API_KEY"
AZURE_FUNCTIONS_ENDPOINT = "https://" + (os.environ.get("AZURE_FUNCTION_APP_NAME", 'AZURE_FUNCTION_APP_NAME') or "AZURE_FUNCTION_APP_NAME") + ".azurewebsites.net/api/"
# Use dev tunnel for local testing
# AZURE_FUNCTIONS_ENDPOINT = "https://h4s9nq2s-7162.use.devtunnels.ms/api/" 


# Replace these with your own values, either in environment variables or directly here
AZURE_COSMOS_ACCOUNT_NAME = os.environ.get("AZURE_COSMOS_ACCOUNT_NAME", "AZURE_COSMOS_ACCOUNT_NAME") or "AZURE_COSMOS_ACCOUNT_NAME"
AZURE_COSMOS_ACCOUNT_URL = f"https://{AZURE_COSMOS_ACCOUNT_NAME}.documents.azure.com:443/"
AZURE_COSMOS_DATABASE_NAME = os.environ.get("AZURE_COSMOS_DATABASE_NAME","AZURE_COSMOS_DATABASE_NAME") or "AZURE_COSMOS_DATABASE_NAME"
AZURE_COSMOS_ABOUT_COLLECTION = os.environ.get("AZURE_COSMOS_ABOUT_COLLECTION","AZURE_COSMOS_ABOUT_COLLECTION") or "AZURE_COSMOS_ABOUT_COLLECTION"

# Use the current user identity to authenticate with Azure OpenAI, Cognitive Search and Blob Storage (no secrets needed, 
# just use 'az login' locally, and managed identity when deployed on Azure). If you need to use keys, use separate AzureKeyCredential instances with the 
# keys for each service
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
#logging.basicConfig(level=logging.DEBUG)
#azure_credential = DefaultAzureCredential(exclude_shared_token_cache_credential = True, logging_enable=True)
azure_credential = DefaultAzureCredential(exclude_shared_token_cache_credential = True)


# Approach to get version info using CosmosDB NoSQL with managed identity
indexFiles_approaches = {
    "ver": versionCheck(AZURE_COSMOS_ACCOUNT_URL,
                       AZURE_COSMOS_DATABASE_NAME, 
                       AZURE_COSMOS_ABOUT_COLLECTION),
    "httpCall": httpCall(AZURE_FUNCTIONS_ENDPOINT,
                         AZURE_FUNCTIONS_KEY),

}


# Configure Flask to serve static files from the React build directory
app = Flask(__name__, static_folder='./static', static_url_path='')

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def static_file(path):
    try:
        if path == "" or path == "index.html":
            # Serve index.html for root and direct requests
            return send_from_directory(app.static_folder, 'index.html')
        
        # Secure the filename to prevent directory traversal
        safe_path = secure_filename(path)
        
        # Check if file exists
        file_path = os.path.join(app.static_folder, safe_path)
        if os.path.exists(file_path):
            return send_from_directory(app.static_folder, safe_path)
        else:
            # For SPA routing, return index.html for non-API routes
            return send_from_directory(app.static_folder, 'index.html')  
    except Exception as e:
        logging.exception("Exception in static_file")
        # Fallback to index.html for SPA routing
        return send_from_directory(app.static_folder, 'index.html')


@app.route("/about")
def about():
    try:
        impl = indexFiles_approaches.get("ver")
        r = impl.run()
        
        if r:
            # CosmosDB NoSQL uses 'id' instead of '_id'
            # Convert id to string for JSON serialization if it exists
            if "id" in r:
                r["id"] = str(r["id"])
            return jsonify(r)
        else:
            # Return default values if no document found
            return jsonify({
                "appName": "Demo Frames Blank",
                "appVersion": "0.0.1a", 
                "deploy_datetime": "Unknown",
                "message": "No version information available"
            })
            
    except Exception as e:
        logging.exception("Exception in /about")
        return jsonify({"error": str(e)}), 500

@app.route("/settings")
def setting():
    try:
        impl = indexFiles_approaches.get("setting")
        r = impl.run()
        id = r["_id"]
        r["_id"] = str(id)
        return jsonify(r)
    except Exception as e:
        logging.exception("Exception in /settings")
        return jsonify({"error": str(e)}), 500
    
@app.route("/health")
def health():
    return jsonify({"status": "healthy"})

@app.route("/heartbeatwebapp")
def heartbeatwebapp():
    try:
        impl = indexFiles_approaches.get("httpCall")
        r = impl.get(uri="Heartbeat", payload={})
        return jsonify(r)
    except Exception as e:
        logging.exception("Exception in /heartbeatwebapp")
        return jsonify({"error": str(e)}), 500
    