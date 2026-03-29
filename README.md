# 🔊 Signal - macOS Keystroke Audio Feedback

Signal is a premium, high-performance macOS menu bar application that provides real-time audio feedback for every keystroke. Inspired by mechanical keyboards and premium UI aesthetics, Signal transforms your typing experience into an immersive auditory journey.

![Signal App Banner](https://raw.githubusercontent.com/unitybtw/Signal-macOS/main/Resources/AppIcon.png)

## ✨ Features

- **15+ Audio Profiles:** Switch between Mechanical (Linear/Clicky), Typewriter, Sci-Fi, Arcade, 808, Laser, and even "Cat Meow" themes.
- **Pure Glass UI:** A sleek, Apple-inspired segmented control with smooth sliding animations and glassmorphic effects.
- **Dynamic Audio Pulse:** Real-time visual waveform that reacts to your typing speed and intensity.
- **Live Key History:** See your latest keystrokes visualized in the menu popover.
- **Advanced Analytics:** Real-time WPM (Words Per Minute) tracking and total keystroke counter.
- **Smart Accessibility Radar:** Automatically detects permission changes without requiring an app restart.
- **Battery Efficient:** Built with native Swift and low-latency Core Audio for negligible CPU impact.

## 🛠 Installation

1. **Clone the Repo:**
   ```bash
   git clone https://github.com/unitybtw/Signal-macOS.git
   cd Signal-macOS
   ```
2. **Build and Run:**
   Execute our custom build script to package the application:
   ```bash
   ./build.sh
   open Signal.app
   ```

## 🔒 Permissions

Signal requires **Accessibility Permissions** to monitor global keystrokes.
1. Open **System Settings > Privacy & Security > Accessibility**.
2. Ensure **Signal** is toggled ON.
3. If it's already on but not working, remove and re-add it.

## 🎨 Audio Profiles

Our current library includes:
- **Mechanical:** Premium linear and clicky switch recordings.
- **Typewriter:** Classic 1920s Underwood feel.
- **808 & Laser:** For the heavy producers and sci-fi fans.
- **Water & Bubble:** Calm, satisfying auditory pulses.
- **And much more...**

## 🏗 Built With

- **Swift & SwiftUI:** Native macOS interface components.
- **Core Audio:** High-fidelity, low-latency sound engine.
- **AppKit:** Seamless menu bar integration.

---
Created with ❤️ by [unitybtw](https://github.com/unitybtw)
