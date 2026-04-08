use accessibility::{AXUIElement, AXUIElementAttributes};
use clap::{Parser, Subcommand};
use objc2_app_kit::NSWorkspace;
use objc2_foundation::{NSDate, NSRunLoop};
use serde::{Deserialize, Serialize};
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Serialize, Deserialize)]
struct AppState {
    tasks: Vec<Task>,
    started_task: Option<StartedTask>,
}

#[derive(Serialize, Deserialize)]
struct StartedTask {
    task_id: String,
    started_at: u64,
}
#[derive(Serialize, Deserialize)]
struct Task {
    id: String,
    name: String,
    time: u64,
    trigger: Trigger,
}
#[derive(Serialize, Deserialize)]
struct Trigger {
    app: String,
    title: String,
}
#[derive(Parser, Debug)]
#[command(name = "timer-tasks")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}
#[derive(Subcommand, Debug)]
enum Commands {
    Add { name: String },
    List,
    Start { task_name: String },
    Stop,
    Status,
    Test,
    Daemon,
}
struct DetectedWindow {
    app: String,
    title: String,
}
fn main() {
    let cli = Cli::parse();
    let text = fs::read_to_string("tasks.json").expect("failed to read tasks.json");
    let mut app_state: AppState = serde_json::from_str(&text).unwrap();
    match cli.command {
        Commands::Add { name } => {
            app_state.tasks.push(Task {
                id: Uuid::new_v4().to_string(),
                name: name,
                time: 0,
                trigger: Trigger {
                    app: "".to_string(),
                    title: "".to_string(),
                },
            });
            let serialized = serde_json::to_string(&app_state).unwrap();
            fs::write("tasks.json", serialized).expect("failed to write tasks.json");
        }
        Commands::List => {
            for task in &app_state.tasks {
                println!("{}: {}", task.id, task.name);
            }
        }
        Commands::Start { task_name } => {
            let Some(task) = app_state
                .tasks
                .iter_mut()
                .find(|task| task.id == *task_name)
            else {
                println!("Task not found");
                return;
            };
            if app_state.started_task.is_some() {
                println!("A timer has already started");
                return;
            }

            app_state.started_task = Some(StartedTask {
                task_id: task.id.clone(),
                started_at: SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_secs(),
            });
            let serialized = serde_json::to_string(&app_state).unwrap();
            fs::write("tasks.json", serialized).expect("failed to write tasks.json");
        }
        Commands::Stop => {
            if let Some(started_task) = app_state.started_task.take() {
                let Some(task) = app_state
                    .tasks
                    .iter_mut()
                    .find(|task| task.id == started_task.task_id)
                else {
                    println!("Task not found");
                    return;
                };
                let elapsed = now() - started_task.started_at;
                println!("{} took {} seconds", task.name, elapsed);
                task.time += elapsed;
                let serialized = serde_json::to_string(&app_state).unwrap();
                fs::write("tasks.json", serialized).expect("failed to write tasks.json");
            }
        }
        Commands::Status => {
            for task in &app_state.tasks {
                let (progress, task_time) = if let Some(started_task) = &app_state.started_task
                    && started_task.task_id == task.id
                {
                    ("In Progress", task.time + now() - started_task.started_at)
                } else {
                    ("Paused", task.time)
                };
                println!("{}: {} seconds ({})", task.name, task_time, progress);
            }
        }
        Commands::Test => {
            if let Err(err) = return_front_title() {
                println!("{err:?} err");
            }
        }
        Commands::Daemon => loop {
            let detected = return_front_title();
            let until = NSDate::dateWithTimeIntervalSinceNow(1.0);
            NSRunLoop::currentRunLoop().runUntilDate(&until);
            let Ok(detect) = detected else {
                println!("detect is bad");
                continue;
            };
            println!("{}", detect.title);
            let curr_task_id = app_state
                .tasks
                .iter()
                .find(|task| task.trigger.app == detect.app && task.trigger.title == detect.title)
                .map(|task| task.id.clone());

            let prev_task_id = app_state
                .started_task
                .as_ref()
                .map(|started| started.task_id.clone());

            let changed = prev_task_id != curr_task_id;

            if prev_task_id.is_some() {
                add_elapsed_to_task(&mut app_state);
                if changed {
                    app_state.started_task = None;
                }
            }
            let should_write = prev_task_id.is_some() || (curr_task_id.is_some() && changed);
            if let Some(task_id) = curr_task_id
                && changed
            {
                app_state.started_task = Some(StartedTask {
                    task_id: task_id.clone(),
                    started_at: now(),
                });
            };
            if should_write {
                write_json(&mut app_state);
            }
        },
    }
}

fn add_elapsed_to_task(app_state: &mut AppState) {
    if let Some(started_task) = app_state.started_task.as_mut() {
        if let Some(task) = app_state
            .tasks
            .iter_mut()
            .find(|task| task.id == started_task.task_id)
        {
            task.time += now() - started_task.started_at;
        }
        started_task.started_at = now();
    }
}
fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

fn return_front_title() -> Result<DetectedWindow, accessibility::Error> {
    let detected = DetectedWindow {
        app: "".to_string(),
        title: "".to_string(),
    };
    let Some(app) = NSWorkspace::sharedWorkspace().frontmostApplication() else {
        println!("No frontmost app");
        return Ok(detected);
    };
    let Some(bundle_id) = app.bundleIdentifier() else {
        println!("no front app bundle id");
        return Ok(detected);
    };
    let front = AXUIElement::application(app.processIdentifier());
    let title = match front.focused_window().and_then(|window| window.title()) {
        Ok(title) => title.to_string(),
        Err(_) => "".to_string(),
    };
    println!(
        "pid={} bundle_id={} title={}",
        app.processIdentifier(),
        bundle_id,
        title.to_string()
    );
    println!("{title:?} succ");
    return Ok(DetectedWindow {
        app: bundle_id.to_string(),
        title,
    });
}

fn write_json(app_state: &mut AppState) {
    let serialized = serde_json::to_string(&app_state).unwrap();
    fs::write("tasks.json", serialized).expect("failed to write tasks.json");
}
