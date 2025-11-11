use serde::{Deserialize, Serialize};
use std::env;
use std::error::Error;
use std::fmt;
use std::fs;
use std::path::Path;

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct AvatarMeta {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub tags: Option<Vec<String>>,
    pub author: Option<String>,
    pub created_at: Option<String>,
    pub version: Option<String>,
}

#[derive(Debug, PartialEq, Eq)]
pub enum FrontMatterError {
    Missing,
    Malformed,
}

impl fmt::Display for FrontMatterError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            FrontMatterError::Missing => write!(f, "front matter missing"),
            FrontMatterError::Malformed => write!(f, "front matter malformed"),
        }
    }
}

impl Error for FrontMatterError {}

pub fn parse_front_matter(content: &str) -> Result<(String, String), FrontMatterError> {
    let content = content.replace("\r\n", "\n");
    let remainder = content
        .strip_prefix("---\n")
        .ok_or(FrontMatterError::Missing)?;

    let mut cursor = 0usize;
    while let Some(rel_newline) = remainder[cursor..].find('\n') {
        let line_end = cursor + rel_newline;
        let line = &remainder[cursor..line_end];
        if line.trim_end() == "---" {
            let front_matter = remainder[..cursor].trim().to_string();
            let rest = remainder[line_end + 1..].to_string();
            return Ok((front_matter, rest));
        }
        cursor = line_end + 1;
    }

    let trailing_line = &remainder[cursor..];
    if trailing_line.trim_end() == "---" {
        let front_matter = remainder[..cursor].trim().to_string();
        return Ok((front_matter, String::new()));
    }

    Err(FrontMatterError::Malformed)
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct AvatarEntry {
    #[serde(flatten)]
    pub meta: AvatarMeta,
    pub uri: String,
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct Index {
    pub base_uri: String,
    pub avatars: Vec<AvatarEntry>,
}

impl Index {
    pub fn avatar_uris(&self) -> impl Iterator<Item = &str> {
        self.avatars.iter().map(|entry| entry.uri.as_str())
    }
}

pub fn generate_index(avatars_dir: &Path, base_path: &Path) -> Result<Index, Box<dyn Error>> {
    let index = build_index(avatars_dir, base_path)?;
    write_index(avatars_dir, &index)?;
    Ok(index)
}

fn build_index(avatars_dir: &Path, base_path: &Path) -> Result<Index, Box<dyn Error>> {
    fs::metadata(base_path)?;
    let base_uri = resolve_base_uri(avatars_dir, base_path);
    let mut avatars = collect_avatar_entries(avatars_dir)?;
    avatars.sort_by(|a, b| a.meta.id.cmp(&b.meta.id));

    Ok(Index { base_uri, avatars })
}

fn write_index(avatars_dir: &Path, index: &Index) -> Result<(), Box<dyn Error>> {
    let json = serde_json::to_string_pretty(index)?;
    fs::write(avatars_dir.join("catalog.json"), json + "\n")?;
    Ok(())
}

fn resolve_base_uri(avatars_dir: &Path, base_path: &Path) -> String {
    avatars_dir
        .parent()
        .and_then(|parent| base_path.strip_prefix(parent).ok())
        .unwrap_or(base_path)
        .to_string_lossy()
        .replace('\\', "/")
}

fn collect_avatar_entries(avatars_dir: &Path) -> Result<Vec<AvatarEntry>, Box<dyn Error>> {
    let base_url = resolve_pages_base_url();
    let mut entries = Vec::new();
    for entry in fs::read_dir(avatars_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("md") {
            continue;
        }
        let content = fs::read_to_string(&path)?;
        let (fm, _) = parse_front_matter(&content)?;
        let meta: AvatarMeta = serde_yaml_ng::from_str(&fm)?;
        let uri = build_avatar_uri(&path, avatars_dir, &base_url);
        entries.push(AvatarEntry { meta, uri });
    }
    Ok(entries)
}

fn resolve_pages_base_url() -> String {
    env::var("PAGES_BASE_URL").unwrap_or_else(|_| "https://qqrm.github.io/codex-tools".to_string())
}

fn build_avatar_uri(path: &Path, avatars_dir: &Path, base_url: &str) -> String {
    let normalized_base = base_url.trim_end_matches('/');
    let relative_path = avatars_dir
        .parent()
        .and_then(|root| path.strip_prefix(root).ok())
        .unwrap_or(path);

    let relative = relative_path
        .components()
        .map(|component| component.as_os_str().to_string_lossy())
        .collect::<Vec<_>>()
        .join("/");

    format!("{}/{}", normalized_base, relative)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::env;
    use tempfile::tempdir;

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
    fn parses_closing_delimiter_with_trailing_spaces() {
        let content = "---\nid: 1\n---   \nbody\n";
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

    #[test]
    fn generates_index_with_expected_fields() -> Result<(), Box<dyn Error>> {
        let tmp = tempdir()?;
        let root = tmp.path();
        let avatars = root.join("avatars");
        fs::create_dir(&avatars)?;

        fs::write(
            avatars.join("ONE.md"),
            "---\nid: one\nname: One\ndescription: First\n---\nbody\n",
        )?;
        fs::write(
            avatars.join("TWO.md"),
            "---\nid: two\nname: Two\n---\nbody\n",
        )?;
        fs::write(root.join("AGENTS.md"), "Base instructions\n")?;

        unsafe {
            env::set_var("PAGES_BASE_URL", "https://example.invalid/base");
        }

        let index = generate_index(&avatars, &root.join("AGENTS.md"))?;
        assert_eq!(index.base_uri, "AGENTS.md");
        assert_eq!(index.avatars.len(), 2);
        assert_eq!(
            index
                .avatars
                .iter()
                .map(|entry| entry.meta.id.as_str())
                .collect::<Vec<_>>(),
            vec!["one", "two"]
        );
        assert_eq!(
            index
                .avatars
                .iter()
                .map(|entry| entry.uri.as_str())
                .collect::<Vec<_>>(),
            vec![
                "https://example.invalid/base/avatars/ONE.md",
                "https://example.invalid/base/avatars/TWO.md"
            ]
        );

        let json = fs::read_to_string(avatars.join("catalog.json"))?;
        let parsed: Index = serde_json::from_str(&json)?;
        assert_eq!(parsed, index);

        unsafe {
            env::remove_var("PAGES_BASE_URL");
        }

        Ok(())
    }
}
