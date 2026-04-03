use std::io;
use std::time::Instant;
fn main() {
    let mut input = String::new();
    let mut start: Option<Instant> = None;
    loop {
        input.clear();
        io::stdin()
            .read_line(&mut input)
            .expect("you failed to read line");
        if input.trim() == "start" {
            start = Some(Instant::now());
        } else if input.trim() == "stop" {
            if let Some(s) = start {
                let elapsed = s.elapsed();
                println!("It has been {}", elapsed.as_secs());
                start = None
            } else {
                println!("Timer not started");
            }
        }
    }
}
