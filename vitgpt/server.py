from flask import Flask, request, jsonify
from flask_cors import CORS
import cv2
import time
import pyttsx3
import requests
import numpy as np
from PIL import Image
from transformers import pipeline
import io
import base64

app = Flask(__name__)
CORS(app)

# Load image captioning model
print("Loading VIT-GPT model...")
pipe = pipeline("image-to-text", model="nlpconnect/vit-gpt2-image-captioning")
print("Model loaded successfully!")

# Initialize text-to-speech engine
def initialize_tts_engine():
    """Initialize and configure TTS engine with proper settings"""
    try:
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
    except Exception as e:
        print(f"TTS initialization error: {e}")
        return None

# Global TTS engine
tts_engine = initialize_tts_engine()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'VIT-GPT AI Service',
        'model': 'nlpconnect/vit-gpt2-image-captioning',
        'timestamp': time.time()
    })

@app.route('/info', methods=['GET'])
def get_info():
    """Get service information"""
    return jsonify({
        'service': 'VIT-GPT AI Service',
        'model': 'nlpconnect/vit-gpt2-image-captioning',
        'version': '1.0.0',
        'capabilities': ['image_captioning', 'scene_description', 'navigation_guidance'],
        'status': 'running'
    })

@app.route('/analyze_image', methods=['POST'])
def analyze_image():
    """Analyze uploaded image and return description based on mode"""
    try:
        print(f"Received request with {len(request.files)} files")
        
        if 'image' not in request.files:
            print("No image file in request")
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            print("Empty filename")
            return jsonify({'error': 'No image file selected'}), 400
        
        # Get mode parameter
        mode = request.form.get('mode', 'scene_description')
        print(f"Processing mode: {mode}")
        
        # Read image data
        image_data = file.read()
        print(f"Image data size: {len(image_data)} bytes")
        
        # Convert to PIL Image
        image = Image.open(io.BytesIO(image_data))
        print(f"Image opened: {image.size}, mode: {image.mode}")
        
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
            print(f"Converted to RGB: {image.size}")
        
        print(f"Analyzing image in {mode} mode: {image.size}")
        
        # Get caption from VIT-GPT model
        result = pipe(image)
        print(f"Model result: {result}")
        
        caption = None
        if result and len(result) > 0 and 'generated_text' in result[0]:
            caption = result[0]['generated_text']
            print(f"Generated caption: {caption}")
        else:
            caption = "Scene unclear or image processing failed"
            print("No caption generated")
        
        # Process based on mode
        if mode == 'scene_description':
            response_data = {
                'description': caption,
                'mode': 'scene_description',
                'confidence': 0.8,
                'timestamp': time.time()
            }
            print(f"Returning scene description: {response_data}")
            return jsonify(response_data)
        elif mode == 'navigation':
            navigation = generate_navigation_guidance(caption)
            response_data = {
                'navigation': navigation,
                'description': caption,
                'mode': 'navigation',
                'confidence': 0.8,
                'timestamp': time.time()
            }
            print(f"Returning navigation: {response_data}")
            return jsonify(response_data)
        else:
            response_data = {
                'description': caption,
                'mode': 'unknown',
                'confidence': 0.8,
                'timestamp': time.time()
            }
            print(f"Returning unknown mode: {response_data}")
            return jsonify(response_data)
        
    except Exception as e:
        print(f"Error analyzing image: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Failed to analyze image: {str(e)}'}), 500

def generate_navigation_guidance(description):
    """Generate navigation guidance from scene description"""
    lower_desc = description.lower()
    
    if 'door' in lower_desc or 'entrance' in lower_desc:
        return 'There appears to be a door or entrance ahead. Move forward carefully.'
    elif 'stairs' in lower_desc or 'step' in lower_desc:
        return 'Stairs detected. Proceed with caution and use handrails if available.'
    elif 'wall' in lower_desc or 'obstacle' in lower_desc:
        return 'Obstacle detected ahead. Consider changing direction or stopping.'
    elif 'path' in lower_desc or 'walkway' in lower_desc:
        return 'Clear path detected. You can proceed forward safely.'
    elif 'person' in lower_desc or 'people' in lower_desc:
        return 'People detected in the area. Be aware of your surroundings.'
    else:
        return f'Continue with caution. The area appears to be: {description}'

@app.route('/speak', methods=['POST'])
def speak_text():
    """Convert text to speech"""
    try:
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        if tts_engine:
            tts_engine.say(text)
            tts_engine.runAndWait()
            return jsonify({'status': 'success', 'message': 'Text spoken successfully'})
        else:
            return jsonify({'error': 'TTS engine not available'}), 500
            
    except Exception as e:
        print(f"TTS error: {e}")
        return jsonify({'error': f'TTS failed: {str(e)}'}), 500

if __name__ == '__main__':
    print("Starting VIT-GPT AI Service...")
    print("Make sure to install required packages:")
    print("pip install flask flask-cors transformers torch pillow opencv-python pyttsx3")
    print("Service will be available at: http://localhost:5000")
    print("Health check: http://localhost:5000/health")
    print("Service info: http://localhost:5000/info")
    app.run(host='0.0.0.0', port=5000, debug=True)
