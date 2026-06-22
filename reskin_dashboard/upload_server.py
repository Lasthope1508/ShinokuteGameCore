import os
import json
import shutil
import subprocess
import urllib.request
import urllib.parse
from http.server import HTTPServer, SimpleHTTPRequestHandler
import boto3
from botocore.config import Config

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

# R2 configuration
R2_ENDPOINT = "https://842caa227e68a58c2c5ec2532d8022d0.r2.cloudflarestorage.com"
R2_ACCESS_KEY = "2da0a183e73f9394edbc25cf9741cf96"
R2_SECRET_KEY = "ae3acdf9dc3bfde0b262fd95f49215ddde0092a3b665902bdd1350f028f69dee"
R2_BUCKET = "0510-6893f1e40b"
R2_PUBLIC_URL_BASE = "https://6893f1e40b.image-hosting.uk"

# Firebase configuration
FIREBASE_BUCKET = "foodapp-7ff6b.firebasestorage.app"

def get_firebase_token() -> str:
    firebase_bin = shutil.which("firebase") or shutil.which("firebase.cmd")
    if not firebase_bin:
        raise RuntimeError("Firebase CLI executable not found on PATH. Please install Firebase CLI.")
    
    try:
        output = subprocess.check_output([firebase_bin, "login:list", "--json"], text=True)
        payload = json.loads(output)
        result = payload.get("result") or []
        if not result:
            raise RuntimeError("No Firebase CLI login found. Run 'firebase login' first.")
        token = result[0].get("tokens", {}).get("access_token")
        if not token:
            raise RuntimeError("Firebase CLI login has no access_token.")
        return token
    except Exception as e:
        raise RuntimeError(f"Failed to get Firebase token: {e}")

def upload_to_r2(file_bytes: bytes, object_name: str, content_type: str) -> str:
    s3 = boto3.client(
        "s3",
        endpoint_url=R2_ENDPOINT,
        aws_access_key_id=R2_ACCESS_KEY,
        aws_secret_access_key=R2_SECRET_KEY,
        config=Config(signature_version="s3v4")
    )
    s3.put_object(
        Bucket=R2_BUCKET,
        Key=object_name,
        Body=file_bytes,
        ContentType=content_type
    )
    return f"{R2_PUBLIC_URL_BASE}/{object_name}"

def upload_to_firebase(file_bytes: bytes, object_name: str, content_type: str, token: str) -> str:
    encoded_name = urllib.parse.quote(object_name, safe='')
    url = f"https://firebasestorage.googleapis.com/v0/b/{FIREBASE_BUCKET}/o?name={encoded_name}&uploadType=media"
    
    req = urllib.request.Request(
        url,
        data=file_bytes,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": content_type
        },
        method="POST"
    )
    
    with urllib.request.urlopen(req) as resp:
        res_data = json.loads(resp.read().decode('utf-8'))
        download_token = res_data.get("downloadTokens")
        if isinstance(download_token, list) and download_token:
            download_token = download_token[0]
        
        public_url = f"https://firebasestorage.googleapis.com/v0/b/{FIREBASE_BUCKET}/o/{encoded_name}?alt=media"
        if download_token:
            public_url += f"&token={download_token}"
        return public_url

class UploadDashboardHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-File-Name, X-Target-Storage')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_POST(self):
        if self.path.startswith('/api/upload'):
            # Parse query params or headers
            parsed_url = urllib.parse.urlparse(self.path)
            query_params = urllib.parse.parse_qs(parsed_url.query)
            
            # Read filename, content type, target
            filename = query_params.get('name', [''])[0]
            target = query_params.get('target', ['both'])[0]
            
            content_length = int(self.headers.get('Content-Length', 0))
            content_type = self.headers.get('Content-Type', 'application/octet-stream')
            
            if not filename:
                self.send_error_response("Missing 'name' query parameter.")
                return
            
            try:
                # Read file data from request body
                file_bytes = self.rfile.read(content_length)
                
                # Determine R2 prefix based on content type
                if content_type.startswith('image/'):
                    r2_key = f"images/{filename}"
                elif content_type.startswith('audio/'):
                    r2_key = f"audio/{filename}"
                else:
                    r2_key = f"uploads/{filename}"
                
                fb_key = f"uploads/{filename}"
                
                r2_url = None
                firebase_url = None
                errors = []
                
                # Perform R2 upload
                if target in ['r2', 'both']:
                    try:
                        r2_url = upload_to_r2(file_bytes, r2_key, content_type)
                    except Exception as e:
                        errors.append(f"R2 Upload error: {str(e)}")
                
                # Perform Firebase upload
                if target in ['firebase', 'both']:
                    try:
                        token = get_firebase_token()
                        firebase_url = upload_to_firebase(file_bytes, fb_key, content_type, token)
                    except Exception as e:
                        errors.append(f"Firebase Upload error: {str(e)}")
                
                if errors and not r2_url and not firebase_url:
                    self.send_error_response("; ".join(errors))
                    return
                
                response_payload = {
                    "success": True,
                    "r2Url": r2_url,
                    "firebaseUrl": firebase_url,
                    "errors": errors if errors else None
                }
                
                self.send_json_response(response_payload)
                
            except Exception as e:
                self.send_error_response(f"General Upload Failure: {str(e)}")
        else:
            self.send_error(404, "Not Found")

    def send_json_response(self, data: dict):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))

    def send_error_response(self, message: str):
        self.send_response(400)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({
            "success": False,
            "error": message
        }).encode('utf-8'))

def run_server():
    server_address = ('', PORT)
    httpd = HTTPServer(server_address, UploadDashboardHandler)
    print(f"reskin_dashboard server started on http://localhost:{PORT}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server...")
        httpd.server_close()

if __name__ == '__main__':
    run_server()
