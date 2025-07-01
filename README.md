<img align="right" src="https://visitor-badge.laobi.icu/badge?page_id=logically-nerd.hen" />

# HEN (Help! Emergency Network) 🚨

Emergency mesh networking app for disaster communication when cellular networks fail.

## What it does
Creates device-to-device networks that relay emergency messages until reaching internet connectivity.

## Tech Stack
- Flutter 3.8.1+
- Platform channels for native WiFi Direct/Bluetooth
- Supports Android 8.0+, iOS 13.0+ (planned)

## Features Roadmap

- [ ] **Device-to-Device Connection**
  - WiFi Direct and Bluetooth discovery
  - Automatic peer connection establishment
  
- [ ] **Create Public Mesh**
  - Join/leave mesh networks seamlessly
  - Multi-hop message routing
  
- [ ] **Broadcast SOS Message**  
  - One-tap emergency alert with GPS location
  - Automatic delivery via internet-connected devices
  
- [ ] **Optimize Network**
  - Battery-efficient mesh management
  - Smart routing and connection healing
  
- [ ] **Manual Message**
  - Send custom messages through the mesh
  - Text communication between users

## Quick Start
```bash
git clone https://github.com/logically-nerd/hen.git
cd hen
flutter pub get
flutter run
```

## Development Status
🔧 **In Development** - Device-to-Device Connection

---
**Emergency communication when networks fail**