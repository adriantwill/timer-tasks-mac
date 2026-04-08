use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

#[derive(Serialize, Deserialize)]
struct AppState {
    tasks: Vec<Task>,
    started_task_id: Option<String>,
    started_at: Option<u64>,
}

#[derive(Serialize, Deserialize)]
struct Task {
    id: String,
    name: String,
    time: u64,
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
            if app_state.started_at.is_some() {
                println!("A timer has already started");
            } else {
                app_state.started_task_id = Some(task.id.clone());
                app_state.started_at = Some(
                    SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap()
                        .as_secs(),
                );
                let serialized = serde_json::to_string(&app_state).unwrap();
                fs::write("tasks.json", serialized).expect("failed to write tasks.json");
            }
        }
        Commands::Stop => {
            if let (Some(task_id), Some(s)) = (app_state.started_task_id, app_state.started_at) {
                let Some(task) = app_state.tasks.iter_mut().find(|task| task.id == task_id) else {
                    println!("Task not found");
                    return;
                };
                let elapsed = SystemTime::now()
                    .duration_since(UNIX_EPOCH)
                    .unwrap()
                    .as_secs()
                    - s;
                println!("{} took {} seconds", task.name, elapsed);
                task.time += elapsed;
                app_state.started_task_id = None;
                app_state.started_at = None;
                let serialized = serde_json::to_string(&app_state).unwrap();
                fs::write("tasks.json", serialized).expect("failed to write app_state.tasks.json");
            }
        }
        Commands::Status => {
            for task in &app_state.tasks {
                let (progress, task_time) = if Some(task.id.clone()) == app_state.started_task_id
                    && let Some(s) = app_state.started_at
                {
                    (
                        "In Progress",
                        task.time
                            + SystemTime::now()
                                .duration_since(UNIX_EPOCH)
                                .unwrap()
                                .as_secs()
                            - s,
                    )
                } else {
                    ("Paused", task.time)
                };
                println!("{}: {} seconds ({})", task.name, task_time, progress);
            }
        }
    }
}
