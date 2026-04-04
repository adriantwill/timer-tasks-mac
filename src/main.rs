use std::io;
use std::time::Instant;
struct Task {
    name: String,
    time: u64,
    started: Option<Instant>,
}
fn main() {
    let mut input = String::new();
    let mut tasks: Vec<Task> = Vec::new();
    tasks.push(Task {
        name: String::from("test"),
        time: 0,
        started: None,
    });
    tasks.push(Task {
        name: String::from("test1"),
        time: 0,
        started: None,
    });
    loop {
        input.clear();
        io::stdin()
            .read_line(&mut input)
            .expect("you failed to read line");
        let parts: Vec<&str> = input.trim().split_whitespace().collect();
        match parts.get(0) {
            Some(&"start") => {
                let Some(task_name) = parts.get(1) else {
                    println!("Enter a task name");
                    continue;
                };
                let Some(task) = tasks.iter_mut().find(|task| task.name == *task_name) else {
                    println!("Task not found");
                    continue;
                };
                if task.started.is_none() {
                    task.started = Some(Instant::now());
                } else {
                    println!("Timer already started for this task");
                }
            }
            Some(&"stop") => {
                let Some(task_name) = parts.get(1) else {
                    println!("Enter a task name");
                    continue;
                };
                let Some(task) = tasks.iter_mut().find(|task| task.name == *task_name) else {
                    println!("Task not found");
                    continue;
                };
                if let Some(started) = task.started {
                    let elapsed = started.elapsed();
                    println!("{} took {} seconds", task.name, elapsed.as_secs());
                    task.time += elapsed.as_secs();
                    task.started = None;
                } else {
                    println!("Timer not started for this task");
                }
            }
            Some(&"status") => {
                for task in &tasks {
                    println!("{}: {} seconds", task.name, task.time);
                }
            }
            Some(&"quit") => {
                return;
            }
            _ => {
                println!("Invalid command, enter stop or start");
            }
        }
    }
}
