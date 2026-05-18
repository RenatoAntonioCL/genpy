use std::env;

fn main() {
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());

    println!("Hello from {{PROJECT_NAME}}");
    println!("Running on port {}", port);
}