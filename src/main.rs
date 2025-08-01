use std::fs;
use std::path::Path;
use serde::{Serialize, Deserialize};

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

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let avatars_dir = Path::new("avatars");
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
    println!("Index generated with {} avatars", index.len());
    Ok(())
}
