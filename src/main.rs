use serde::{Deserialize, Serialize};
use std::error::Error;
use std::fs;
use std::path::Path;

#[derive(Clone, Serialize, Deserialize, Debug, PartialEq)]
struct AvatarMeta {
    id: String,
    name: String,
    description: Option<String>,
    tags: Option<Vec<String>>,
    author: Option<String>,
    created_at: Option<String>,
    version: Option<String>,
}

#[derive(Serialize, Deserialize, Debug, PartialEq)]
struct RootIndex {
    base_instructions: String,
    avatars: Vec<AvatarMeta>,
    avatar_selection: String,
}

#[derive(Debug, PartialEq)]
enum FrontMatterError {
    Missing,
    Malformed,
}

impl std::fmt::Display for FrontMatterError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            FrontMatterError::Missing => write!(f, "front matter missing"),
            FrontMatterError::Malformed => write!(f, "front matter malformed"),
        }
    }
}

impl Error for FrontMatterError {}

fn parse_front_matter(content: &str) -> Result<(String, String), FrontMatterError> {
    let content = content.replace("\r\n", "\n");
    let after_first = content
        .strip_prefix("---\n")
        .ok_or(FrontMatterError::Missing)?;
    if let Some(rest) = after_first.strip_prefix("---\n") {
        return Ok((String::new(), rest.to_string()));
    }
    if after_first == "---" {
        return Ok((String::new(), String::new()));
    }
    if let Some(end) = after_first.find("\n---\n") {
        let fm = &after_first[..end];
        let rest = &after_first[end + 5..];
        return Ok((fm.trim().to_string(), rest.to_string()));
    }
    if let Some(fm) = after_first.strip_suffix("\n---") {
        return Ok((fm.trim().to_string(), String::new()));
    }
    Err(FrontMatterError::Malformed)
}

fn generate_index(avatars_dir: &Path) -> Result<Vec<AvatarMeta>, Box<dyn Error>> {
    let mut index: Vec<AvatarMeta> = Vec::new();
    for entry in fs::read_dir(avatars_dir)? {
        let entry = entry?;
        if entry.path().extension().and_then(|s| s.to_str()) == Some("md") {
            let content = fs::read_to_string(entry.path())?;
            let (fm, _) = parse_front_matter(&content)?;
            let meta: AvatarMeta = serde_yaml::from_str(&fm)?;
            index.push(meta);
        }
    }
    let json = serde_json::to_string_pretty(&index)?;
    fs::write(avatars_dir.join("index.json"), json + "\n")?;
    Ok(index)
}

fn generate_root_index(
    avatars: &[AvatarMeta],
    agents_path: &Path,
    output: &Path,
) -> Result<(), Box<dyn Error>> {
    let base = fs::read_to_string(agents_path)?;
    let root = RootIndex {
        base_instructions: base,
        avatars: avatars.to_vec(),
        avatar_selection:
            "Select an avatar that fits your task and fetch /avatars/{id}.md for details."
                .to_string(),
    };
    let json = serde_json::to_string_pretty(&root)?;
    fs::write(output, json + "\n")?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let avatars_dir = Path::new("avatars");
    let index = generate_index(avatars_dir)?;
    generate_root_index(&index, Path::new("AGENTS.md"), Path::new("index.json"))?;
    println!("Index generated with {} avatars", index.len());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_with_extra_delimiter() {
        let content = "---\nid: 1\n---\n---\nbody\n";
        let (fm, rest) = parse_front_matter(content).expect("should parse");
        assert_eq!(fm, "id: 1");
        assert_eq!(rest, "---\nbody\n");
    }

    #[test]
    fn errors_when_missing_front_matter() {
        let content = "id: 1\n---\nbody\n";
        let err = parse_front_matter(content).unwrap_err();
        assert_eq!(err, FrontMatterError::Missing);
    }

    #[test]
    fn errors_when_unclosed_front_matter() {
        let content = "---\nid: 1\nbody\n";
        let err = parse_front_matter(content).unwrap_err();
        assert_eq!(err, FrontMatterError::Malformed);
    }

    #[test]
    fn parses_windows_line_endings() {
        let content = "---\r\nid: 1\r\n---\r\nbody\r\n";
        let (fm, rest) = parse_front_matter(content).expect("should parse");
        assert_eq!(fm, "id: 1");
        assert_eq!(rest, "body\n");
    }

    #[test]
    fn errors_when_unclosed_front_matter_windows() {
        let content = "---\r\nid: 1\r\nbody\r\n";
        let err = parse_front_matter(content).unwrap_err();
        assert_eq!(err, FrontMatterError::Malformed);
    }
}

#[cfg(test)]
mod index_generation_tests {
    use super::*;
    use std::error::Error;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn generates_index_with_expected_fields() -> Result<(), Box<dyn Error>> {
        let tmp = tempdir()?;
        let dir = tmp.path();

        fs::write(
            dir.join("ONE.md"),
            "---\nid: one\nname: One\ndescription: First\n---\nbody\n",
        )?;
        fs::write(dir.join("TWO.md"), "---\nid: two\nname: Two\n---\nbody\n")?;

        let index = generate_index(dir)?;
        assert_eq!(index.len(), 2);

        let first = index.iter().find(|m| m.id == "one").unwrap();
        assert_eq!(first.name, "One");
        assert_eq!(first.description.as_deref(), Some("First"));

        let json = fs::read_to_string(dir.join("index.json"))?;
        let parsed: Vec<AvatarMeta> = serde_json::from_str(&json)?;
        assert_eq!(parsed, index);

        Ok(())
    }

    #[test]
    fn generates_root_index_with_base_and_avatars() -> Result<(), Box<dyn Error>> {
        let tmp = tempdir()?;
        let dir = tmp.path();

        fs::write(dir.join("AGENTS.md"), "base instructions")?;
        let avatars_dir = dir.join("avatars");
        fs::create_dir(&avatars_dir)?;
        fs::write(
            avatars_dir.join("ONE.md"),
            "---\nid: one\nname: One\ndescription: First\n---\nbody\n",
        )?;

        let avatars = generate_index(&avatars_dir)?;
        generate_root_index(&avatars, &dir.join("AGENTS.md"), &dir.join("index.json"))?;

        let json = fs::read_to_string(dir.join("index.json"))?;
        let parsed: RootIndex = serde_json::from_str(&json)?;
        assert_eq!(parsed.base_instructions, "base instructions");
        assert_eq!(parsed.avatars.len(), 1);
        assert_eq!(parsed.avatars[0].id, "one");

        Ok(())
    }
}
