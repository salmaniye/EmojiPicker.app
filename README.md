# 🎉 Emoji Picker

A macOS menu bar app that lets you quickly insert emojis anywhere by typing shortcuts like `:heart` or `:fire`.

## How It Works

1. Type `:` followed by an emoji name (e.g., `:heart`, `:fire`, `:smile`)
2. Use arrow keys to navigate suggestions
3. Press Enter to insert the emoji
4. Press Escape to cancel

## Installation

1. Download the latest `.dmg` from releases
2. Drag "Emoji Picker" to Applications
3. Launch the app and grant accessibility permissions when prompted

## Setup

The app needs accessibility permissions to work:

1. Open **System Preferences** → **Security & Privacy** → **Privacy** → **Accessibility**
2. Add "Emoji Picker" to the list
3. Restart the app

## Requirements

- macOS 11.0+
- Accessibility permissions

## Building from Source

```bash
git clone https://github.com/yourusername/emoji-picker.git
cd emoji-picker
open emoji-picker.xcodeproj
```

## License

MIT License 