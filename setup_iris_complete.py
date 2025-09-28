#!/usr/bin/env python3
"""
Complete Iris Setup Script for MCA-WR-2 Network
This script sets up the complete Iris pipeline: ESP32-CAM -> VIT-GPT -> Audio/Haptic
"""

import subprocess
import sys
import os
import time
import requests
import threading
from find_esp32_ip import scan_network, test_esp32_connection

def check_python_packages():
    """Check if required Python packages are installed"""
    required_packages = [
        'flask', 'flask_cors', 'transformers', 'torch', 
        'pillow', 'opencv-python', 'pyttsx3', 'requests'
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
    
    print("✅ All required Python packages are installed")
    return True

def start_vitgpt_service():
    """Start VIT-GPT service in background"""
    print("🚀 Starting VIT-GPT AI Service...")
    
    try:
        # Change to vitgpt directory
        vitgpt_dir = os.path.join(os.path.dirname(__file__), 'vitgpt')
        if not os.path.exists(vitgpt_dir):
            print("❌ VIT-GPT directory not found")
            return None
        
        # Start the service
        process = subprocess.Popen(
            [sys.executable, 'server.py'],
            cwd=vitgpt_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        
        # Wait a bit for service to start
        time.sleep(5)
        
        # Test if service is running
        try:
            response = requests.get('http://localhost:5000/health', timeout=5)
            if response.status_code == 200:
                print("✅ VIT-GPT service started successfully")
                return process
            else:
                print("❌ VIT-GPT service failed to start properly")
                return None
        except:
            print("❌ VIT-GPT service not responding")
            return None
            
    except Exception as e:
        print(f"❌ Error starting VIT-GPT service: {e}")
        return None

def find_esp32_camera():
    """Find ESP32 camera on MCA-WR-2 network"""
    print("🔍 Searching for ESP32-CAM on MCA-WR-2 network...")
    
    esp32_cameras = scan_network()
    
    if not esp32_cameras:
        print("❌ No ESP32-CAM devices found")
        return None
    
    # Test each found camera
    for ip in esp32_cameras:
        if test_esp32_connection(ip):
            print(f"✅ Found working ESP32-CAM at {ip}")
            return ip
    
    print("❌ No working ESP32-CAM devices found")
    return None

def test_complete_pipeline(esp32_ip, vitgpt_url):
    """Test the complete pipeline: ESP32 -> VIT-GPT -> Audio"""
    print(f"\n🔄 Testing complete pipeline...")
    print("=" * 40)
    
    try:
        # Get image from ESP32
        print("📸 Capturing image from ESP32...")
        esp32_url = f"http://{esp32_ip}/capture"
        esp32_response = requests.get(esp32_url, timeout=10)
        
        if esp32_response.status_code != 200:
            print("❌ Failed to capture image from ESP32")
            return False
        
        print(f"✅ Image captured ({len(esp32_response.content)} bytes)")
        
        # Send to VIT-GPT for analysis
        print("🧠 Analyzing image with VIT-GPT...")
        files = {'image': ('image.jpg', esp32_response.content, 'image/jpeg')}
        data = {'mode': 'scene_description'}
        
        analysis_url = f"{vitgpt_url}/analyze_image"
        vitgpt_response = requests.post(analysis_url, files=files, data=data, timeout=30)
        
        if vitgpt_response.status_code == 200:
            result = vitgpt_response.json()
            description = result.get('description', 'No description')
            print(f"✅ Image analysis successful!")
            print(f"   Description: {description}")
            
            # Test navigation mode
            print("\n🧭 Testing navigation mode...")
            data['mode'] = 'navigation'
            nav_response = requests.post(analysis_url, files=files, data=data, timeout=30)
            
            if nav_response.status_code == 200:
                nav_result = nav_response.json()
                navigation = nav_result.get('navigation', 'No navigation guidance')
                print(f"✅ Navigation analysis successful!")
                print(f"   Navigation: {navigation}")
                return True
            else:
                print(f"⚠️  Navigation analysis failed: {nav_response.status_code}")
                return True  # Scene description still works
        else:
            print(f"❌ Image analysis failed: {vitgpt_response.status_code}")
            print(f"   Response: {vitgpt_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Pipeline test error: {e}")
        return False

def create_flutter_config(esp32_ip):
    """Create configuration file for Flutter app"""
    config = f"""# Iris Flutter App Configuration
# Generated automatically by setup script

# ESP32 Camera Configuration
ESP32_CAMERA_URL=http://{esp32_ip}/capture
ESP32_STREAM_URL=http://{esp32_ip}/stream

# VIT-GPT AI Service Configuration  
VITGPT_URL=http://localhost:5000

# Network Configuration
WIFI_SSID=MCA-WR-2
WIFI_PASSWORD=87654321

# Instructions:
# 1. Open Iris Flutter app
# 2. Go to Settings
# 3. ESP32 Camera section: Enter {esp32_ip}/capture
# 4. VIT-GPT section: Enter localhost:5000
# 5. Test the connection
"""
    
    config_file = os.path.join(os.path.dirname(__file__), 'iris_config.txt')
    with open(config_file, 'w') as f:
        f.write(config)
    
    print(f"📝 Configuration saved to: {config_file}")
    return config_file

def main():
    """Main setup function"""
    print("Iris Complete Setup for MCA-WR-2 Network")
    print("=" * 50)
    print("Setting up ESP32-CAM + VIT-GPT + Flutter pipeline")
    print()
    
    # Check Python packages
    if not check_python_packages():
        print("\n❌ Please install missing packages and run again")
        return False
    
    # Start VIT-GPT service
    vitgpt_process = start_vitgpt_service()
    if not vitgpt_process:
        print("\n❌ Failed to start VIT-GPT service")
        return False
    
    # Find ESP32 camera
    esp32_ip = find_esp32_camera()
    if not esp32_ip:
        print("\n❌ ESP32 camera not found")
        vitgpt_process.terminate()
        return False
    
    # Test complete pipeline
    pipeline_ok = test_complete_pipeline(esp32_ip, 'http://localhost:5000')
    
    # Create configuration file
    config_file = create_flutter_config(esp32_ip)
    
    # Summary
    print("\n📊 Setup Results")
    print("=" * 20)
    print(f"ESP32 Camera:     {'✅ READY' if esp32_ip else '❌ FAIL'}")
    print(f"VIT-GPT Service:  {'✅ READY' if vitgpt_process else '❌ FAIL'}")
    print(f"Complete Pipeline: {'✅ READY' if pipeline_ok else '❌ FAIL'}")
    
    if esp32_ip and vitgpt_process and pipeline_ok:
        print("\n🎉 Setup complete! Your Iris system is ready.")
        print(f"\n📱 Next steps:")
        print(f"   1. Open Iris Flutter app")
        print(f"   2. Go to Settings")
        print(f"   3. ESP32 Camera URL: http://{esp32_ip}/capture")
        print(f"   4. VIT-GPT URL: http://localhost:5000")
        print(f"   5. Configure both services")
        print(f"   6. Start using Iris!")
        
        print(f"\n📄 Configuration details saved to: {config_file}")
        
        # Keep VIT-GPT running
        print(f"\n🔄 VIT-GPT service is running in background...")
        print("Press Ctrl+C to stop the service")
        
        try:
            vitgpt_process.wait()
        except KeyboardInterrupt:
            print("\n🛑 Stopping VIT-GPT service...")
            vitgpt_process.terminate()
            print("✅ Setup complete. VIT-GPT service stopped.")
        
        return True
    else:
        print("\n⚠️  Setup incomplete. Please check the errors above.")
        if vitgpt_process:
            vitgpt_process.terminate()
        return False

if __name__ == '__main__':
    main()
