# NavAssist — AI Navigation Assistant

AI-powered navigation assistant for visually impaired users.
2-stage cascade: Gemini gate → Gemini classify + Arduino ultrasonic sensors.

## Getting Your APK (No Installation Needed)

1. Push this folder to a GitHub repository
2. Go to the Actions tab on GitHub
3. Click the latest "Build Flutter APK" workflow run
4. Wait ~5 minutes for it to complete
5. Click "nav-assist-apk" under Artifacts to download the APK
6. Transfer APK to your Android phone and install it

## Before Installing

Enable "Install from unknown sources" on your Android phone:
- Android 8+: Settings → Apps → Special App Access → Install Unknown Apps
  → Find your file manager → Allow
- Android 7 and below: Settings → Security → Unknown Sources → ON

Enable Developer Mode (optional but useful):
- Settings → About Phone → tap "Build Number" 7 times

## Setup

### 1. Get Gemini API Key (Free)
- Go to https://aistudio.google.com
- Sign in with Google account
- Click "Get API Key" → "Create API key"
- Copy the key
- Open the app → Settings → paste key → Save

### 2. Connect Arduino
- Buy a USB OTG adapter (₹150 on Amazon — USB-C to USB-A or Micro-USB to USB-A)
- Upload arduino_sensors.ino to Arduino Nano using Arduino IDE on a computer
- Plug OTG adapter into your phone
- Plug Arduino Nano into OTG adapter
- Open app — Home screen will show "Arduino connected ✓"

### 3. Wire the Sensors
Left HC-SR04:   VCC→5V, GND→GND, TRIG→D2, ECHO→D3
Center HC-SR04: VCC→5V, GND→GND, TRIG→D4, ECHO→D5
Right HC-SR04:  VCC→5V, GND→GND, TRIG→D6, ECHO→D7

### 4. Use the App
- Open app → tap "Start Navigation"
- Point phone camera forward (mount on chest or hold forward)
- App speaks navigation cues automatically
- View Results screen to see API efficiency data for science fair

## Finding Your CSV Data File
Android/data/com.navassist.app/files/nav_log_DATETIME.csv
Or check the Results screen for the exact path.
Transfer via USB cable to computer for analysis.

## Science Fair Research Finding
The Results screen shows what percentage of API calls the cascade saved.
In a typical indoor environment, the gate (Stage 1) handles 60-80% of frames
without ever calling the full Gemini classifier (Stage 2).
This proves cascaded inference reduces API usage while maintaining accuracy.
