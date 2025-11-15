use serde::{Deserialize, Serialize};
use std::borrow::Cow;
use std::collections::HashMap;
use std::env;
use std::fmt;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct PersonaMeta {
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

impl std::error::Error for FrontMatterError {}

#[derive(Debug)]
pub struct FrontMatter<'a> {
    pub yaml: Cow<'a, str>,
    pub body: Cow<'a, str>,
}

#[derive(Debug, Error)]
pub enum CatalogError {
    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: io::Error,
    },
    #[error("invalid front matter in {path}: {source}")]
    FrontMatter {
        path: PathBuf,
        #[source]
        source: FrontMatterError,
    },
    #[error("failed to parse YAML in {path}: {source}")]
    Yaml {
        path: PathBuf,
        #[source]
        source: serde_yaml_ng::Error,
    },
    #[error("failed to process JSON at {path}: {source}")]
    Json {
        path: PathBuf,
        #[source]
        source: serde_json::Error,
    },
    #[error("duplicate persona id `{id}` found in {duplicate} (already defined in {first})")]
    Duplicate {
        id: String,
        first: PathBuf,
        duplicate: PathBuf,
    },
}

impl CatalogError {
    fn io(path: &Path, source: io::Error) -> Self {
        Self::Io {
            path: path.to_path_buf(),
            source,
        }
    }

    fn front_matter(path: &Path, source: FrontMatterError) -> Self {
        Self::FrontMatter {
            path: path.to_path_buf(),
            source,
        }
    }

    fn yaml(path: &Path, source: serde_yaml_ng::Error) -> Self {
        Self::Yaml {
            path: path.to_path_buf(),
            source,
        }
    }

    fn json(path: &Path, source: serde_json::Error) -> Self {
        Self::Json {
            path: path.to_path_buf(),
            source,
        }
    }

    fn duplicate(id: String, first: PathBuf, duplicate: PathBuf) -> Self {
        Self::Duplicate {
            id,
            first,
            duplicate,
        }
    }
}

pub fn parse_front_matter(content: &str) -> Result<FrontMatter<'_>, FrontMatterError> {
    if content.contains("\r\n") {
        let normalized = content.replace("\r\n", "\n");
        let (yaml, body) = parse_normalized(&normalized)?;
        return Ok(FrontMatter {
            yaml: Cow::Owned(yaml.to_string()),
            body: Cow::Owned(body.to_string()),
        });
    }

    let (yaml, body) = parse_normalized(content)?;
    Ok(FrontMatter {
        yaml: Cow::Borrowed(yaml),
        body: Cow::Borrowed(body),
    })
}

fn consume_delimiter_suffix(remainder: &str) -> Result<&str, FrontMatterError> {
    let trimmed = remainder.trim_start_matches([' ', '\t']);
    if let Some(rest) = trimmed.strip_prefix('\n') {
        return Ok(rest);
    }
    if trimmed.is_empty() {
        return Ok(trimmed);
    }
    Err(FrontMatterError::Malformed)
}

fn parse_normalized(mut source: &str) -> Result<(&str, &str), FrontMatterError> {
    if let Some(stripped) = source.strip_prefix('\u{FEFF}') {
        source = stripped;
    }

    let Some(remainder) = source.strip_prefix("---\n") else {
        return Err(FrontMatterError::Missing);
    };

    if let Some(rest) = remainder
        .strip_prefix("---")
        .and_then(|stripped| consume_delimiter_suffix(stripped).ok())
    {
        return Ok(("", rest));
    }

    let Some((front_matter, suffix)) = remainder.split_once("\n---") else {
        return Err(FrontMatterError::Malformed);
    };

    let rest = consume_delimiter_suffix(suffix)?;
    Ok((front_matter.trim(), rest))
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct PersonaEntry {
    #[serde(flatten)]
    pub meta: PersonaMeta,
    pub uri: String,
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Eq, Clone)]
pub struct Index {
    pub base_uri: String,
    pub personas: Vec<PersonaEntry>,
}

impl Index {
    pub fn persona_uris(&self) -> impl Iterator<Item = &str> {
        self.personas.iter().map(|entry| entry.uri.as_str())
    }
}

pub fn generate_index(personas_dir: &Path, base_path: &Path) -> Result<Index, CatalogError> {
    let index = build_index(personas_dir, base_path)?;
    write_index(personas_dir, &index)?;
    Ok(index)
}

fn build_index(personas_dir: &Path, base_path: &Path) -> Result<Index, CatalogError> {
    fs::metadata(base_path).map_err(|source| CatalogError::io(base_path, source))?;
    let base_uri = resolve_base_uri(personas_dir, base_path);
    let mut personas = collect_persona_entries(personas_dir)?;
    personas.sort_by(|a, b| a.meta.id.cmp(&b.meta.id));

    Ok(Index { base_uri, personas })
}

