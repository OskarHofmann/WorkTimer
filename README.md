# WorkTimer - Time Tracking App

A mobile app for tracking time spent on different tasks with persistence and Excel export capabilities.

## Features

- Start/stop timers for multiple tasks
- Persistent storage 
- Historical data view with calendar
- Excel export 

## Prerequisites

### 1. Install Flutter

#### Windows Installation:
1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
2. Extract the zip file to a location (e.g., `C:\src\flutter`)
3. Add Flutter to PATH:
   - Search for "Environment Variables" in Windows
   - Edit "Path" under User variables
   - Add: `C:\src\flutter\bin` (or your installation path)

#### Verify Installation:
```bash
flutter doctor
```

This will check for:
- Flutter SDK ✓
- Android toolchain (Android Studio) 
- VS Code or Android Studio
- Connected devices

### 2. Install Android Studio

1. Download from: https://developer.android.com/studio
2. During installation, ensure these are selected:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
3. Open Android Studio and install additional components when prompted

### 3. Set up Android Emulator (or use physical device)

#### Option A: Android Emulator
1. Open Android Studio
2. Go to: Tools → Device Manager
3. Create Virtual Device → Select a phone (e.g., Pixel 6)
4. Download a system image (e.g., Android 13)
5. Finish setup

#### Option B: Physical Android Device
1. Enable Developer Options on your phone:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging in Developer Options
3. Connect via USB

### 4. Verify Setup
```bash
flutter devices
```
Should show your emulator or connected device.

## Installation & Running

### First Time Setup:
```bash
# Navigate to project directory
cd PROJECT_DIRECTORY

# Get dependencies
flutter pub get

# Check everything is OK
flutter doctor
```

### Run the App:
```bash
# Start your emulator first (or connect phone)

# Run the app
flutter run
```

The app will build and install on your device/emulator.

### Hot Reload During Development:
- Press `r` in the terminal to hot reload (instant updates)
- Press `R` to hot restart (full restart)
- Press `q` to quit

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   ├── task.dart         # Task data model
│   └── time_entry.dart   # Time entry data model
├── database/
│   └── database_helper.dart  # SQLite database management
├── screens/
│   ├── home_screen.dart      # Main screen with task buttons
│   ├── timer_screen.dart     # Active timer screen
│   ├── history_screen.dart   # Historical data view
│   └── settings_screen.dart  # Task management
└── utils/
    └── excel_export.dart     # Excel export functionality
```

## Usage

1. **First Launch**: Add tasks via the settings icon (⚙️) on home screen
2. **Start Timer**: Tap any task button to start tracking time
3. **Stop Timer**: Press the STOP button on timer screen
4. **View History**: Use the History tab to view past data
5. **Export**: Use the Export button to generate Excel file
