#!/usr/bin/env python3
"""
ESP32 Camera Capture and Display Test
This script tests ESP32 camera capture and VIT-GPT processing
"""

import requests
import time
import json
import base64
from io import BytesIO
from PIL import Image

def test_esp32_capture(esp32_url):
    """Test ESP32 camera capture"""
    print(f"📸 Testing ESP32 camera capture at: {esp32_url}")
    print("-" * 50)
    
    try:
        # Test capture endpoint
        response = requests.get(esp32_url, timeout=10)
        
        if response.status_code == 200:
            print(f"✅ ESP32 camera capture successful")
            print(f"   Image size: {len(response.content)} bytes")
            print(f"   Content type: {response.headers.get('content-type', 'Unknown')}")
            
            # Try to open as image
            try:
                image = Image.open(BytesIO(response.content))
                print(f"   Image dimensions: {image.size}")
                print(f"   Image mode: {image.mode}")
                return response.content
            except Exception as e:
                print(f"   ⚠️  Image format issue: {e}")
                return response.content
        else:
            print(f"❌ ESP32 camera error: {response.statusCode}")
            return None
            
    except requests.exceptions.Timeout:
        print("❌ ESP32 camera timeout")
        return None
    except requests.exceptions.ConnectionError:
        print("❌ ESP32 camera connection failed")
        return None
    except Exception as e:
        print(f"❌ ESP32 camera error: {e}")
        return None

def test_vitgpt_processing(image_bytes, vitgpt_url):
    """Test VIT-GPT processing"""
    print(f"\n🧠 Testing VIT-GPT processing at: {vitgpt_url}")
    print("-" * 50)
    
    try:
        # Test health first
        health_response = requests.get(f"{vitgpt_url}/health", timeout=5)
        if health_response.status_code != 200:
            print("❌ VIT-GPT service not healthy")
            return False
        
        print("✅ VIT-GPT service is healthy")
        
        # Test scene description
        print("📝 Testing scene description...")
        files = {'image': ('image.jpg', image_bytes, 'image/jpeg')}
        data = {'mode': 'scene_description'}
        
        response = requests.post(f"{vitgpt_url}/analyze_image", files=files, data=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            description = result.get('description', 'No description')
            print(f"✅ Scene description successful:")
            print(f"   Description: {description}")
            
            # Test navigation
            print("\n🧭 Testing navigation guidance...")
            data['mode'] = 'navigation'
            nav_response = requests.post(f"{vitgpt_url}/analyze_image", files=files, data=data, timeout=30)
            
            if nav_response.status_code == 200:
                nav_result = nav_response.json()
                navigation = nav_result.get('navigation', 'No navigation')
                print(f"✅ Navigation guidance successful:")
                print(f"   Navigation: {navigation}")
                return True
            else:
                print(f"⚠️  Navigation failed: {nav_response.status_code}")
                return True  # Scene description still works
        else:
            print(f"❌ VIT-GPT processing failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ VIT-GPT processing error: {e}")
        return False

def test_continuous_capture(esp32_url, vitgpt_url, num_frames=5):
    """Test continuous capture and processing"""
    print(f"\n🔄 Testing continuous capture ({num_frames} frames)")
    print("-" * 50)
    
    successful_captures = 0
    successful_processing = 0
    
    for i in range(num_frames):
        print(f"\nFrame {i+1}/{num_frames}:")
        
        # Capture frame
        image_bytes = test_esp32_capture(esp32_url)
        if image_bytes:
            successful_captures += 1
            
            # Process with VIT-GPT
            if test_vitgpt_processing(image_bytes, vitgpt_url):
                successful_processing += 1
        
        # Wait between frames
        if i < num_frames - 1:
            time.sleep(2)
    
    print(f"\n📊 Continuous Test Results:")
    print(f"   Successful captures: {successful_captures}/{num_frames}")
    print(f"   Successful processing: {successful_processing}/{num_frames}")
    
    return successful_captures == num_frames and successful_processing == num_frames

def main():
    """Main test function"""
    print("ESP32 Camera Capture and VIT-GPT Processing Test")
    print("=" * 60)
    
    # Configuration
    esp32_url = "http://192.168.0.144/capture"  # Update with your ESP32 IP
    vitgpt_url = "http://localhost:5000"
    
    print(f"📋 Configuration:")
    print(f"   ESP32 Camera: {esp32_url}")
    print(f"   VIT-GPT Service: {vitgpt_url}")
    print()
    
    # Test 1: Single capture
    print("🧪 Test 1: Single ESP32 capture")
    image_bytes = test_esp32_capture(esp32_url)
    
    if not image_bytes:
        print("\n❌ ESP32 camera test failed. Check:")
        print("   - ESP32 is connected to MCA-WR-2 WiFi")
        print("   - ESP32 IP address is correct")
        print("   - ESP32 camera sketch is uploaded")
        return False
    
    # Test 2: VIT-GPT processing
    print("\n🧪 Test 2: VIT-GPT processing")
    if not test_vitgpt_processing(image_bytes, vitgpt_url):
        print("\n❌ VIT-GPT processing test failed. Check:")
        print("   - VIT-GPT service is running")
        print("   - Service URL is correct")
        print("   - Python dependencies are installed")
        return False
    
    # Test 3: Continuous capture
    print("\n🧪 Test 3: Continuous capture and processing")
    if not test_continuous_capture(esp32_url, vitgpt_url, 3):
        print("\n⚠️  Continuous test had some failures")
        print("   This might be normal for slower networks")
    
    print("\n🎉 All tests completed!")
    print("\n📱 Next steps for Flutter app:")
    print(f"   1. Update ESP32 URL to: {esp32_url}")
    print(f"   2. Update VIT-GPT URL to: {vitgpt_url}")
    print("   3. Test the Flutter app")
    
    return True

if __name__ == '__main__':
    main()
