#!/usr/bin/env python3
"""
ESP32 Camera Connection Test Script
This script tests the connection to your ESP32-CAM and VIT-GPT service.
"""

import requests
import time
import json
from urllib.parse import urlparse

def test_esp32_camera(esp32_url):
    """Test ESP32 camera connection"""
    print(f"🔍 Testing ESP32 Camera at: {esp32_url}")
    print("-" * 50)
    
    try:
        # Test capture endpoint
        response = requests.get(esp32_url, timeout=10)
        
        if response.status_code == 200:
            print("✅ ESP32 Camera is accessible")
            print(f"   Response size: {len(response.content)} bytes")
            print(f"   Content type: {response.headers.get('content-type', 'Unknown')}")
            return True
        else:
            print(f"❌ ESP32 Camera error: HTTP {response.status_code}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ ESP32 Camera timeout - check if device is connected to WiFi")
        return False
    except requests.exceptions.ConnectionError:
        print("❌ ESP32 Camera connection failed - check IP address and network")
        return False
    except Exception as e:
        print(f"❌ ESP32 Camera error: {e}")
        return False

def test_vitgpt_service(vitgpt_url):
    """Test VIT-GPT service connection"""
    print(f"\n🤖 Testing VIT-GPT Service at: {vitgpt_url}")
    print("-" * 50)
    
    try:
        # Test health endpoint
        health_url = f"{vitgpt_url}/health"
        response = requests.get(health_url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ VIT-GPT Service is running")
            print(f"   Service: {data.get('service', 'Unknown')}")
            print(f"   Model: {data.get('model', 'Unknown')}")
            print(f"   Status: {data.get('status', 'Unknown')}")
            return True
        else:
            print(f"❌ VIT-GPT Service error: HTTP {response.status_code}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ VIT-GPT Service timeout - check if service is running")
        return False
    except requests.exceptions.ConnectionError:
        print("❌ VIT-GPT Service connection failed - check if service is started")
        return False
    except Exception as e:
        print(f"❌ VIT-GPT Service error: {e}")
        return False

def test_image_analysis(esp32_url, vitgpt_url):
    """Test image analysis with ESP32 camera and VIT-GPT"""
    print(f"\n🖼️  Testing Image Analysis Pipeline")
    print("-" * 50)
    
    try:
        # Get image from ESP32
        print("📸 Capturing image from ESP32...")
        esp32_response = requests.get(esp32_url, timeout=10)
        
        if esp32_response.status_code != 200:
            print("❌ Failed to capture image from ESP32")
            return False
        
        # Send to VIT-GPT for analysis
        print("🧠 Analyzing image with VIT-GPT...")
        files = {'image': ('image.jpg', esp32_response.content, 'image/jpeg')}
        data = {'mode': 'scene_description'}
        
        analysis_url = f"{vitgpt_url}/analyze_image"
        vitgpt_response = requests.post(analysis_url, files=files, data=data, timeout=30)
        
        if vitgpt_response.status_code == 200:
            result = vitgpt_response.json()
            print("✅ Image analysis successful!")
            print(f"   Description: {result.get('description', 'No description')}")
            print(f"   Mode: {result.get('mode', 'Unknown')}")
            print(f"   Confidence: {result.get('confidence', 'Unknown')}")
            return True
        else:
            print(f"❌ Image analysis failed: HTTP {vitgpt_response.status_code}")
            print(f"   Response: {vitgpt_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Image analysis error: {e}")
        return False

def main():
    """Main test function"""
    print("Iris ESP32-CAM + VIT-GPT Integration Test")
    print("=" * 50)
    
    # Default URLs - update these with your actual IP addresses
    esp32_url = "http://192.168.0.144/capture"  # Update with your ESP32 IP on MCA-WR-2
    vitgpt_url = "http://localhost:5000"        # Update if VIT-GPT is on different host
    
    print("📋 Configuration:")
    print(f"   ESP32 Camera: {esp32_url}")
    print(f"   VIT-GPT Service: {vitgpt_url}")
    print()
    
    # Test ESP32 camera
    esp32_ok = test_esp32_camera(esp32_url)
    
    # Test VIT-GPT service
    vitgpt_ok = test_vitgpt_service(vitgpt_url)
    
    # Test complete pipeline if both services are working
    if esp32_ok and vitgpt_ok:
        pipeline_ok = test_image_analysis(esp32_url, vitgpt_url)
    else:
        pipeline_ok = False
    
    # Summary
    print("\n📊 Test Results Summary")
    print("=" * 30)
    print(f"ESP32 Camera:     {'✅ PASS' if esp32_ok else '❌ FAIL'}")
    print(f"VIT-GPT Service:  {'✅ PASS' if vitgpt_ok else '❌ FAIL'}")
    print(f"Image Pipeline:   {'✅ PASS' if pipeline_ok else '❌ FAIL'}")
    
    if pipeline_ok:
        print("\n🎉 All tests passed! Your setup is ready to use.")
    else:
        print("\n⚠️  Some tests failed. Please check the configuration.")
        print("\n💡 Troubleshooting tips:")
        if not esp32_ok:
            print("   - Check ESP32 WiFi connection")
            print("   - Verify ESP32 IP address")
            print("   - Make sure ESP32-CAM sketch is uploaded")
        if not vitgpt_ok:
            print("   - Start VIT-GPT service: python vitgpt/server.py")
            print("   - Check if port 5000 is available")
            print("   - Install required Python packages")

if __name__ == '__main__':
    main()
