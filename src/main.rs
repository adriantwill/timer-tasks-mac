use accessibility::{AXUIElement, AXUIElementAttributes};
use clap::{Parser, Subcommand};
use directories::ProjectDirs;
use objc2_app_kit::NSWorkspace;
use objc2_foundation::{NSDate, NSRunLoop};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Default, Serialize, Deserialize)]
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
    trigger: Vec<Trigger>,
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
    Status,
    Edit { name: String, app: String },
    Daemon,
}
struct DetectedWindow {
    app: String,
    title: String,
}
fn main() {
    let cli = Cli::parse();
    let dir = ProjectDirs::from("com", "adrianwill", "project-progress").unwrap();
    let path = dir.data_dir();
    let tasks = path.join("tasks.json");
    fs::create_dir_all(path).expect("failed ot create app data directory");
    let mut app_state = match fs::read_to_string(&tasks) {
        Ok(text) => serde_json::from_str(&text).expect("failed to parse tasks.json"),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => AppState::default(),
        Err(err) => panic!("failed to read tasks.json: {err}"),
    };
    match cli.command {
        Commands::Add { name } => {
            let Ok(inital_app) = return_front_title() else {
                println!("detect is bad");
                return;
            };
            let trigger_app = loop {
                let Ok(current_app) = return_front_title() else {
                    println!("detect is bad");
                    return;
                };
                if current_app.title != inital_app.title || current_app.app != inital_app.app {
                    break current_app;
                }
                wait_one_second();
            };
            if let Some(task) = app_state.tasks.iter().find(|task| {
                task.trigger.iter().any(|trigger| {
                    trigger.app == trigger_app.app
                        && (trigger_app.title.contains(&trigger.title)
                            || trigger.title.contains(&trigger_app.title))
                })
            }) {
                println!("{} already has that app and title", task.name);
            } else {
                if let Some(task) = app_state.tasks.iter_mut().find(|task| task.name == name) {
                    if task.trigger.iter().any(|task| task.app == trigger_app.app) {
                        println!("only 1 trigger per app");
                        return;
                    } else {
                        task.trigger.push(Trigger {
                            app: trigger_app.app.to_string(),
                            title: trigger_app.title.to_string(),
                        });
                    }
                } else {
                    app_state.tasks.push(Task {
                        id: Uuid::new_v4().to_string(),
                        name: name,
                        time: 0,
                        trigger: vec![Trigger {
                            app: trigger_app.app.to_string(),
                            title: trigger_app.title.to_string(),
                        }],
                    });
                }
                write_json(&tasks, &mut app_state);
            }
        }
        Commands::List => {
            for task in &app_state.tasks {
                println!("{}: {}", task.id, task.name);
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
        Commands::Edit { name, app } => {}
        Commands::Daemon => loop {
            let Ok(detect) = return_front_title() else {
                println!("detect is bad");
                continue;
            };
            wait_one_second();
            println!("{}", detect.title);
            let curr_task_id = app_state
                .tasks
                .iter()
                .find(|task| {
                    task.trigger.iter().any(|trigger| {
                        trigger.app == detect.app
                            && (detect.title.contains(&trigger.title)
                                || trigger.title.contains(&detect.title))
                    })
                })
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
                write_json(&tasks, &mut app_state);
            }
        },
    }
}

fn wait_one_second() {
    let until = NSDate::dateWithTimeIntervalSinceNow(1.0);
    NSRunLoop::currentRunLoop().runUntilDate(&until);
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
    println!("{},{}", bundle_id, title);
    return Ok(DetectedWindow {
        app: bundle_id.to_string(),
        title,
    });
}

fn write_json(path: &PathBuf, app_state: &mut AppState) {
    let serialized = serde_json::to_string(&app_state).unwrap();
    fs::write(path, serialized).expect("failed to write tasks.json");
}
