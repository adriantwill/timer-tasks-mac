use std::io;
use std::time::Instant;
struct Task {
    id: usize,
    name: String,
    time: u64,
}
fn main() {
    let mut input = String::new();
    let mut start: Option<Instant> = None;
    let mut started_task: Option<usize> = None;
    let mut tasks: Vec<Task> = Vec::new();
    tasks.push(Task {
        id: 0,
        name: String::from("test"),
        time: 0,
    });
    tasks.push(Task {
        id: 1,
        name: String::from("test1"),
        time: 0,
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
                if start.is_some() {
                    println!("A timer has already started");
                } else {
                    start = Some(Instant::now());
                    started_task = Some(task.id);
                }
            }
            Some(&"stop") => {
                let Some(task) = tasks.iter_mut().find(|task| Some(task.id) == started_task) else {
                    println!("Task not started");
                    continue;
                };
                if let Some(s) = start {
                    let elapsed = s.elapsed();
                    println!("{} took {} seconds", task.name, elapsed.as_secs());
                    task.time += elapsed.as_secs();
                    started_task = None;
                    start = None;
                } else {
                    println!("Timer not started for this task");
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
                return;
            }
            _ => {
                println!("Invalid command, enter stop or start");
            }
        }
    }
}
