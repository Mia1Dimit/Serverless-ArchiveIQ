#!/usr/bin/env python3
"""
Build Agent Runtime Package

Creates archiveiq-agent.zip with all dependencies for AgentCore deployment.
Works on Windows, macOS, and Linux.
"""

import os
import sys
import shutil
import zipfile
import subprocess
import tempfile
from pathlib import Path

REGION = "eu-central-1"
BUCKET = "archiveiq-agentcore-runtime-dev"
ZIP_FILE = "archiveiq-agent.zip"

def main():
    print("Building agent package...")
    
    # Create temporary directory for build
    with tempfile.TemporaryDirectory() as build_dir:
        print(f"Installing dependencies to {build_dir}...")
        
        # Install dependencies
        try:
            subprocess.run(
                [sys.executable, "-m", "pip", "install", 
                 "-r", "requirements.txt", 
                 "--target", build_dir, 
                 "--quiet"],
                check=True,
                cwd=os.path.dirname(os.path.abspath(__file__))
            )
        except subprocess.CalledProcessError as e:
            print(f"Error installing dependencies: {e}")
            return 1
        
        print("Copying agent code...")
        shutil.copy("agent.py", os.path.join(build_dir, "agent.py"))
        
        print(f"Creating zip package: {ZIP_FILE}...")
        with zipfile.ZipFile(ZIP_FILE, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, dirs, files in os.walk(build_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, build_dir)
                    zf.write(file_path, arcname)
    
    # Check file size
    size_mb = os.path.getsize(ZIP_FILE) / (1024 * 1024)
    print(f"[OK] Created {ZIP_FILE} ({size_mb:.2f} MB)")
    
    # Upload to S3
    print(f"Uploading to s3://{BUCKET}/agent/{ZIP_FILE}...")
    try:
        subprocess.run(
            ["aws", "s3", "cp", ZIP_FILE, f"s3://{BUCKET}/agent/{ZIP_FILE}", 
             "--region", REGION, "--no-progress"],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Error uploading to S3: {e}")
        return 1
    
    print("[OK] Upload complete")
    print("")
    print("Ready to deploy with terraform apply")
    return 0

if __name__ == "__main__":
    sys.exit(main())
