use avatars_generator::generate_index;
use std::path::Path;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let avatars_dir = Path::new("avatars");
    let base_path = Path::new("BASE_AGENTS.md");
    let index = generate_index(avatars_dir, base_path)?;
    println!("Index generated with {} avatars", index.avatars.len());
    Ok(())
}
