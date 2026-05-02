# Swift GUI to Rust CLI + Daemon

## Goal

Port the old macOS SwiftUI timer app into one Rust binary.

Keep the core behavior:

- tasks with elapsed time
- apps/windows that activate a task
- active task timer
- auto-switch when frontmost app/window changes
- persistent local JSON storage

Do not preserve the GUI shape. The Rust app is allowed to feel like a small personal CLI tool.

## Previous Swift App

The Swift version had 3 main parts:

1. Data models
   - `TimerTask`
   - `TaskTrigger`
2. Runtime services
   - `TimerManager`: increments active task over time
   - `AppMonitor`: watches frontmost app + focused window title
3. UI workflows
   - list tasks
   - add task
   - add trigger from installed app
   - add trigger from running window title
   - manually start/stop task

Important behavior to preserve:

- a task can have one or more app/window matches
- a matching app/window starts that task
- switching apps/windows can switch active task
- no match stops active tracking
- elapsed time survives restart

## Current Rust CLI Direction

Keep the current flat CLI style.

Current command surface:

```bash
timer-tasks add <name>
timer-tasks status
timer-tasks edit <name> <app> <title>
timer-tasks delete <name> [app]
timer-tasks detect
timer-tasks daemon
```

Do not switch to nested commands like:

```bash
timer-tasks task add ...
timer-tasks trigger add-window ...
```

Those are more formal, but not needed for this project right now.

## Current Workflow

### Add

```bash
timer-tasks add "Write docs"
```

Current intended behavior:

1. Read current frontmost app/window.
2. Wait until user switches to a different app/window.
3. Use that new app/window as the trigger.
4. If task exists, add trigger to it.
5. If task does not exist, create task with that trigger.

This replaces the Swift GUI flow where the user picked an app/window from UI.

### Status

```bash
timer-tasks status
```

Shows all tasks and elapsed seconds.

This replaces the Swift task list.

### Edit

```bash
timer-tasks edit "Write docs" com.apple.Safari "Docs"
```

Changes the saved window title for an existing app trigger on a task.

This replaces editing trigger details in the GUI.

### Delete

```bash
timer-tasks delete "Write docs"
timer-tasks delete "Write docs" com.apple.Safari
```

Without app: delete whole task.

With app: delete only that task's app trigger.

### Daemon

```bash
timer-tasks daemon
```

Runs forever:

1. Read frontmost app/window.
2. Find first matching task.
3. If match changed, stop old task and start new one.
4. If no match, stop active task.
5. Persist elapsed time.

This replaces Swift `AppMonitor` + `TimerManager`.

### Detect

```bash
timer-tasks detect
```

Prints the current frontmost app bundle ID and focused window title once.

Use this before `add` or `daemon` to verify macOS detection and Accessibility permissions.

## Data Model

Current simple model is enough for now:

```rust
struct AppState {
    tasks: Vec<Task>,
    started_task: Option<StartedTask>,
}

struct Task {
    id: String,
    name: String,
    time: u64,
    trigger: Vec<Trigger>,
}

struct Trigger {
    app: String,
    title: String,
}

struct StartedTask {
    task_id: String,
    started_at: u64,
}
```

This is smaller than the Swift model. That is fine while learning and building the core loop.

Possible later fields from Swift:

- target time
- manual complete flag
- created/updated timestamps
- exact title match vs contains match
- app-only trigger with no title
- trigger ID

Do not add these until the current behavior is solid.

Accepted differences from Swift for now:

- no manual start/stop commands
- no exact title match option
- no `previous_active` trigger flag
- fuzzy title matching is preferred
- bad hand-edited JSON does not need full migration support yet
- daemon logs can stay rough until behavior is stable

## Matching Rule

Current matcher should be one function.

Goal:

```rust
fn matching_task_id(tasks: &[Task], detect: &DetectedWindow) -> Option<String>
```

Rules:

1. First matching task wins.
2. App must match exactly.
3. Title match is fuzzy by design.

Current accepted rule:

```text
trigger.app == detect.app && detect.title.contains(&trigger.title)
```

An empty trigger title can match any window title for that app. This is acceptable because duplicate tasks/triggers are prevented through the CLI, and hand-editing JSON is outside the main user path.

## Suggested File Shape Later

Keep `src/main.rs` while learning if that helps.

Split only when the file feels painful:

```text
src/
  main.rs
  model.rs
  store.rs
  matcher.rs
  macos.rs
```

No need for a large architecture yet.

## Swift GUI vs Rust CLI

| Swift GUI behavior | Rust CLI behavior |
|---|---|
| Visual task list | `status` |
| Add task form | `add <name>` |
| Pick app/window in UI | switch to app/window while `add` waits |
| Edit trigger in UI | `edit <name> <app> <title>` |
| Delete task/trigger in UI | `delete <name> [app]` |
| Inspect current app/window | `detect` |
| `TimerManager` in app memory | `daemon` loop |
| `AppMonitor` using macOS APIs | `return_front_title()` |
| SwiftData autosave | explicit JSON writes |

## Progress

- [x] basic task model
- [x] JSON load/save
- [x] flat `clap` CLI
- [x] add task/trigger through current app switch workflow
- [x] status output
- [x] edit trigger title
- [x] delete task or trigger
- [x] detect current app/window
- [x] basic daemon loop
- [x] basic macOS frontmost app/window detection
- [x] make matcher rule explicit and shared everywhere
- [x] accept empty-title fuzzy matching
- [x] accept no manual start/stop commands
- [x] accept simplified trigger model for now
- [x] accept rough daemon logs for now
- [ ] add tests for matcher
- [ ] reduce repeated lookup/save code
- [ ] optionally make JSON parse errors print clearer message

## What To Do Next

1. Add matcher tests.
   - App mismatch returns `None`.
   - App match + title contains returns task ID.
   - Empty title matches app-only behavior.
   - First matching task wins.

2. Clean small repeated code.
   - `load_state(path)`
   - `task_has_app_trigger(task, app)`
   - `wait_for_front_change(initial)`
   - maybe `find_task_mut(tasks, name)`

3. Improve persistence errors.
   - If `tasks.json` is missing, use empty state.
   - If `tasks.json` has bad shape, print a clear error.
   - Write after every successful mutation.

4. Then improve daemon polish.
   - Remove noisy debug prints or make them intentional logs.
   - Save elapsed time on each tick or fixed interval.
   - Keep behavior stable when no app/window title is available.

## Bottom Line

You are no longer trying to copy the Swift UI. You are keeping the old app's behavior and expressing it through your simpler CLI:

1. `status` replaces the list UI.
2. `add` plus app switching replaces picker UI.
3. `edit` and `delete` replace trigger management UI.
4. `daemon` replaces Swift runtime services.

Next best work: add matcher tests and clean repeated lookup/save code.
