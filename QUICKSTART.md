# Quick Start Guide - WorkTimer

## Installation Steps

### 1. Install Flutter (if not already installed)

**Windows:**
```bash
# Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
# Extract to C:\src\flutter (or your preferred location)
# Add to PATH: C:\src\flutter\bin

# Verify installation
flutter doctor
```

### 2. Install Android Studio

1. Download from: https://developer.android.com/studio
2. Run installer and install Android SDK
3. Open Android Studio → Tools → SDK Manager
4. Ensure Android SDK is installed (API level 21+)

### 3. Set up Device

**Option A: Android Emulator**
1. Android Studio → Tools → Device Manager
2. Create Virtual Device → Select Pixel 6 or similar
3. Download system image (Android 13 recommended)
4. Start emulator

**Option B: Physical Device**
1. Enable Developer Options on phone (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect via USB
4. Verify with: `flutter devices`

### 4. Set Up Project

```bash
# Navigate to project folder
cd PROJECT_FOLDER

# Get all dependencies
flutter pub get

# Check for issues
flutter doctor
```

### 5. Run the App

```bash
# Make sure emulator is running or device is connected
flutter devices

# Run the app
flutter run
```

The app will build and install. First build takes 3-5 minutes, subsequent builds are much faster.

## Using the App

### First Time Setup
1. App opens with home screen
2. Tap settings icon (⚙️) to add tasks
3. Tap "Add Task" button
4. Enter task name and choose color
5. Repeat for all your tasks (10-12 tasks fit well on screen)

### Tracking Time
1. On home screen, tap any task button to start timer
2. Timer screen shows current session and today's total
3. Tap STOP to pause timer and return to home screen
4. Tap same task again to continue tracking

### Viewing History
1. Tap "History" button at bottom
2. Use calendar to select any date
3. View time spent per task for that date
4. Orange dots indicate dates with tracked time

### Exporting Data
1. Go to History screen
2. Tap export icon (📤) in top right
3. Excel file is generated with:
   - One sheet per task (date + hours)
   - Summary sheet (total per task)
4. Share file via any app (email, Drive, etc.)

### Managing Tasks
1. Tap settings icon (⚙️) on home screen
2. Tap "Add Task" to create new task
3. Tap edit icon to modify task name/color
4. Tap delete icon to hide task (data preserved)

## Development Commands

```bash
# Hot reload (instant updates while running)
# Press 'r' in terminal

# Hot restart (full restart)
# Press 'R' in terminal

# Build APK for installation
flutter build apk

# Clean build (if errors occur)
flutter clean
flutter pub get
flutter run

# View logs
flutter logs

# Run in release mode (faster)
flutter run --release
```
