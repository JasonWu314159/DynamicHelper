# DynamicHelper

**DynamicHelper** is a dynamic floating window utility designed for **macOS**, inspired by the iPhone’s Dynamic Island. It integrates **battery monitoring, music playback detection, clipboard note storage, and multi-screen adaptive display**, delivering an efficient and non-intrusive desktop experience.

> 🖥️ Fully supports Apple Silicon and optimized for macOS Spaces.

## ✨ Features

## 🧊 IslandView: Always-on floating window
- Always stays on top, even when switching Spaces
- Immune to interference from apps or macOS gestures
- Automatically resizes and repositions based on dynamic content
- On notch-less devices/screens, activated by hovering the mouse to the top edge

## 🔋 BatteryView: Power status awareness
- Shows charging status when plugged in
- Automatically switches to other content when power is disconnected

### 📒 CopyBook: Scrollable clipboard content manager
- Supports scroll-to-store, tap-to-paste, and right-click interactions
- Automatically remembers last scroll position
- Great for quick copies, quotes, or transient notes

### 🎵 MediaStatusMonitor: Playback status detection
-  Detects whether Apple Music is currently playing
- Future support planned for YouTube and Spotify
- Integrated with IslandView for dynamic display

### 🖥️ Multi-screen support and smart alignment
- IslandView auto-scales and aligns based on content and screen
- Automatically aligns to main display or built-in screen in multi-monitor setups

### 🧩 Menu bar icon and controls
- Many buttons support command+click or right-click hidden actions — try them!

---

## 🛠️ Installation
   
1. Open the project with Xcode 15 or later

### Build using Xcode:
    1.    Install Xcode 15+
    2.    Clone the project:
        ```
        git clone https://github.com/JasonWu314159/DynamicHelper.git
        cd DynamicHelper
        open DynamicHelper.xcodeproj
        ```


2. Ensure system settings allow use of private APIs (for personal development only)
3. Build and run the app to see IslandView floating window
4. Alternatively, download prebuilt app from Releases (execution may not be guaranteed)

> Note: Some features use macOS private APIs. This app is intended for personal experimentation only — not for App Store or public distribution.

---

## 📄 License

This project is developed for personal use only. No commercial use is authorized.
You are welcome to use, modify, or share the project as long as it is not for commercial purposes.
If you encounter issues or have suggestions, feel free to comment — improvements will be made based on your feedback.

---

## 🧑‍💻 Developer Info
- macOS / SwiftUI / System integration enthusiast
