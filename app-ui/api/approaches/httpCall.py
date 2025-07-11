import os
import requests
import urllib.parse
import time
from azure.identity import DefaultAzureCredential


class httpCall():
    def __init__(self, httpFunctionEndpoint, functionKey):
        self.httpFunctionEndpoint = httpFunctionEndpoint
        self.functionKey = functionKey
        self.credential = DefaultAzureCredential()
    
    def get(self, uri, payload, headers={}, fullURI=False, useFunctionKey=True):
        if fullURI:
            url = uri
        else:
            url = urllib.parse.urljoin(self.httpFunctionEndpoint, uri)
        if useFunctionKey:
            headers['x-functions-key'] = self.functionKey
            print(f"Using function key for authentication")
        else:
            token = self.credential.get_token("https://management.azure.com/.default")
            headers['Authorization'] = f"Bearer {token.token}"
        print(f"get url: {url}")
        response = requests.get(url, headers=headers, data=payload)
        print(f"response: {response}")
        if response.content:
            return response.json()
        else:
            return []
    
    
    def post(self, uri, payload, headers={}, contentType=None, timeout=60):
        url = urllib.parse.urljoin(self.httpFunctionEndpoint, uri)
        print(f"post url: {url}")
        print(f"post payload: {payload}")
        print(f"post contentType: {contentType}")
        print(f"Timeout: {timeout}")
        headers['x-functions-key'] = self.functionKey
        
        # Start timing the request
        start_time = time.time()
        if (contentType == 'application/json'):
            headers['Content-Type'] = contentType
            response = requests.post(url, headers=headers, json=payload, timeout=timeout)
        else:
            response = requests.post(url, headers=headers, data=payload, timeout=timeout)
                # End timing the request
        end_time = time.time()
        elapsed_time = end_time - start_time
        print(f"Elapsed time for POST request: {elapsed_time} seconds")
        print (f"post response: {response}")
        # Check if the response is successful
        if response.status_code == 200:
            print("Request was successful.")
        else:
            print(f"Request failed with status code: {response.status_code}")
        return response.json()
    
    def put(self, uri, payload, headers={}):
        url = urllib.parse.urljoin(self.httpFunctionEndpoint, uri)
        headers['x-functions-key'] = self.functionKey
        response = requests.put(url, headers=headers, data=payload)
        return response.json()
    
    
    def delete(self, uri, payload, headers={}):
        url = urllib.parse.urljoin(self.httpFunctionEndpoint, uri)
        headers['x-functions-key'] = self.functionKey
        response = requests.delete(url, headers=headers, data=payload)
        print(f"delete response: {response}")
        return response.json()