#!/usr/bin/env rust-script
//! ```cargo
//! [dependencies]
//! reqwest = { version = "0.12", features = ["blocking", "rustls-tls"] }
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ```

use reqwest::blocking::Client;
use serde::Deserialize;
use std::env;
use std::error::Error;
use std::fs;
use std::path::{Component, Path, PathBuf};

struct Config {
    base_url: String,
    base_file: PathBuf,
    index_path: PathBuf,
}

impl Config {
    fn from_env() -> Self {
        let base_url = env::var("MCP_BASE_URL")
            .unwrap_or_else(|_| "https://qqrm.github.io/avatars-mcp".to_string());
        let avatar_dir = env::var("AVATAR_DIR").unwrap_or_else(|_| "avatars".to_string());
        let base_file = env::var("BASE_FILE").unwrap_or_else(|_| "BASE_AGENTS.md".to_string());
        let index_path =
            env::var("INDEX_PATH").unwrap_or_else(|_| format!("{}/index.json", avatar_dir));
        Self {
            base_url,
            base_file: PathBuf::from(base_file),
            index_path: PathBuf::from(index_path),
        }
    }
}

#[derive(Deserialize)]
struct Index {
    avatars: Vec<AvatarEntry>,
}

#[derive(Deserialize)]
struct AvatarEntry {
    uri: String,
}

struct SyncSummary {
    total: usize,
    updated: usize,
}

fn main() -> Result<(), Box<dyn Error>> {
    let config = Config::from_env();
    validate_relative(&config.base_file)?;
    validate_relative(&config.index_path)?;

    let client = Client::builder()
        .user_agent("avatars-mcp-sync/0.1")
        .build()?;

    let summary = sync_resources(&client, &config)?;
    println!(
        "Synced {} files ({} updated, {} unchanged) from {}",
        summary.total,
        summary.updated,
        summary.total.saturating_sub(summary.updated),
        config.base_url
    );
    Ok(())
}

fn sync_resources(client: &Client, config: &Config) -> Result<SyncSummary, Box<dyn Error>> {
    let mut total = 0usize;
    let mut updated = 0usize;

    if download_file(
        client,
        &config.base_url,
        &config.base_file,
        &config.base_file,
    )? {
        updated += 1;
    }
    total += 1;

    if download_file(
        client,
        &config.base_url,
        &config.index_path,
        &config.index_path,
    )? {
        updated += 1;
    }
    total += 1;

    let index_contents = fs::read_to_string(&config.index_path)?;
    let index: Index = serde_json::from_str(&index_contents)?;

    for entry in index.avatars {
        let path = PathBuf::from(entry.uri);
        validate_relative(&path)?;
        if download_file(client, &config.base_url, &path, &path)? {
            updated += 1;
        }
        total += 1;
    }

    Ok(SyncSummary { total, updated })
}

fn download_file(
    client: &Client,
    base_url: &str,
    remote_path: &Path,
    dest: &Path,
) -> Result<bool, Box<dyn Error>> {
    let url = build_url(base_url, remote_path);
    let response = client.get(&url).send()?;
    if !response.status().is_success() {
        return Err(format!("Failed to download {} (status: {})", url, response.status()).into());
    }
    let bytes = response.bytes()?.to_vec();

    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }

    let changed = match fs::read(dest) {
        Ok(existing) => existing != bytes,
        Err(_) => true,
    };

    if changed {
        fs::write(dest, &bytes)?;
    }

    Ok(changed)
}

fn build_url(base_url: &str, remote_path: &Path) -> String {
    let trimmed_base = base_url.trim_end_matches('/');
    let joined = remote_path
        .components()
        .filter_map(|component| match component {
            Component::Normal(segment) => Some(segment.to_string_lossy()),
            _ => None,
        })
        .collect::<Vec<_>>()
        .join("/");
    if joined.is_empty() {
        trimmed_base.to_string()
    } else {
        format!("{}/{}", trimmed_base, joined)
    }
}

fn validate_relative(path: &Path) -> Result<(), Box<dyn Error>> {
    if path.is_absolute() {
        return Err(format!("Path {:?} must be relative", path).into());
    }
    for component in path.components() {
        if matches!(component, Component::ParentDir) {
            return Err(format!("Path {:?} must not contain parent segments", path).into());
        }
    }
    Ok(())
}
