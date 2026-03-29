# 📡 Signal - Keystroke Audio Feedback for macOS

Signal is a native macOS menu bar application designed to provide real-time, ultra-low-latency audio feedback for your keystrokes. It transforms your typing experience into something mechanical, nostalgic, or futuristic.

![Signal UI](https://img.shields.io/badge/UX-Native_macOS-blue?style=for-the-badge)
![Swift](https://img.shields.io/badge/Language-Swift-orange?style=for-the-badge)
![Latency](https://img.shields.io/badge/Latency-%3C5ms-green?style=for-the-badge)

## 🚀 Features

- **Real-time Audio Synthesis:** Instead of playing precorded audio files, Signal synthesizes sounds on-the-fly. This minimizes CPU usage and eliminates perceived latency.
- **Three Unique Sound Profiles:**
  - **Mechanical:** The tactile feel of a modern mechanical keyboard (M-Switch).
  - **Typewriter:** The classic chime and clack of a vintage typewriter.
  - **Sci-Fi:** Futuristic terminal sounds and laser-like electronic blips.
- **Native Interface:** A minimalist SwiftUI interface that blends perfectly with macOS (Control Center style), featuring dark glassmorphism.
- **Menu Bar Integration:** Runs quietly in the background, accessible via a sleek status bar icon for quick adjustments.

## 🛠️ Tech Stack

- **Language:** Swift 5.10+
- **Frameworks:** SwiftUI, AppKit, AVFoundation (AVAudioEngine)
- **Monitoring:** Low-level system-wide keyboard monitoring using `CGEventTap` (Accessibility API).
- **Architecture:** Zero-dependency, purely native Apple APIs.

## ⚙️ Build and Run

To build the application locally, simply run the following command in your terminal:

```bash
chmod +x build.sh
./build.sh
```

Once the build is complete, you can launch `Signal.app`:

```bash
open Signal.app
```

## 🔐 Important: Accessibility Permissions

Due to macOS security protocols, Signal requires **Accessibility** permissions to detect keyboard events across other applications.

1. Go to **System Settings** -> **Privacy & Security** -> **Accessibility**.
2. Click the `+` icon and add `Signal.app` from your project folder.
3. Ensure the toggle is turned ON.
4. Restart Signal if necessary.

## 📂 Project Structure

- `Source/Core`: Keyboard monitoring and audio synthesis engines.
- `Source/UI`: SwiftUI-based native interface components.
- `SignalApp.swift`: Main application lifecycle and status item management.
- `build.sh`: Bash script to compile and bundle the `.app` package.

---
*Developed by [unitybtw](https://github.com/unitybtw)*