fn write_index(personas_dir: &Path, index: &Index) -> Result<(), CatalogError> {
    let catalog_path = personas_dir.join("catalog.json");
    let mut json = serde_json::to_string_pretty(index)
        .map_err(|source| CatalogError::json(&catalog_path, source))?;
    json.push('\n');
    fs::write(&catalog_path, json).map_err(|source| CatalogError::io(&catalog_path, source))?;
    Ok(())
}

fn resolve_base_uri(personas_dir: &Path, base_path: &Path) -> String {
    personas_dir
        .parent()
        .and_then(|parent| base_path.strip_prefix(parent).ok())
        .unwrap_or(base_path)
        .to_string_lossy()
        .replace('\\', "/")
}

pub fn collect_persona_entries(personas_dir: &Path) -> Result<Vec<PersonaEntry>, CatalogError> {
    let base_url = resolve_pages_base_url();
    let mut entries = Vec::new();
    let mut seen_ids: HashMap<String, PathBuf> = HashMap::new();
    let read_dir =
        fs::read_dir(personas_dir).map_err(|source| CatalogError::io(personas_dir, source))?;
    for entry in read_dir {
        let entry = entry.map_err(|source| CatalogError::io(personas_dir, source))?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) != Some("md") {
            continue;
        }
        let content =
            fs::read_to_string(&path).map_err(|source| CatalogError::io(&path, source))?;
        let front_matter = parse_front_matter(&content)
            .map_err(|source| CatalogError::front_matter(&path, source))?;
        let meta: PersonaMeta = serde_yaml_ng::from_str(front_matter.yaml.as_ref())
            .map_err(|source| CatalogError::yaml(&path, source))?;
        let id = meta.id.clone();
        if let Some(first) = seen_ids.insert(id.clone(), path.clone()) {
            return Err(CatalogError::duplicate(id, first, path));
        }
        let uri = build_persona_uri(&path, personas_dir, &base_url);
        entries.push(PersonaEntry { meta, uri });
    }
    Ok(entries)
}

fn resolve_pages_base_url() -> String {
    env::var("PAGES_BASE_URL").unwrap_or_else(|_| "https://qqrm.github.io/codex-tools".to_string())
}

fn build_persona_uri(path: &Path, personas_dir: &Path, base_url: &str) -> String {
    let normalized_base = base_url.trim_end_matches('/');
    let relative_path = personas_dir
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
    use std::error::Error;
    use tempfile::tempdir;

    #[test]
    fn parses_with_extra_delimiter() {
        let content = "---\nid: 1\n---\n---\nbody\n";
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "id: 1");
        assert_eq!(parsed.body.as_ref(), "---\nbody\n");
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
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "id: 1");
        assert_eq!(parsed.body.as_ref(), "body\n");
    }

    #[test]
    fn parses_closing_delimiter_with_trailing_spaces() {
        let content = "---\nid: 1\n---   \nbody\n";
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "id: 1");
        assert_eq!(parsed.body.as_ref(), "body\n");
    }

    #[test]
    fn parses_with_bom_prefix() {
        let content = "\u{FEFF}---\nid: 1\n---\nbody\n";
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "id: 1");
        assert_eq!(parsed.body.as_ref(), "body\n");
    }

    #[test]
    fn parses_without_trailing_newline_after_delimiter() {
        let content = "---\nid: 1\n---";
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "id: 1");
        assert_eq!(parsed.body.as_ref(), "");
    }

    #[test]
    fn parses_empty_front_matter_block() {
        let content = "---\n---\nbody\n";
        let parsed = parse_front_matter(content).expect("should parse");
        assert_eq!(parsed.yaml, "");
        assert_eq!(parsed.body.as_ref(), "body\n");
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
        let personas = root.join("personas");
        fs::create_dir(&personas)?;

        fs::write(
            personas.join("ONE.md"),
            "---\nid: one\nname: One\ndescription: First\n---\nbody\n",
        )?;
        fs::write(
            personas.join("TWO.md"),
            "---\nid: two\nname: Two\n---\nbody\n",
        )?;
        fs::write(root.join("AGENTS.md"), "Base instructions\n")?;

        unsafe {
            env::set_var("PAGES_BASE_URL", "https://example.invalid/base");
        }

        let index = generate_index(&personas, &root.join("AGENTS.md"))?;
        assert_eq!(index.base_uri, "AGENTS.md");
        assert_eq!(index.personas.len(), 2);
        assert_eq!(
            index
                .personas
                .iter()
                .map(|entry| entry.meta.id.as_str())
                .collect::<Vec<_>>(),
            vec!["one", "two"]
        );
        assert_eq!(
            index
                .personas
                .iter()
                .map(|entry| entry.uri.as_str())
                .collect::<Vec<_>>(),
            vec![
                "https://example.invalid/base/personas/ONE.md",
                "https://example.invalid/base/personas/TWO.md"
            ]
        );

        let json = fs::read_to_string(personas.join("catalog.json"))?;
        let parsed: Index = serde_json::from_str(&json)?;
        assert_eq!(parsed, index);

        unsafe {
            env::remove_var("PAGES_BASE_URL");
        }

        Ok(())
    }
}
