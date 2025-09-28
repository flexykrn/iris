#!/usr/bin/env python3
"""
ESP32-CAM IP Discovery Script for MCA-WR-2 Network
This script helps find the IP address of your ESP32-CAM when connected to MCA-WR-2 WiFi
"""

import socket
import threading
import time
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

def scan_port(ip, port, timeout=1):
    """Scan a specific port on an IP address"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, 80))
        sock.close()
        return result == 0
    except:
        return False

def test_esp32_camera(ip):
    """Test if an IP is running ESP32 camera service"""
    try:
        # Test capture endpoint
        response = requests.get(f'http://{ip}/capture', timeout=3)
        if response.status_code == 200 and 'image' in response.headers.get('content-type', ''):
            return True
    except:
        pass
    return False

def get_local_network():
    """Get the local network range"""
    try:
        # Get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        
        # Extract network prefix (assuming /24)
        network_parts = local_ip.split('.')
        network_prefix = '.'.join(network_parts[:3])
        return f"{network_prefix}.0/24"
    except:
        return "192.168.0.0/24"  # Fallback

def scan_network():
    """Scan the local network for ESP32 cameras"""
    print("🔍 Scanning MCA-WR-2 network for ESP32-CAM...")
    print("=" * 50)
    
    # Get network range
    network = get_local_network()
    network_prefix = network.split('.')[0:3]
    base_ip = '.'.join(network_prefix)
    
    print(f"Scanning network: {base_ip}.1-254")
    print("This may take a few minutes...")
    print()
    
    found_ips = []
    
    # Scan all IPs in the range
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = []
        
        for i in range(1, 255):
            ip = f"{base_ip}.{i}"
            future = executor.submit(scan_port, ip, 80, 1)
            futures.append((future, ip))
        
        # Check results
        for future, ip in futures:
            if future.result():
                print(f"✅ Found device at {ip} (port 80 open)")
                found_ips.append(ip)
    
    print(f"\n📊 Found {len(found_ips)} devices with port 80 open")
    
    # Test each found IP for ESP32 camera
    esp32_cameras = []
    print("\n🤖 Testing for ESP32-CAM services...")
    
    for ip in found_ips:
        print(f"Testing {ip}...", end=" ")
        if test_esp32_camera(ip):
            print("✅ ESP32-CAM found!")
            esp32_cameras.append(ip)
        else:
            print("❌ Not ESP32-CAM")
    
    return esp32_cameras

def test_esp32_connection(ip):
    """Test connection to ESP32 camera"""
    print(f"\n🔗 Testing ESP32-CAM at {ip}")
    print("-" * 30)
    
    try:
        # Test capture endpoint
        response = requests.get(f'http://{ip}/capture', timeout=5)
        if response.status_code == 200:
            print(f"✅ Capture endpoint working")
            print(f"   Image size: {len(response.content)} bytes")
            print(f"   Content type: {response.headers.get('content-type', 'Unknown')}")
            
            # Test stream endpoint
            try:
                stream_response = requests.get(f'http://{ip}/stream', timeout=3)
                if stream_response.status_code == 200:
                    print(f"✅ Stream endpoint working")
                else:
                    print(f"⚠️  Stream endpoint returned: {stream_response.status_code}")
            except:
                print(f"⚠️  Stream endpoint not accessible")
            
            return True
        else:
            print(f"❌ Capture endpoint error: {response.status_code}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Connection timeout")
        return False
    except requests.exceptions.ConnectionError:
        print("❌ Connection failed")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Main function"""
    print("ESP32-CAM IP Discovery for MCA-WR-2 Network")
    print("=" * 50)
    print("Make sure your ESP32-CAM is connected to MCA-WR-2 WiFi")
    print("and your computer is also on the same network.")
    print()
    
    # Scan for ESP32 cameras
    esp32_cameras = scan_network()
    
    if not esp32_cameras:
        print("\n❌ No ESP32-CAM devices found on the network")
        print("\n💡 Troubleshooting tips:")
        print("   - Make sure ESP32-CAM is connected to MCA-WR-2 WiFi")
        print("   - Check if your computer is on the same network")
        print("   - Verify ESP32-CAM sketch is uploaded and running")
        print("   - Check Serial Monitor for ESP32 IP address")
        return
    
    print(f"\n🎉 Found {len(esp32_cameras)} ESP32-CAM device(s):")
    for i, ip in enumerate(esp32_cameras, 1):
        print(f"   {i}. {ip}")
    
    # Test each found camera
    working_cameras = []
    for ip in esp32_cameras:
        if test_esp32_connection(ip):
            working_cameras.append(ip)
    
    if working_cameras:
        print(f"\n✅ {len(working_cameras)} working ESP32-CAM device(s) found:")
        for ip in working_cameras:
            print(f"   - {ip}")
        
        print(f"\n📱 Update your Flutter app with:")
        print(f"   ESP32 Camera URL: http://{working_cameras[0]}/capture")
        print(f"   ESP32 Stream URL: http://{working_cameras[0]}/stream")
        
        print(f"\n🔧 Or update the settings in your app:")
        print(f"   1. Open Iris app")
        print(f"   2. Go to Settings")
        print(f"   3. ESP32 Camera section")
        print(f"   4. Enter: http://{working_cameras[0]}/capture")
        print(f"   5. Tap 'Configure ESP32 Camera'")
    else:
        print("\n❌ No working ESP32-CAM devices found")
        print("Check the troubleshooting tips above.")

if __name__ == '__main__':
    main()
