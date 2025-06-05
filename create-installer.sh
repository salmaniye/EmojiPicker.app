#!/bin/bash

# Script to create a distributable .dmg for Emoji Picker
# Run this after building your app in Xcode

APP_NAME="Emoji Picker"
APP_FILE="emoji-picker.app"
DMG_NAME="EmojiPicker-Installer.dmg"
VOLUME_NAME="Emoji Picker Installer"

echo "🚀 Creating installer for $APP_NAME..."

# Create temporary directory
mkdir -p dmg-temp
cd dmg-temp

# Copy the .app file (you'll need to build it in Xcode first)
echo "📦 Copying app file..."
cp -r "../build/Build/Products/Debug/$APP_FILE" .

# Create Applications folder symlink for easy installation
ln -s /Applications Applications

# Create the DMG
echo "💿 Creating DMG..."
cd ..
hdiutil create -srcfolder dmg-temp -volname "$VOLUME_NAME" -format UDZO -o "$DMG_NAME"

# Cleanup
rm -rf dmg-temp

echo "✅ Created $DMG_NAME"
echo "📤 You can now distribute this .dmg file for free!"
echo ""
echo "Users can:"
echo "1. Download the .dmg"
echo "2. Double-click to mount it"
echo "3. Drag Emoji Picker to Applications folder"
echo "4. Grant accessibility permissions when prompted"
echo "5. Enjoy global emoji shortcuts!" 