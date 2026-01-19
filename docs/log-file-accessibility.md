# Log File Accessibility Configuration

This document explains how log files are stored on different platforms and how to configure them for optimal user accessibility.

## Overview

The Project Tracking app creates human-readable log files for each project as an audit trail and verification mechanism. These log files are stored in platform-specific locations that balance security and accessibility.

## Storage Locations by Platform

### Windows

**Location**: `C:\Users\<username>\Documents\ProjectTrackingLogs\`

**Accessibility**: Immediately accessible via File Explorer.

**Configuration**: No additional configuration needed.

### Linux

**Location**: `~/Documents/ProjectTrackingLogs/`

**Accessibility**: Accessible via any file manager.

**Configuration**: No additional configuration needed.

### Android

**Location**: `/storage/emulated/0/Android/data/com.example.project_tracking/files/ProjectTrackingLogs/`

(Replace `com.example.project_tracking` with your app's package name if you've customized it)

**Accessibility**: 
- Accessible via file manager apps (Files by Google, Samsung My Files, etc.)
- Navigate to: Internal Storage → Android → data → com.example.project_tracking → files → ProjectTrackingLogs
- Files persist after app updates
- Files are removed when the app is uninstalled

**Configuration**: 
- No additional configuration needed
- The app automatically uses external storage directory which is accessible by file managers
- External storage permissions are already declared in `AndroidManifest.xml`

**Alternative Access Methods**:
- Connect device to computer via USB and browse using File Explorer (Windows) or file browser (Linux/Mac)
- Use ADB: `adb pull /storage/emulated/0/Android/data/com.example.project_tracking/files/ProjectTrackingLogs/`

### iOS

**Location**: `<App Container>/Documents/ProjectTrackingLogs/`

**Accessibility**: 
- Accessible via the Files app when file sharing is enabled
- Open Files app → On My iPhone → Project Tracking → ProjectTrackingLogs

**Configuration Required**:

When building the app for iOS, you need to enable file sharing in the `Info.plist` file. This file is generated during the first iOS build.

**Steps to Enable File Sharing**:

1. Build the iOS app at least once to generate the iOS project structure:
   ```bash
   flutter build ios
   ```

2. Open the generated `Info.plist` file at `ios/Runner/Info.plist`

3. Add the following keys before the closing `</dict>` tag:
   ```xml
   <key>UIFileSharingEnabled</key>
   <true/>
   <key>LSSupportsOpeningDocumentsInPlace</key>
   <true/>
   ```

4. Rebuild the app

**What these keys do**:
- `UIFileSharingEnabled`: Makes the app's Documents directory visible in the Files app
- `LSSupportsOpeningDocumentsInPlace`: Allows other apps to open files in place without copying

**Example Info.plist snippet**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Other existing keys -->
    
    <!-- File Sharing Configuration -->
    <key>UIFileSharingEnabled</key>
    <true/>
    <key>LSSupportsOpeningDocumentsInPlace</key>
    <true/>
</dict>
</plist>
```

## Implementation Details

The platform-specific directory selection is implemented in `lib/services/file_logging_service_io.dart`:

```dart
Future<void> initialize() async {
  final Directory appDir;
  
  if (Platform.isAndroid) {
    // Use external storage for user-accessible files
    final Directory? externalDir = await getExternalStorageDirectory();
    appDir = externalDir ?? await getApplicationDocumentsDirectory();
  } else if (Platform.isIOS) {
    // Use documents directory (accessible via Files app with proper config)
    appDir = await getApplicationDocumentsDirectory();
  } else {
    // Windows, Linux, macOS: Use documents directory
    appDir = await getApplicationDocumentsDirectory();
  }
  
  _logDirectory = path.join(appDir.path, 'ProjectTrackingLogs');
  await Directory(_logDirectory!).create(recursive: true);
}
```

## Security Considerations

### Android
- Files in external storage are accessible by other apps with storage permissions
- Files are not encrypted at rest
- Consider the sensitivity of logged data

### iOS
- Files in the Documents directory are part of the app's sandbox
- Only accessible via Files app when explicitly shared
- Files are encrypted with device encryption

### All Platforms
- Log files contain project names, instance timestamps, and user notes
- Do not include sensitive information in project names or notes if sharing logs
- Log files are plain text and not encrypted by the app

## Troubleshooting

### Android: Can't find log files
1. Ensure external storage permission is granted (should be automatic)
2. Check if the app has run at least once to create the directory
3. Try different file manager apps (some may not show app-specific folders)
4. Use a computer connection or ADB to verify files exist

### iOS: Files app doesn't show the app
1. Verify `UIFileSharingEnabled` is set to `true` in Info.plist
2. Rebuild the app after modifying Info.plist
3. Ensure the app has created at least one log file
4. Restart the device if the Files app doesn't update

### Windows/Linux: Can't find Documents folder
1. Check if OneDrive or similar service is redirecting Documents folder
2. Verify the app has appropriate file system permissions
3. Check the actual directory returned by the app (may be user-specific)

## Future Enhancements

Potential improvements for log file accessibility:

1. **Export functionality**: Add UI to export logs via share sheet
2. **Cloud backup**: Optional integration with cloud storage services
3. **Email logs**: Built-in email functionality to send logs
4. **Log viewer**: In-app log file viewer with search and filter
5. **Selective export**: Export logs for specific projects or date ranges
