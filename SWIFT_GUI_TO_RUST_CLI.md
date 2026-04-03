# Swift GUI to Rust CLI + Daemon

## Goal

Port prior macOS SwiftUI app into a Rust binary without losing core behavior:

- task list
- categories
- triggers by app bundle id
- triggers by window title
- active task timer
- auto-switch when frontmost app/window changes
- persistent local storage

The Rust binary should do 2 jobs:

- CLI for CRUD/admin
- background daemon for auto timer switching

Current Rust app is only a `clap` stub in [src/main.rs](/Users/adrianwill/Dev/timer-tasks-mac/src/main.rs). This doc maps old Swift app shape to a Rust CLI + daemon design.

## What the Swift app actually did

Final Swift impl in git history (`5a17e50`) had 3 main parts:

1. Data models
   - `TimerTask`
   - `TaskTrigger`
   - `Category`
2. Runtime services
   - `TimerManager`: increments active task every second
   - `AppMonitor`: watches frontmost app + focused window title, auto-starts/stops tasks
3. UI
   - list tasks
   - add task/category
   - add trigger from installed app
   - add trigger from running window title
   - reorder by priority

The important part for Rust is not the GUI. It is:

- domain model
- CRUD surface
- monitor loop
- timer runtime

## Core domain to preserve

### `TimerTask`

Needs:

- `id: Uuid`
- `title: String`
- `priority: i32`
- `target_time_secs: Option<i64>`
- `elapsed_secs: i64`
- `is_manual_complete: bool`
- `category_id: Option<Uuid>`
- `created_at`
- `updated_at`

### `TaskTrigger`

Needs:

- `id: Uuid`
- `task_id: Uuid`
- `bundle_id: String`
- `title: Option<String>`
- `is_exact_title_match: bool`
- `previous_active: bool`

Matching rules from Swift:

- if `title == None`, match only on bundle id
- if `title != None`, match bundle id + title
- exact or contains match based on `is_exact_title_match`
- optional guard: only match if same task was previously active when `previous_active == true`

### `Category`

Needs:

- `id: Uuid`
- `name: String`
- `color: [f32; 3]` or hex string

For CLI, color is metadata only. No need for rich GUI color handling.

## Swift concept -> Rust concept

| Swift app | Rust CLI |
|---|---|
| `SwiftData` models | SQLite or JSON-backed structs |
| `ModelContext` | repository layer |
| `@Query(sort: \\TimerTask.priority)` | repository query with explicit sort |
| `TimerManager.shared` | app state service with active task + ticker loop |
| `AppMonitor.shared` | macOS monitor service |
| SwiftUI list/forms | `clap` subcommands |
| scene lifecycle save | explicit save after mutations + periodic flush |
| app picker / window picker | CLI args + helper commands to inspect apps/windows |

## Best Rust shape

Use 5 layers.

### 1. `model`

Pure structs + matching logic.

Suggested files:

- `src/model/task.rs`
- `src/model/trigger.rs`
- `src/model/category.rs`

### 2. `store`

Persistence layer.

Two viable options:

1. SQLite
   - best for long-term
   - easier filtering/sorting
   - safer writes
2. JSON file
   - fastest to build
   - enough for early CLI

Recommendation: start JSON, move to SQLite only if needed.

Reason: old Swift app was small, single-user, local-only.

Suggested path:

- `~/Library/Application Support/timer-tasks-mac/data.json`

That mirrors the Swift app using app support storage.

### 3. `runtime`

Holds:

- active task state
- timer tick loop
- app/window monitor loop
- trigger evaluation

Suggested files:

- `src/runtime/timer.rs`
- `src/runtime/monitor.rs`
- `src/runtime/matcher.rs`

### 4. `cli`

Maps user commands to store/runtime actions.

Suggested files:

- `src/cli.rs`
- `src/main.rs`

### 5. `daemon`

Long-running background entrypoint.

Suggested file:

- `src/daemon.rs`

## Binary mode split

The binary should support 2 operating modes.

### Mode 1: CLI admin

Short-lived commands for users to manage data.

Examples:

```bash
timer-tasks task add "Design App" --category Work
timer-tasks task list
timer-tasks task delete <task-id>
timer-tasks trigger add-app <task-id> com.microsoft.VSCode
```

### Mode 2: daemon

Long-running background process.

Example:

```bash
timer-tasks daemon
```

This process should:

- load persisted data
- detect frontmost app/window
- match triggers
- start/stop task timers
- persist changes

## CLI feature mapping

### CRUD

Swift GUI actions become commands like:

```bash
timer-tasks task add "Design App" --category Work
timer-tasks task list
timer-tasks task delete <task-id>
timer-tasks category add Work --color '#296ef2'
timer-tasks trigger add-app <task-id> com.microsoft.VSCode
timer-tasks trigger add-window <task-id> com.microsoft.VSCode --title "Linear"
timer-tasks task move <task-id> --priority 0
```

### Manual timing

Replaces clicking row play/stop:

```bash
timer-tasks start <task-id>
timer-tasks stop
timer-tasks status
```

### Auto tracking daemon

