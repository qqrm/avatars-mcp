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
    let personas_dir = repo_root.join("personas");
    let agents_path = repo_root.join("AGENTS.md");

    if !personas_dir.is_dir() {
        bail!("personas directory missing: {}", display(&personas_dir));
    }
    if !agents_path.is_file() {
        bail!("AGENTS.md missing: {}", display(&agents_path));
    }

    personas_core::generate_index(&personas_dir, &agents_path)
        .with_context(|| format!("generate catalog for {}", display(&personas_dir)))?;
    println!("wrote {}", display(&personas_dir.join("catalog.json")));

    Ok(())
}

fn display(path: &Path) -> String {
    path.display().to_string()
}
