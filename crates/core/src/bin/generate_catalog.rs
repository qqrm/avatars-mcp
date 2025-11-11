use anyhow::{Context, Result, bail};
use std::env;
use std::path::Path;

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let repo_root = env::current_dir().context("determine repository root")?;
    let avatars_dir = repo_root.join("avatars");
    let agents_path = repo_root.join("AGENTS.md");

    if !avatars_dir.is_dir() {
        bail!("avatars directory missing: {}", display(&avatars_dir));
    }
    if !agents_path.is_file() {
        bail!("AGENTS.md missing: {}", display(&agents_path));
    }

    avatars_core::generate_index(&avatars_dir, &agents_path)
        .with_context(|| format!("generate catalog for {}", display(&avatars_dir)))?;
    println!("wrote {}", display(&avatars_dir.join("catalog.json")));

    Ok(())
}

fn display(path: &Path) -> String {
    path.display().to_string()
}
