import os
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
from flask import Flask, request, jsonify, send_file, abort, Response
from azure.identity import DefaultAzureCredential
from approaches.versioncheck import versionCheck

# Replace these with your own values, either in environment variables or directly here
AZURE_COSMOS_ENDPOINT = os.environ.get("AZURE_COSMOS_ENDPOINT") or "AZURE_COSMOS_ENDPOINT"
AZURE_COSMOS_DATABASE_NAME = os.environ.get("AZURE_COSMOS_DATABASE_NAME") or "AZURE_COSMOS_DATABASE_NAME"
AZURE_COSMOS_ABOUT_COLLECTION = os.environ.get("AZURE_COSMOS_ABOUT_COLLECTION") or "AZURE_COSMOS_ABOUT_COLLECTION"
AZURE_COSMOS_ALERT_COLLECTION = os.environ.get("AZURE_COSMOS_ALERT_COLLECTION") or "AZURE_COSMOS_ALERT_COLLECTION"
AZURE_COSMOS_CONNECTION_STRING = os.environ.get("AZURE_COSMOS_CONNECTION_STRING") or "AZURE_COSMOS_CONNECTION_STRING"

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
                            AZURE_COSMOS_CONNECTION_STRING)
}


app = Flask(__name__)

@app.route("/", defaults={"path": "index.html"})
@app.route("/<path:path>")
def static_file(path):
    return app.send_static_file(path)


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