use std::env;
use std::error::Error;
use std::path::Path;

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), Box<dyn Error>> {
    let repo_root = env::current_dir()?;
    let avatars_dir = repo_root.join("avatars");
    let agents_path = repo_root.join("AGENTS.md");

    if !avatars_dir.is_dir() {
        return Err(format!("avatars directory missing: {}", display(&avatars_dir)).into());
    }
    if !agents_path.is_file() {
        return Err(format!("AGENTS.md missing: {}", display(&agents_path)).into());
    }

    codex_tools_core::generate_index(&avatars_dir, &agents_path)?;
    println!("wrote {}", display(&avatars_dir.join("catalog.json")));

    Ok(())
}

fn display(path: &Path) -> String {
    path.display().to_string()
}
