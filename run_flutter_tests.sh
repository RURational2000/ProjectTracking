#!/bin/bash
set -e

# Update and install dependencies
apt-get update
apt-get install -y curl git unzip xz-utils

# Install Flutter
cd /tmp
rm -rf /flutter
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
export PATH="/tmp/flutter/bin:$PATH"

# Skip analytics and agree to licenses
flutter config --no-analytics
yes | flutter doctor --android-licenses || true

# Run tests
cd /workspace
flutter pub get
flutter test

