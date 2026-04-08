use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::fs;
use std::io;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Serialize, Deserialize)]
struct AppState {
    tasks: Vec<Task>,
    started_task_id: Option<usize>,
    started_at: Option<u64>,
}

#[derive(Serialize, Deserialize)]
struct Task {
    id: usize,
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
    Start { id: i32 },
    Stop,
    Status,
}
fn main() {
    let cli = Cli::parse();

    let mut input = String::new();
    let text = fs::read_to_string("tasks.json").expect("failed to read tasks.json");
    let mut app_state: AppState = serde_json::from_str(&text).unwrap();
    let mut tasks = app_state.tasks;
    // tasks.push(Task {
    //     id: 1,
    //     name: String::from("test1"),
    //     time: 0,
    // });
    input.clear();
    io::stdin()
        .read_line(&mut input)
        .expect("you failed to read line");
    let parts: Vec<&str> = input.trim().split_whitespace().collect();
    match cli.command {
        Commands::Add { name } => {
            tasks.push(Task {
                id: 0,
                name: String::from("test"),
                time: 0,
            });
        }
        Commands::Start { id } => {
            let Some(task_name) = parts.get(1) else {
                println!("Enter a task name");
                return;
            };
            let Some(task) = tasks.iter_mut().find(|task| task.name == *task_name) else {
                println!("Task not found");
                return;
            };
            if app_state.started_at.is_some() {
                println!("A timer has already started");
            } else {
                app_state.started_task_id = Some(task.id);
                app_state.started_at = Some(
                    SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap()
                        .as_secs(),
                );
            }
        }
        Commands::Stop => {
            if let (Some(task_id), Some(s)) = (app_state.started_task_id, app_state.started_at) {
                let Some(task) = tasks.iter_mut().find(|task| task.id == task_id) else {
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
                let serialized = serde_json::to_string(&tasks).unwrap();
                fs::write("tasks.json", serialized).expect("failed to write tasks.json");
                app_state.started_task_id = None;
                app_state.started_at = None;
            }
        }
        Commands::Status => {
            for task in &tasks {
                let (progress, task_time) = if Some(task.id) == app_state.started_task_id
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
        _ => {
            println!("Invalid command, enter stop or start");
        }
    }
}
