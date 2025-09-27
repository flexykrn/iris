# Iris

Iris is a pair of AI-powered smart glasses designed to assist visually impaired individuals. Equipped with a ESP32-CAM Module Iris provides real-time audio descriptions of what the camera sees and helps with navigation.
Iris also has an AI-powered mobile application built to empower visually impaired users by transforming any smartphone into a real-time vision assistant. With advanced computer vision and natural language processing, Iris provides scene descriptions, obstacle and object recognition, and intuitive navigation guidance. The app ensures maximum accessibility through a blend of voice narration, haptic feedback, and enabling users to confidently explore and interact with their surroundings — anytime, anywhere.

<p align="center">
  <img src="https://raw.githubusercontent.com/flexykrn/iris/c6ecd40118f3ac9ac2b32c1cc80313d545233132/Iris.png" alt="Iris Logo" width="100%">
</p>

## 🚀 Features
👓 Smart Glasses Integration
- Camera attached to spectacles captures surroundings.

🧭 Navigation Mode Mobile App (Iris App) 📱
- Provides voice + haptic instructions for navigation. 
- Detects obstacles and guides step-by-step.
                   
✋ Gesture & Haptic Interaction 
-  Tap gestures for dashboard navigation

🎨 Simple UI
- Clean, responsive, and user-friendly design

🌆 Scene Description Mode
- Captures live feed and uses AI to describe surroundings.
- Outputs via Text-to-Speech + vibration feedback.

## 🏗️ Tech Stack

- Mobile App: Flutter (cross-platform, accessibility-first UI)
- AI Models (On-Device): 
- Vision AI: Hugging Face Inference API (BLIP, free tier)
- Voice Feedback: Android TTS API 
- Haptics: Native Android/iOS vibration APIs

## 💰 Cost Estimate

- On-device (Free): TensorFlow Lite, Tesseract, Flutter, Android APIs
- API (Optional): Hugging Face Inference API (Free tier: ~30k tokens/month)
- Total: 💸 0/- for prototyping; scalable with paid tiers.

## 🌍 Impact

- Enables independence and confidence for visually impaired individuals.
- Works offline or online, ensuring accessibility in all environments.
- Bridges the gap between AI vision research and real-world usability.
