use serde::{Deserialize, Serialize};
use std::fs;
use std::io;
use std::time::Instant;

#[derive(Serialize, Deserialize)]
struct Task {
    id: usize,
    name: String,
    time: u64,
}
fn main() {
    let mut input = String::new();
    let mut start: Option<Instant> = None;
    let mut started_task: Option<usize> = None;
    let text = fs::read_to_string("tasks.json").expect("failed to read tasks.json");
    let mut tasks: Vec<Task> = serde_json::from_str(&text).unwrap();
    // tasks.push(Task {
    //     id: 1,
    //     name: String::from("test1"),
    //     time: 0,
    // });
    loop {
        input.clear();
        io::stdin()
            .read_line(&mut input)
            .expect("you failed to read line");
        let parts: Vec<&str> = input.trim().split_whitespace().collect();
        match parts.get(0) {
            Some(&"add") => {
                tasks.push(Task {
                    id: 0,
                    name: String::from("test"),
                    time: 0,
                });
            }
            Some(&"start") => {
                let Some(task_name) = parts.get(1) else {
                    println!("Enter a task name");
                    continue;
                };
                let Some(task) = tasks.iter_mut().find(|task| task.name == *task_name) else {
                    println!("Task not found");
                    continue;
                };
                if start.is_some() {
                    println!("A timer has already started");
                } else {
                    start = Some(Instant::now());
                    started_task = Some(task.id);
                }
            }
            Some(&"stop") => {
                if let (Some(task_id), Some(s)) = (started_task, start) {
                    let Some(task) = tasks.iter_mut().find(|task| task.id == task_id) else {
                        println!("Task not found");
                        continue;
                    };
                    let elapsed = s.elapsed();
                    println!("{} took {} seconds", task.name, elapsed.as_secs());
                    task.time += elapsed.as_secs();
                    let serialized = serde_json::to_string(&tasks).unwrap();
                    fs::write("tasks.json", serialized).expect("failed to write tasks.json");
                    started_task = None;
                    start = None;
                }
            }
            Some(&"status") => {
                for task in &tasks {
                    let (progress, task_time) = if Some(task.id) == started_task
                        && let Some(s) = start
                    {
                        ("In Progress", task.time + s.elapsed().as_secs())
                    } else {
                        ("Paused", task.time)
                    };
                    println!("{}: {} seconds ({})", task.name, task_time, progress);
                }
            }
            Some(&"quit") | Some(&"exit") => {
                if start.is_some() {
                    println!("Task in progress, stop it first");
                } else {
                    return;
                }
            }
            _ => {
                println!("Invalid command, enter stop or start");
            }
        }
    }
}