Replaces `AppMonitor.startMonitoring()` and `TimerManager.shared` running in memory:

```bash
timer-tasks daemon
```

This long-running command should:

- poll frontmost app every 1s
- read focused window title
- compare against triggers
- switch active task when matched
- stop timer when no task matches
- persist elapsed time periodically

### Discovery helpers

Swift used open panels and accessibility APIs to pick apps/windows. CLI should expose inspect commands instead:

```bash
timer-tasks inspect frontmost
timer-tasks inspect windows --bundle-id com.microsoft.VSCode
timer-tasks inspect apps
```

## macOS integration details

The Swift app relied on:

- `NSWorkspace.shared.frontmostApplication`
- Accessibility APIs for focused window title

Rust CLI will need same macOS-only capabilities.

Practical approach:

1. Keep CLI cross-platform at domain/store layer
2. Put monitoring behind `cfg(target_os = "macos")`
3. Implement mac monitor using one of:
   - AppleScript via `osascript` for quick bootstrap
   - direct CoreFoundation / AX APIs via crates or FFI for robust impl

Recommendation:

1. bootstrap with `osascript`
2. replace with AX FFI later if reliability/perf needs it

Reason: fastest path to parity.

Possible helper calls:

- frontmost app bundle id via AppleScript/System Events
- front window title via AppleScript when app exposes it
- fallback to AX API later for stricter parity

Risk: AppleScript window-title access is less reliable across apps than AX.

## Rust crates worth using

Minimal set:

- `clap` for CLI
- `serde`
- `serde_json`
- `uuid`
- `chrono`
- `dirs`
- `anyhow`

Maybe later:

- `rusqlite` if moving to SQLite
- `tokio` if async daemon becomes useful
- `tracing` + `tracing-subscriber` for daemon logs

## Suggested data format

If JSON:

```json
{
  "tasks": [],
  "categories": [],
  "triggers": [],
  "active_task_id": null,
  "active_started_at": null
}
```

Important: do not store only accumulated `elapsed_secs`.

Also store runtime timing metadata so daemon restart can recover sanely:

- `active_task_id`
- `active_started_at`
- `last_tick_at`

## Matching logic to port exactly

From Swift `AppMonitor`:

1. read frontmost bundle id
2. read current window title
3. load tasks sorted by priority ascending
4. first matching task wins
5. if a different task matches, stop old timer and start new one
6. if none match, stop active timer

This priority-ordered first-match behavior matters. Keep it.

## Recommended implementation order

### Phase 1

Build non-daemon CLI:

- models
- JSON store
- task/category/trigger CRUD
- priority reorder
- `start`, `stop`, `status`

### Phase 2

Build daemon timing loop:

- keep active task in persisted state
- tick every second
- flush every few seconds
- restore active task on restart if desired

### Phase 3

Build macOS monitor:

- inspect frontmost app
- inspect focused window title
- trigger matching
- auto-switch task

### Phase 4

Hardening:

- file locking
- crash-safe writes
- migration path JSON -> SQLite if needed
- better logs

## Working Checklist

Mark these off as each step is completed.

- [ ] manual timer REPL
  - commands: `start`, `stop`, `status`, `quit`
  - goal: learn `Option`, `Duration`, `Instant`, loops, stdin
- [ ] add task model
  - create `Task` struct
  - start timer for a named task
  - hardcode tasks first if needed
- [ ] persist tasks + elapsed time
  - save/load JSON with `serde`
  - make state survive restart
- [ ] move to real CLI commands
  - keep `clap`
  - add `task add`, `task list`, `start <id>`, `stop`, `status`
- [ ] add long-running daemon loop
  - add `daemon` command
  - poll every second
  - update timer state without stdin
- [ ] add macOS detection
  - first fake detector
  - then real frontmost app/window detection

## Proposed repo shape

```text
src/
  main.rs
  cli.rs
  app.rs
  model/
    mod.rs
    task.rs
    trigger.rs
    category.rs
  store/
    mod.rs
    json_store.rs
  runtime/
    mod.rs
    timer.rs
    matcher.rs
    monitor.rs
```

## Example command surface

```bash
timer-tasks task add "Write docs" --category Work
timer-tasks task list
timer-tasks task move 0c1... --priority 1
timer-tasks trigger add-app 0c1... com.apple.Safari
timer-tasks trigger add-window 0c1... com.microsoft.VSCode --title "timer-tasks-mac"
timer-tasks daemon
timer-tasks status
```

## Biggest behavior diffs vs Swift GUI

- no visual task list; all task interaction becomes commands
- no `NSOpenPanel`; bundle ids/titles must come from args or inspect commands
- no SwiftData autosave; Rust must explicitly persist
- no SwiftUI reactive state; CLI daemon owns runtime state

## Bottom line

This is not really a GUI port problem. It is:

1. port data model
2. build CLI CRUD surface with `clap`
3. port trigger matcher
4. port timer loop
5. reimplement macOS foreground-window detection
6. run all auto-tracking inside a daemon command

If done in that order, the Rust binary can reach feature parity with the old Swift app without needing any GUI layer.
