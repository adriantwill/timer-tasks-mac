# Timer Tasks - Native SwiftUI Mac App

## Overview
Replace existing web app with native SwiftUI Mac app. Full window app with auto-start/stop tasks when specific macOS apps are opened/closed.

## Architecture

### Data Model
```swift
struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var targetTime: TimeInterval?  // nil = no limit
    var elapsedTime: TimeInterval
    var color: String  // hex
    var isManualComplete: Bool
}

struct TriggerMapping: Identifiable, Codable {
    let id: UUID
    var pattern: String           // e.g., "app:com.microsoft.VSCode" or "title:*GitHub*"
    var patternType: PatternType  // .app, .title, .url
    var taskTitle: String
}

enum PatternType: String, Codable {
    case app    // match bundle identifier
    case title  // match window title (glob)
    case url    // match full URL (Phase 2)
}

struct LifetimeStat: Identifiable, Codable {
    let id: UUID
    var color: String
    var totalTime: TimeInterval
    var breakdown: [(title: String, time: TimeInterval)]
}
```

### Storage
- **SwiftData** for persistence (modern, integrates with SwiftUI)
- Weekly reset logic (same as current web app)
- Export to JSON for backup

---

## Core Components

### 1. App Monitoring (`AppMonitor.swift`)
Uses `NSWorkspace` to detect app launches/terminations:
```swift
// Key notifications:
NSWorkspace.didLaunchApplicationNotification
NSWorkspace.didTerminateApplicationNotification

// Get running apps:
NSWorkspace.shared.runningApplications
```

When app launches → check mappings → start associated task
When app quits → stop task if it was auto-started

### 2. Browser Tab Monitoring (`BrowserMonitor.swift`)
Detects active browser tab to trigger tasks based on websites.

**Phase 1: Window Title Matching**
- Use Accessibility API to read window title (no focus stealing)
- Match patterns like `*GitHub*`, `*YouTube*`
- Works for all browsers
- Requires accessibility permission

**Phase 2 (optional): Full URL Matching**
- AppleScript for Safari/Chrome (easy, full URL)
- Accessibility API for Firefox (read URL bar directly)
- Match patterns like `github.com/*`, `docs.google.com/*`

**Pattern syntax:**
```
title:*GitHub*           → match window title
url:github.com/*         → match full URL (Phase 2)
app:com.microsoft.VSCode → match app bundle ID
```

**Polling strategy:**
- Check active window every 2-3 seconds
- Only query browser URL if frontmost app is a browser
- Minimal performance impact

### 2. Timer Manager (`TimerManager.swift`)
- Singleton for active timer state
- Publishes updates via `@Published`/Combine
- Handles background time accumulation
- Weekly reset check

### 3. Views
- `ContentView` - Main task list + weekly progress
- `TaskRowView` - Individual task with play/pause, time, progress
- `TaskFormView` - Add/edit task
- `SettingsView` - Configure app→task mappings
- `HistoryView` - Lifetime stats

### 4. Menu Bar Helper (optional)
- Show active task + elapsed time in menu bar
- Quick start/stop without opening main window

---

## Project Structure
```
TimerTasks/
├── TimerTasksApp.swift        # App entry
├── Models/
│   ├── Task.swift
│   ├── AppMapping.swift
│   └── LifetimeStat.swift
├── Managers/
│   ├── TimerManager.swift
│   ├── AppMonitor.swift
│   └── DataManager.swift
├── Views/
│   ├── ContentView.swift
│   ├── TaskRowView.swift
│   ├── TaskFormView.swift
│   ├── SettingsView.swift
│   └── HistoryView.swift
└── Utilities/
    └── WeeklyReset.swift
```

---

## Implementation Order

1. **Project setup** - Create Xcode project, add SwiftData models
2. **Basic UI** - Task list, add/delete tasks, manual timer toggle
3. **Timer logic** - Background timer, elapsed time tracking
4. **VPS status endpoint** - POST/GET on tasks.adrianwill.com
5. **Status pusher** - Mac app pushes status every 1 sec
6. **App monitoring** - NSWorkspace observers, app→task mappings
7. **Browser title matching** - Accessibility API for window titles, glob patterns
8. **Settings UI** - Configure triggers (app, title patterns)
9. **Weekly reset** - Port week calculation logic from web app
10. **History/stats** - Lifetime stats view
11. **Polish** - Menu bar helper, export, styling
12. **(Optional) Full URL matching** - AppleScript for Safari/Chrome, Accessibility for Firefox URL bar

---

## macOS APIs Used
- `NSWorkspace` - App launch/quit detection
- `SwiftData` - Persistence
- `Timer` - Background time tracking
- `UserDefaults` - Settings/preferences
- `NSStatusItem` - Menu bar (optional)

---

## Real-Time Status API (VPS)

### Purpose
Expose current task status for personal website to display in real-time.

### Endpoints
```
POST /api/status  ← Mac app pushes every ~1 sec
GET /api/status   ← Website polls every ~3-5 sec
```

### Payload
```json
{
  "task": "Coding",
  "elapsed": 3600,
  "color": "#3873fc",
  "active": true,
  "updatedAt": "2024-01-30T12:00:00Z"
}
```

### Implementation (on existing VPS)
- Simple in-memory store or JSON file
- No database needed
- Add to existing tasks.adrianwill.com or separate endpoint

### Mac App Integration
- `StatusPusher.swift` - URLSession POST every 1 sec when timer active
- Push `{"active": false}` when timer stops
- Handle network errors gracefully (don't block timer)

### Website Integration
- Fetch `/api/status` every 3-5 sec
- Display current task name + elapsed time
- Show "Not working" when `active: false`
