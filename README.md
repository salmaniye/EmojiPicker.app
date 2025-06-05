# 🎉 Emoji Picker - Rocket Style

A powerful macOS menu bar application that provides instant emoji shortcuts in any app. Type `:emoji_name` anywhere and get smart emoji suggestions with keyboard navigation!

## ✨ Features

- **🚀 Universal Emoji Shortcuts**: Works in any macOS application
- **🔍 Smart Search**: Intelligent emoji matching with priority-based ranking
- **⌨️ Keyboard Navigation**: Navigate suggestions with arrow keys
- **📱 Menu Bar Integration**: Runs quietly in your menu bar
- **📊 Comprehensive Database**: 3000+ emojis with categories and keywords
- **🎯 Priority Matching**: Smart ranking for exact matches and prefix searches
- **⚡ Real-time Suggestions**: Instant feedback as you type

## 🎬 How It Works

1. **Start typing**: Use `:` followed by emoji name in any app (e.g., `:heart`, `:fire`, `:thumbsup`)
2. **See suggestions**: A dropdown appears with matching emojis
3. **Navigate**: Use ↑/↓ arrow keys to select
4. **Insert**: Press Enter to insert the selected emoji
5. **Cancel**: Press Escape or Space to cancel

### Examples
- `:heart` → ❤️ 💖 💝 💗 💓 💕
- `:smile` → 😄 😊 😃 😆 😁 😂
- `:fire` → 🔥
- `:thumbsup` → 👍

## 🛠 Technical Features

### Emoji Database
- **Comprehensive**: Complete emoji database with Unicode support
- **Categories**: Organized into 8 major categories:
  - 😀 Smileys & People
  - 🐶 Animals & Nature  
  - 🍎 Food & Drink
  - ⚽ Activities
  - 🚗 Travel & Places
  - 💡 Objects
  - 💯 Symbols
  - 🏁 Flags

### Smart Search Algorithm
- **Priority-based matching**: Exact matches rank highest
- **Prefix matching**: Terms starting with your query
- **Keyword support**: Multiple search terms per emoji
- **Apple compatibility**: Only shows emojis supported on macOS

### System Integration
- **Global event handling**: Uses CGEventTap for system-wide shortcuts
- **Accessibility permissions**: Required for global key interception
- **Menu bar app**: Lightweight, always-available interface

## 📋 Requirements

- **macOS 11.0+** (Big Sur or later)
- **Accessibility permissions** (the app will prompt you)
- **Xcode 13.0+** (for building from source)

## 🚀 Installation

### Option 1: Download Release
1. Download the latest `.dmg` from releases
2. Mount the DMG and drag "Emoji Picker" to Applications
3. Launch the app
4. Grant accessibility permissions when prompted

### Option 2: Build from Source
```bash
git clone https://github.com/yourusername/emoji-picker.git
cd emoji-picker
open emoji-picker.xcodeproj
```

Build and run in Xcode, or use the installer script:
```bash
./create-installer.sh
```

## 🔧 Setup

### Accessibility Permissions
The app needs accessibility permissions to work globally:

1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Click the lock to make changes
3. Add "Emoji Picker" to the list
4. Restart the app

### First Launch
- The app appears in your menu bar with a 😊 icon
- Click the icon to see status and test functionality
- Try typing `:test` in any text field to verify it's working

## 📊 Project Structure

```
emoji-picker/
├── emoji-picker/
│   ├── emoji_pickerApp.swift      # Main app entry point
│   ├── SimpleAppDelegate.swift    # Core functionality & event handling
│   ├── ContentView.swift          # SwiftUI views
│   ├── emoji.json                 # Comprehensive emoji database
│   └── Assets.xcassets/           # App icons and resources
├── EmojiData.swift                # Emoji data models and database manager
├── create-installer.sh            # DMG creation script
└── emoji-picker.xcodeproj/        # Xcode project
```

## 🎯 Core Components

### EmojiData.swift
- **EmojiData struct**: Models individual emoji with metadata
- **EmojiDatabase class**: Manages loading and searching emojis
- **Search functions**: Smart emoji matching and categorization

### SimpleAppDelegate.swift
- **Event handling**: Global keyboard interception via CGEventTap
- **Menu bar management**: Status bar integration
- **UI rendering**: Dropdown suggestion interface
- **Emoji insertion**: System-level text injection

## 🔍 Search Algorithm

The app uses a sophisticated priority-based search:

1. **Exact short_name match** (Priority: 1000)
2. **Prefix match in short_name** (Priority: 900)
3. **Contains match in short_name** (Priority: 800)
4. **Prefix match in keywords** (Priority: 700)
5. **Contains match in keywords** (Priority: 600)

## 🎨 Menu Bar Features

Click the menu bar icon to access:
- Usage instructions and examples
- Accessibility permission status
- Current tracking status
- Test functionality
- Quit option

## 🐛 Troubleshooting

### App Not Working
- **Check accessibility permissions** in System Preferences
- **Restart the app** after granting permissions
- **Try the test function** from menu bar

### No Emoji Suggestions
- Ensure you start with `:` character
- Check that emoji.json loaded successfully (check Console.app)
- Verify accessibility permissions are granted

### Performance Issues
- The app uses minimal CPU when idle
- Database loads once at startup
- Event handling is optimized for real-time response

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on macOS
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Emoji database sourced from the comprehensive Unicode emoji specification
- Built with SwiftUI and AppKit for native macOS integration
- Inspired by the need for quick emoji access across all applications

## 🚀 Version History

- **v1.0**: Initial release with core emoji shortcut functionality
- Global CGEventTap integration
- Comprehensive emoji database
- Smart search and navigation

---

Made with ❤️ for emoji lovers everywhere! Type `:heart` to spread the love! 🎉 