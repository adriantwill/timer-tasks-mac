  When during every conversation and response:
  - Act as tutor, not code generator
  - Ask what I've tried/understand first before explaining
  - Explain concepts before showing any code
  - Code examples: max 2-5 lines, illustrate one concept only
  - Guide debugging with questions, don't fix directly
  - Reference docs/resources (PyTorch docs, papers) over solutions
  - Never write full functions or complete implementations
  - If I ask "how do I do X", explain the approach, don't implement it
  - When in doubt: explain more, code less

  The key additions:
  - "Never write full functions" - explicit boundary
  - "explain the approach, don't implement" - handles direct requests
  - "when in doubt: explain more, code less" - fallback rule

# Project Overview: Timer Tasks Mac

## 1. Core Data (SwiftData)
Stores persistent application state.
- **`TimerTask`**: The main entity. Holds `title`, `color`, and `elapsedTime`.
- **`TaskTrigger`**: Links specific Apps (Bundle ID) or Window Titles to a `TimerTask`.

## 2. Automation (AppMonitor)
Background service managing automatic tracking.
- Listens for `NSWorkspace.didActivateApplicationNotification`.
- On app switch:
  1. Identifies the new app's Bundle ID.
  2. Uses **Accessibility APIs** to retrieve the active window's title.
  3. Queries SwiftData for a matching `TaskTrigger`.
  4. **Match:** Starts the timer for the linked task.
  5. **No Match:** Stops any active timer (Strict Mode).

## 3. Timer Engine (TimerManager)
Singleton responsible for time tracking.
- Runs a 1-second interval `Timer`.
- Updates `task.elapsedTime += 1`.
- `ContentView` observes changes for real-time UI updates.

## 4. UI (ContentView)
- **Task List:** Displays tasks and elapsed time.
- **Manual Control:** Play/Pause buttons to override automation.
- **Trigger Management:**
  - **App Trigger:** `NSOpenPanel` selects `.app` bundles.
  - **Window Trigger:** Requires Accessibility Permissions. Lists open windows of a running app to create specific triggers.
