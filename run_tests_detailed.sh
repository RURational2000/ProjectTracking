#!/bin/bash

# This script attempts to run Flutter tests with detailed diagnostic output

echo "========================================="
echo "Flutter Test Runner"
echo "========================================="
echo ""

# Check for Flutter
echo "1. Checking for Flutter installation..."
if command -v flutter &> /dev/null; then
    echo "✓ Flutter found at: $(which flutter)"
    flutter --version
else
    echo "✗ Flutter not found"
    echo ""
    echo "Attempting to install Flutter..."
    
    # Try to clone Flutter
    if command -v git &> /dev/null; then
        echo "Installing Flutter SDK..."
        mkdir -p /tmp/flutter-sdk
        cd /tmp/flutter-sdk
        git clone --depth 1 --branch stable https://github.com/flutter/flutter.git 2>&1 || {
            echo "Failed to clone Flutter repository"
            exit 1
        }
        export PATH="/tmp/flutter-sdk/flutter/bin:$PATH"
    else
        echo "Git not found, cannot clone Flutter"
        exit 1
    fi
fi

# Navigate back to project
cd /home/runner/work/ProjectTracking/ProjectTracking

# Check Dart
echo ""
echo "2. Checking for Dart installation..."
if command -v dart &> /dev/null; then
    echo "✓ Dart found at: $(which dart)"
    dart --version
else
    echo "✗ Dart not found separately"
fi

# Try Flutter pub
echo ""
echo "3. Getting dependencies..."
flutter pub get 2>&1 | tail -20

# Run tests
echo ""
echo "4. Running tests..."
flutter test --verbose 2>&1

