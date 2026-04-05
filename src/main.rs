use std::io;
use std::time::Instant;
struct Task {
    name: String,
    time: u64,
    started: bool,
}
fn main() {
    let mut input = String::new();
    let mut start: Option<Instant> = None;
    let mut tasks: Vec<Task> = Vec::new();
    tasks.push(Task {
        name: String::from("test"),
        time: 0,
        started: false,
    });
    tasks.push(Task {
        name: String::from("test1"),
        time: 0,
        started: false,
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
                if task.started {
                    println!("Timer already started for this task");
                } else {
                    start = Some(Instant::now());
                    task.started = true;
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
                if task.started
                    && let Some(s) = start
                {
                    let elapsed = s.elapsed();
                    println!("{} took {} seconds", task.name, elapsed.as_secs());
                    task.time += elapsed.as_secs();
                    task.started = false;
                    start = None;
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
