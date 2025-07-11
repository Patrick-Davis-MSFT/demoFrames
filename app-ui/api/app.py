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
# AZURE_FUNCTIONS_ENDPOINT = "https://j4k30g3c-7277.use.devtunnels.ms/api/" 


# Replace these with your own values, either in environment variables or directly here
AZURE_COSMOS_ENDPOINT = os.environ.get("AZURE_COSMOS_ENDPOINT", "AZURE_COSMOS_ENDPOINT") or "AZURE_COSMOS_ENDPOINT"
AZURE_COSMOS_DATABASE_NAME = os.environ.get("AZURE_COSMOS_DATABASE_NAME","AZURE_COSMOS_DATABASE_NAME") or "AZURE_COSMOS_DATABASE_NAME"
AZURE_COSMOS_ABOUT_COLLECTION = os.environ.get("AZURE_COSMOS_ABOUT_COLLECTION","AZURE_COSMOS_ABOUT_COLLECTION") or "AZURE_COSMOS_ABOUT_COLLECTION"
AZURE_COSMOS_CONNECTION_STRING = os.environ.get("AZURE_COSMOS_CONNECTION_STRING", "AZURE_COSMOS_CONNECTION_STRING") or "AZURE_COSMOS_CONNECTION_STRING"

# Use the current user identity to authenticate with Azure OpenAI, Cognitive Search and Blob Storage (no secrets needed, 
# just use 'az login' locally, and managed identity when deployed on Azure). If you need to use keys, use separate AzureKeyCredential instances with the 
# keys for each service
# If you encounter a blocking error during a DefaultAzureCredntial resolution, you can exclude the problematic credential by using a parameter (ex. exclude_shared_token_cache_credential=True)
#logging.basicConfig(level=logging.DEBUG)
#azure_credential = DefaultAzureCredential(exclude_shared_token_cache_credential = True, logging_enable=True)
azure_credential = DefaultAzureCredential(exclude_shared_token_cache_credential = True)


# Approach to get 
indexFiles_approaches = {
    "ver": versionCheck(AZURE_COSMOS_ENDPOINT,
                            AZURE_COSMOS_DATABASE_NAME, 
                            AZURE_COSMOS_ABOUT_COLLECTION,
                            AZURE_COSMOS_CONNECTION_STRING),
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
        id = r["_id"]
        r["_id"] = str(id)
        return jsonify(r)
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
    