use serde::{Deserialize, Serialize};
use std::fs;
use std::path::Path;
#[cfg(test)]
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Debug)]
struct AvatarMeta {
    id: String,
    name: String,
    description: Option<String>,
    tags: Option<Vec<String>>,
    author: Option<String>,
    created_at: Option<String>,
    version: Option<String>,
}

fn parse_front_matter(content: &str) -> Option<(&str, &str)> {
    let mut parts = content.splitn(3, "---");
    parts.next()?; // before first ---
    let fm = parts.next()?;
    let rest = parts.next().unwrap_or("");
    Some((fm.trim(), rest))
}

fn generate_index(avatars_dir: &Path) -> Result<Vec<AvatarMeta>, Box<dyn std::error::Error>> {
    let mut index: Vec<AvatarMeta> = Vec::new();
    for entry in fs::read_dir(avatars_dir)? {
        let entry = entry?;
        if entry.path().extension().and_then(|s| s.to_str()) == Some("md") {
            let content = fs::read_to_string(entry.path())?;
            if let Some((fm, _)) = parse_front_matter(&content) {
                let meta: AvatarMeta = serde_yaml::from_str(fm)?;
                index.push(meta);
            }
        }
    }
    let json = serde_json::to_string_pretty(&index)?;
    fs::write(avatars_dir.join("index.json"), json + "\n")?;
    Ok(index)
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let avatars_dir = Path::new("avatars");
    let index = generate_index(avatars_dir)?;
    println!("Index generated with {} avatars", index.len());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn generates_index_with_all_avatars_and_fields() {
        let dir = tempdir().unwrap();
        let avatars_dir: PathBuf = dir.path().to_path_buf();

        let avatar1 = r#"---
id: "hero"
name: "Hero"
description: "Brave"
tags: ["brave", "strong"]
---"#;
        fs::write(avatars_dir.join("hero.md"), avatar1).unwrap();

        let avatar2 = r#"---
id: "villain"
name: "Villain"
---"#;
        fs::write(avatars_dir.join("villain.md"), avatar2).unwrap();

        let index = generate_index(&avatars_dir).unwrap();
        assert_eq!(index.len(), 2);

        let json = fs::read_to_string(avatars_dir.join("index.json")).unwrap();
        let value: serde_json::Value = serde_json::from_str(&json).unwrap();
        let arr = value.as_array().unwrap();
        assert_eq!(arr.len(), 2);

        let hero = arr.iter().find(|v| v["id"] == "hero").unwrap();
        assert_eq!(hero["name"], "Hero");
        assert_eq!(hero["description"], "Brave");
        assert_eq!(hero["tags"], serde_json::json!(["brave", "strong"]));

        let villain = arr.iter().find(|v| v["id"] == "villain").unwrap();
        assert_eq!(villain["name"], "Villain");
    }
}
