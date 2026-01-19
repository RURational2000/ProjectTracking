#!/bin/bash
set -e

#################################
# Flutter Test Runner Script
# This script sets up and runs Flutter tests for the ProjectTracking app
#################################

FLUTTER_VERSION="3.22.0-stable"
FLUTTER_INSTALL_DIR="${HOME}/.flutter"

echo "========================================="
echo "Flutter Test Runner for ProjectTracking"
echo "========================================="
echo ""

# Function to detect flutter installation
find_flutter() {
    if command -v flutter &> /dev/null; then
        echo "✓ Flutter already installed: $(which flutter)"
        return 0
    fi
    
    if [ -f "$FLUTTER_INSTALL_DIR/flutter/bin/flutter" ]; then
        export PATH="$FLUTTER_INSTALL_DIR/flutter/bin:$PATH"
        echo "✓ Found Flutter in $FLUTTER_INSTALL_DIR"
        return 0
    fi
    
    return 1
}

# Function to download and install Flutter
install_flutter() {
    echo "Installing Flutter SDK..."
    mkdir -p "$FLUTTER_INSTALL_DIR"
    cd "$FLUTTER_INSTALL_DIR"
    
    if ! command -v git &> /dev/null; then
        echo "✗ Git is required but not installed"
        return 1
    fi
    
    echo "Cloning Flutter from GitHub..."
    git clone --depth 1 --branch stable https://github.com/flutter/flutter.git 2>/dev/null || {
        echo "✗ Failed to clone Flutter repository"
        return 1
    }
    
    export PATH="$FLUTTER_INSTALL_DIR/flutter/bin:$PATH"
    
    echo "Configuring Flutter..."
    flutter config --no-analytics 2>&1 || true
    
    echo "✓ Flutter installed successfully"
    return 0
}

# Main execution
echo "Step 1: Locating Flutter..."
if ! find_flutter; then
    echo "Step 2: Installing Flutter..."
    if ! install_flutter; then
        echo ""
        echo "ERROR: Could not install Flutter"
        echo "  Troubleshooting:"
        echo "    - Ensure internet connectivity"
        echo "    - Ensure git is installed"
        echo "    - Check /var/log/flutter.log for details"
        exit 1
    fi
fi

echo ""
echo "Step 3: Getting Flutter version..."
flutter --version
echo ""

echo "Step 4: Getting dependencies..."
cd /home/runner/work/ProjectTracking/ProjectTracking
flutter pub get 2>&1 || {
    echo "✗ Failed to get dependencies"
    exit 1
}

echo ""
echo "Step 5: Running tests..."
flutter test --verbose 2>&1

test_result=$?

echo ""
echo "========================================="
if [ $test_result -eq 0 ]; then
    echo "✓ All tests passed successfully!"
else
    echo "✗ Tests failed with exit code: $test_result"
fi
echo "========================================="

exit $test_result
