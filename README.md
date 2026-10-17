# Tap Counter (iOS & watchOS)

A minimalist, high-performance counting application for iOS and watchOS built with SwiftUI, ActivityKit, and WatchConnectivity.

---

## Features

### 1. Counting Experience
- **Tap Anywhere to Count:** The entire screen serves as an interactive tap zone.
- **Physical Feedback:** 
  - Crisp mechanical haptics (`.rigid` impact with 1.0 intensity).
  - Authentic mechanical keyboard click audio played via `AVAudioPlayer` (`.playback` audio session).
- **Three Counting Modes:**
  - **Simple:** Count freely without bounds.
  - **Target:** Count toward a specific goal with real-time circular progress indicator, haptic milestones, celebration overlay, and auto-finish.
  - **Timer:** Count against a countdown timer (hours, minutes, seconds) with audible & haptic alerts on completion.
- **Utility Controls:** Instant subtract (`-`) and reset (`↺`).

### 2. Live Activity & Dynamic Island (iOS)
- **Automatic Morph on Exit:** Smoothly collapses into the Dynamic Island when swiping to Home, just like Apple Music and Clock.
- **Dynamic Island Compact Layouts:**
  - **Simple Mode:** Left app icon, Right tap count (17pt bold rounded).
  - **Target Mode:** Left app icon, Right `count / target`.
  - **Timer Mode:** Left app icon + count, Right timer countdown (`MM:SS`).
- **Lock Screen Live Activity Banner:**
  - High-visibility 44pt bold count display.
  - Mode progress indicators and remaining time.
- **One-Tap Re-entry:** Deep-links directly back into the session via `tapcounter://session/<id>`.

### 3. Apple Watch Companion App (watchOS)
- **Standalone & Paired:** Works offline or paired with the iPhone.
- **Real-Time Bidirectional Sync:** Powered by `WCSession` (`WatchConnectivity`):
  - Tapping on the Watch increments the iPhone counter and Live Activity instantly.
  - Tapping on the iPhone reflects immediately on the wrist.
- **Wrist Haptics:** Physical `.click` tactile feedback on every count.
- **Digital Crown Support:** Rotate the Digital Crown forward or backward to count.
- **Quick Start:** Pick between Simple, Target (e.g. 108 mantra), or 5-minute timed sessions from the wrist.

---

## Project Structure

```text
TapCounter/
├── TapCounter/              # Main iOS Application Target
│   ├── TapCounterApp.swift  # App Lifecycle & Watch Sync Init
│   ├── Models/              # TapSession & ActivityAttributes
│   ├── ViewModels/          # TapSessionViewModel
│   ├── Views/               # HomeView, TapCounterView, NewSessionSheet
│   ├── Services/            # TapStore, HapticService, LiveActivityManager, PhoneWatchSyncManager
│   └── Assets.xcassets      # App Icons & Color Sets
├── TapCounterWidget/        # WidgetKit Extension (Dynamic Island & Live Activity)
│   ├── TapCounterWidget.swift
│   └── Info.plist
└── TapCounterWatch/         # Apple Watch Companion Target (watchOS 10+)
    ├── TapCounterWatchApp.swift
    ├── Views/               # WatchHomeView, WatchCounterView
    ├── Services/            # WatchSessionManager
    └── Assets.xcassets
```

---

## Requirements

- **iOS:** 17.0+
- **watchOS:** 10.0+
- **Xcode:** 15.4+ / 16.0+
- **Swift:** 5.0+
