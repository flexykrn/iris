#!/usr/bin/env python3
"""
Simple ESP32 IP Finder for MCA-WR-2 Network
"""

import requests
import socket
import threading
from concurrent.futures import ThreadPoolExecutor

def test_ip(ip):
    """Test if an IP has ESP32 camera"""
    try:
        response = requests.get(f'http://{ip}/capture', timeout=2)
        if response.status_code == 200 and 'image' in response.headers.get('content-type', ''):
            return ip
    except:
        pass
    return None

def find_esp32():
    """Find ESP32 on MCA-WR-2 network"""
    print("🔍 Searching for ESP32-CAM on MCA-WR-2 network...")
    
    # Get local network
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        network = '.'.join(local_ip.split('.')[:3])
    except:
        network = '192.168.0'  # Fallback
    
    print(f"Scanning network: {network}.1-254")
    
    found_ips = []
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = []
        for i in range(1, 255):
            ip = f"{network}.{i}"
            futures.append(executor.submit(test_ip, ip))
        
        for future in futures:
            result = future.result()
            if result:
                found_ips.append(result)
    
    if found_ips:
        print(f"\n✅ Found ESP32-CAM at: {found_ips[0]}")
        print(f"📱 Update your Flutter app with:")
        print(f"   ESP32 URL: http://{found_ips[0]}/capture")
        return found_ips[0]
    else:
        print("\n❌ ESP32-CAM not found")
        print("Check:")
        print("- ESP32 is connected to MCA-WR-2 WiFi")
        print("- ESP32 sketch is uploaded")
        print("- Check Serial Monitor for IP address")
        return None

if __name__ == '__main__':
    find_esp32()
