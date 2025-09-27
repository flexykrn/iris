import cv2
import time
import pyttsx3
import requests
import numpy as np
from PIL import Image
from transformers import pipeline

# Load image captioning model
pipe = pipeline("image-to-text", model="nlpconnect/vit-gpt2-image-captioning")

# Initialize text-to-speech engine with proper setup function
def initialize_tts_engine():
    """Initialize and configure TTS engine with proper settings"""
    engine = pyttsx3.init()
    engine.setProperty('rate', 150)
    engine.setProperty('volume', 0.8)
    
    # Set voice if available
    voices = engine.getProperty('voices')
    if voices:
        for voice in voices:
            if 'female' in voice.name.lower() or 'zira' in voice.name.lower():
                engine.setProperty('voice', voice.id)
                break
        else:
            engine.setProperty('voice', voices[0].id)
    
    return engine

def speak_text(text):
    """Speak text using a fresh TTS engine instance"""
    try:
        # Create a new engine instance for each speech
        engine = initialize_tts_engine()
        engine.say(text)
        engine.runAndWait()
        engine.stop()
        # Clean up
        del engine
        return True
    except Exception as e:
        print(f"TTS Error: {e}")
        return False

ESP32_CAPTURE_URL = "http://192.168.0.144/capture"

def capture_image_from_url(url, timeout=10, max_retries=3):
    for attempt in range(max_retries):
        try:
            print(f"Capturing image (attempt {attempt + 1}/{max_retries})...")
            response = requests.get(url, timeout=timeout)
            if response.status_code == 200:
                image_array = np.frombuffer(response.content, np.uint8)
                frame = cv2.imdecode(image_array, cv2.IMREAD_COLOR)
                if frame is not None:
                    print("Successfully captured image from ESP32")
                    return frame
                else:
                    print("Failed to decode image")
            else:
                print(f"HTTP Error: {response.status_code}")
        except requests.exceptions.Timeout:
            print(f"Timeout occurred (attempt {attempt + 1})")
        except requests.exceptions.ConnectionError:
            print(f"Connection error (attempt {attempt + 1})")
        except Exception as e:
            print(f"Error capturing image: {e}")
        if attempt < max_retries - 1:
            print("Retrying in 2 seconds...")
            time.sleep(2)
    return None

# Test initial connection
print("Testing ESP32 camera connection...")
test_frame = capture_image_from_url(ESP32_CAPTURE_URL)
if test_frame is None:
    print("Failed to connect to ESP32 camera. Please check the URL and network connection.")
    exit()

print("ESP32 camera connected successfully!")
print("Starting image capture and analysis. Press Ctrl+C to quit.")
print("Audio announcements will play every 3 captured images.")
print("System ready for visual assistance.")

capture_count = 0
failed_captures = 0
max_failed_captures = 5
tts_announcement_interval = 3  # Announce every 3rd caption

try:
    while True:
        frame = capture_image_from_url(ESP32_CAPTURE_URL, timeout=15)
        
        if frame is None:
            failed_captures += 1
            print(f"Failed to capture image ({failed_captures}/{max_failed_captures})")
            if failed_captures >= max_failed_captures:
                print("Too many failed captures. Retrying in 5 seconds...")
                time.sleep(5)
                failed_captures = 0
            else:
                time.sleep(2)
            continue

        failed_captures = 0
        capture_count += 1
        cv2.imshow("ESP32 Captured Image", frame)

        try:
            print(f"Analyzing captured image #{capture_count}...")
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            pil_image = Image.fromarray(rgb_frame)
            result = pipe(pil_image)

            caption = None
            if result and len(result) > 0 and 'generated_text' in result[0]:
                caption = result[0]['generated_text']
                print(f"Caption (capture #{capture_count}): {caption}")
            else:
                print("No caption generated")
                caption = "Scene unclear or image processing failed"

            # Always announce every 3rd capture
            if capture_count % tts_announcement_interval == 0:
                print(f"Speaking caption (announcement #{capture_count // tts_announcement_interval})...")
                # Create accessibility-friendly announcement
                accessible_text = f"Scene description: {caption}"
                success = speak_text(accessible_text)
                if success:
                    print("Finished speaking caption")
                else:
                    print("Failed to speak caption")
            else:
                remaining = tts_announcement_interval - (capture_count % tts_announcement_interval)
                print(f"Caption displayed (audio in {remaining} capture(s))")

        except Exception as e:
            print(f"Error analyzing image: {e}")
            if capture_count % tts_announcement_interval == 0:
                success = speak_text("Unable to analyze current image")
                if success:
                    print("Finished speaking error message")
                else:
                    print("Failed to speak error message")

        # Wait before next capture
        time.sleep(0.5)

        key = cv2.waitKey(1) & 0xFF
        if key == ord('q'):
            break

except KeyboardInterrupt:
    print("\nProgram interrupted by user")

print("Cleaning up...")
cv2.destroyAllWindows()
print("Goodbye!")
