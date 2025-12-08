# Testing Android Builds

This guide explains how to test the Project Tracking app on Android devices and emulators.

## Prerequisites

- Flutter SDK installed and configured
- Android SDK installed (comes with Android Studio or Flutter setup)
- Java Development Kit (JDK) 17 or higher

## Testing Methods

### 1. Test on Android Emulator (Recommended for Development)

#### List Available Emulators

```bash
flutter emulators
```

#### Launch an Emulator

```bash
flutter emulators --launch <emulator_id>
```

Example:

```bash
flutter emulators --launch Medium_Phone_API_36.1
```

#### Run the App

Once the emulator is running (wait 30-60 seconds after launch):

```bash
flutter run
```

The app will build, install, and launch automatically on the emulator.

#### Hot Reload During Development

While the app is running, you can make code changes and instantly see them:

- Press `r` for hot reload (preserves app state)
- Press `R` for hot restart (resets app state)
- Press `q` to quit

---

### 2. Test on Physical Android Device

#### Enable Developer Mode on Your Device

1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times
3. You'll see "You are now a developer!"

#### Enable USB Debugging

1. Go to **Settings** → **Developer Options**
2. Enable **USB Debugging**
3. Connect your device via USB cable

#### Verify Device Connection

```bash
flutter devices
```

You should see your Android device listed.

#### Run the App on Device

```bash
flutter run
```

If multiple devices are connected:

```bash
flutter run -d <device_id>
```

---

### 3. Install Pre-built APK

#### Build the APK

For debug build:

```bash
flutter build apk --debug
```

For release build:

```bash
flutter build apk --release
```

#### Locate the APK

Debug APK: `build\app\outputs\flutter-apk\app-debug.apk`
Release APK: `build\app\outputs\flutter-apk\app-release.apk`

#### Install on Device

##### Option A: Using ADB (Android Debug Bridge)

```bash
adb install build\app\outputs\flutter-apk\app-debug.apk
```

##### Option B: Manual Transfer

1. Copy the APK file to your Android device (via USB, email, or cloud storage)
2. Open the APK file on your device
3. Allow installation from unknown sources if prompted
4. Tap "Install"

---

### 4. Build and Test App Bundle (for Play Store)

#### Build an App Bundle

```bash
flutter build appbundle --release
```

The bundle will be created at: `build\app\outputs\bundle\release\app-release.aab`

#### Test the Bundle

App bundles can't be installed directly. To test:

1. Upload to Google Play Console (Internal Testing track)
2. Or use `bundletool` to generate APKs from the bundle locally

---

## Testing Different Build Modes

### Debug Mode (Default)

- Includes debugging information
- Larger file size
- Hot reload enabled

```bash
flutter run
# or
flutter build apk --debug
```

### Profile Mode

- Optimized performance
- Includes some debugging capabilities

```bash
flutter run --profile
# or
flutter build apk --profile
```

### Release Mode

- Fully optimized
- Smallest file size
- No debugging overhead

```bash
flutter build apk --release
```

---

## Common Commands Reference

| Command | Description |
|---------|-------------|
| `flutter devices` | List all connected devices and emulators |
| `flutter emulators` | List available emulators |
| `flutter emulators --launch <id>` | Start a specific emulator |
| `flutter run` | Build and run on connected device |
| `flutter run -d <device>` | Run on specific device |
| `flutter build apk` | Build APK file |
| `flutter build appbundle` | Build app bundle for Play Store |
| `flutter clean` | Clean build artifacts |
| `adb devices` | List connected Android devices (via ADB) |
| `adb install <apk_path>` | Install APK via ADB |

---

## Troubleshooting

### Emulator Won't Start

- Ensure virtualization is enabled in BIOS (Intel VT-x or AMD-V)
- Check Android Studio → AVD Manager for emulator status
- Try creating a new emulator with a different API level

### Device Not Detected

- Check USB cable connection
- Enable USB Debugging on device
- Try different USB port
- Run `flutter doctor` to check for issues
- Run `adb kill-server` then `adb start-server`

### Build Failures

- Run `flutter clean` then rebuild
- Check Java version: `java -version` (should be JDK 17+)
- Verify JAVA_HOME points to JDK, not JRE
- Update Flutter: `flutter upgrade`
- Check Gradle configuration in `android/gradle.properties`

### App Crashes on Startup

- Check Android version compatibility
- Review logs: `flutter logs`
- Enable verbose logging: `flutter run -v`
- Check for missing permissions in `AndroidManifest.xml`

---

## Performance Testing

### Check App Performance

While the app is running:

```bash
flutter run --profile
```

Then open DevTools:

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

### Measure App Size

```bash
flutter build apk --release --analyze-size
```

---

## Automated Testing

### Run Unit Tests

```bash
flutter test
```

### Run Integration Tests

```bash
flutter test integration_test
```

### Run Tests on Specific Device

```bash
flutter test -d <device_id>
```

---

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Android Developer Guide](https://developer.android.com/)
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools)
- [Debugging Flutter Apps](https://docs.flutter.dev/testing/debugging)
