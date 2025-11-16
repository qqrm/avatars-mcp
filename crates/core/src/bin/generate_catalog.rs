use anyhow::{Context, Result, bail};
use std::env;
use std::path::{Path, PathBuf};

fn main() {
    if let Err(err) = run() {
        eprintln!("error: {err}");
        std::process::exit(1);
    }
}

fn run() -> Result<()> {
    let repo_root = env::current_dir().context("determine repository root")?;
    run_in_repo(&repo_root)
}

fn run_in_repo(repo_root: &Path) -> Result<()> {
    let repo_root = repo_root.to_path_buf();
    let paths = RepoPaths::new(repo_root);
    paths.validate()?;

    personas_core::generate_index(&paths.personas_dir, &paths.agents_path)
        .with_context(|| format!("generate catalog for {}", display(&paths.personas_dir)))?;
    println!("wrote {}", display(&paths.catalog_path()));

    Ok(())
}

struct RepoPaths {
    personas_dir: PathBuf,
    agents_path: PathBuf,
}

impl RepoPaths {
    fn new(repo_root: PathBuf) -> Self {
        let personas_dir = repo_root.join("personas");
        let agents_path = repo_root.join("AGENTS.md");
        Self {
            personas_dir,
            agents_path,
        }
    }

    fn validate(&self) -> Result<()> {
        if !self.personas_dir.is_dir() {
            bail!(
                "personas directory missing: {}",
                display(&self.personas_dir)
            );
        }
        if !self.agents_path.is_file() {
            bail!("AGENTS.md missing: {}", display(&self.agents_path));
        }
        Ok(())
    }

    fn catalog_path(&self) -> PathBuf {
        self.personas_dir.join("catalog.json")
    }
}

fn display(path: &Path) -> String {
    path.display().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn run_in_repo_writes_catalog() {
        let tmp = tempdir().expect("tempdir");
        let repo_root = tmp.path();
        let personas_dir = repo_root.join("personas");
        fs::create_dir(&personas_dir).expect("personas dir");
        fs::write(repo_root.join("AGENTS.md"), "# Test\n").expect("agents");
        fs::write(
            personas_dir.join("ONE.md"),
            "---\nid: one\nname: One\n---\nbody\n",
        )
        .expect("persona");

        run_in_repo(repo_root).expect("run");

        let catalog = personas_dir.join("catalog.json");
        let contents = fs::read_to_string(catalog).expect("catalog contents");
        assert!(contents.contains("\"id\": \"one\""));
    }

    #[test]
    fn missing_personas_dir_returns_error() {
        let tmp = tempdir().expect("tempdir");
        fs::write(tmp.path().join("AGENTS.md"), "# Test\n").expect("agents");
        let err = run_in_repo(tmp.path()).unwrap_err();
        let msg = err.to_string();
        assert!(msg.contains("personas directory missing"));
    }

    #[test]
    fn missing_agents_file_returns_error() {
        let tmp = tempdir().expect("tempdir");
        fs::create_dir(tmp.path().join("personas")).expect("personas");
        let err = run_in_repo(tmp.path()).unwrap_err();
        assert!(err.to_string().contains("AGENTS.md missing"));
    }
}
