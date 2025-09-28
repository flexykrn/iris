#!/usr/bin/env python3
"""
VIT-GPT AI Service Startup Script
This script starts the VIT-GPT AI service for the Iris vision assistant app.
"""

import subprocess
import sys
import os
import time

def check_dependencies():
    """Check if required packages are installed"""
    required_packages = [
        'flask', 'flask_cors', 'transformers', 'torch', 
        'pillow', 'opencv-python', 'pyttsx3'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print("❌ Missing required packages:")
        for package in missing_packages:
            print(f"   - {package}")
        print("\n📦 Install them with:")
        print(f"pip install {' '.join(missing_packages)}")
        return False
    
    print("✅ All required packages are installed")
    return True

def start_service():
    """Start the VIT-GPT service"""
    print("🚀 Starting VIT-GPT AI Service...")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not os.path.exists('server.py'):
        print("❌ server.py not found. Make sure you're in the vitgpt directory.")
        return False
    
    try:
        # Start the Flask server
        subprocess.run([sys.executable, 'server.py'], check=True)
    except KeyboardInterrupt:
        print("\n🛑 Service stopped by user")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error starting service: {e}")
        return False
    
    return True

def main():
    """Main function"""
    print("Iris VIT-GPT AI Service")
    print("=" * 30)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Start service
    start_service()

if __name__ == '__main__':
    main()
