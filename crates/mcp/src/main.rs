use serde_json::{Value, json};
use std::fs;
use std::io::{Error as IoError, ErrorKind, Result as IoResult};
use std::path::{Path, PathBuf};
use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::task;

const CATALOG_URI: &str = "avatars.json";
const CATALOG_PATH: &str = "avatars/catalog.json";
const BASE_URI: &str = "AGENTS.md";
const AVATARS_DIR: &str = "avatars";

async fn handle_initialize() -> Value {
    json!({
        "serverInfo": {"name": "Avatars MCP", "version": "0.1"},
        "capabilities": {"resources": true}
    })
}

fn list_avatar_files() -> IoResult<Vec<String>> {
    let avatars_dir = avatars_root();
    let mut files = Vec::new();
    for entry in fs::read_dir(avatars_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension().and_then(|s| s.to_str()) == Some("md") {
            if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                files.push(name.to_string());
            }
        }
    }
    files.sort();
    Ok(files)
}

fn enumerate_resources() -> IoResult<Vec<String>> {
    let mut resources = vec![CATALOG_URI.to_string(), BASE_URI.to_string()];
    for file in list_avatar_files()? {
        resources.push(format!("{}/{}", AVATARS_DIR, file));
    }
    Ok(resources)
}

fn error_response(message: impl Into<String>) -> Value {
    json!({"error": {"code": -32000, "message": message.into()}})
}

async fn handle_resources_list() -> Value {
    match enumerate_resources() {
        Ok(resources) => {
            let values: Vec<Value> = resources
                .into_iter()
                .map(|uri| json!({"uri": uri}))
                .collect();
            json!({"resources": values})
        }
        Err(e) => error_response(e.to_string()),
    }
}

async fn handle_resources_read(uri: &str) -> Value {
    match uri {
        CATALOG_URI => read_file(catalog_path()).await,
        BASE_URI => read_file(base_instructions_path()).await,
        _ if uri.starts_with(&format!("{}/", AVATARS_DIR)) => match avatar_path_from_uri(uri) {
            Ok(path) => read_file(path).await,
            Err(e) => error_response(e.to_string()),
        },
        _ => error_response("Unknown resource"),
    }
}

async fn read_file(path: PathBuf) -> Value {
    match task::spawn_blocking(move || fs::read_to_string(path)).await {
        Ok(Ok(content)) => json!({"contents": content}),
        Ok(Err(e)) => error_response(e.to_string()),
        Err(e) => error_response(e.to_string()),
    }
}

fn avatar_path_from_uri(uri: &str) -> IoResult<PathBuf> {
    let relative = Path::new(uri)
        .strip_prefix(AVATARS_DIR)
        .map_err(|_| IoError::new(ErrorKind::NotFound, "Unknown resource"))?;
    let base = fs::canonicalize(avatars_root())?;
    let candidate = base.join(relative);
    let normalized = fs::canonicalize(&candidate)?;
    if normalized.starts_with(&base) {
        Ok(normalized)
    } else {
        Err(IoError::new(ErrorKind::PermissionDenied, "Access denied"))
    }
}

fn avatars_root() -> PathBuf {
    workspace_path(AVATARS_DIR)
}

fn base_instructions_path() -> PathBuf {
    workspace_path(BASE_URI)
}

fn catalog_path() -> PathBuf {
    workspace_path(CATALOG_PATH)
}

fn workspace_path(relative: &str) -> PathBuf {
    let mut path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    path.pop();
    path.pop();
    path.push(relative);
    path
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let stdin = BufReader::new(io::stdin());
    let mut lines = stdin.lines();
    let mut stdout = io::stdout();

    while let Some(line) = lines.next_line().await? {
        if line.trim().is_empty() {
            continue;
        }
        let req: Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(e) => {
                let err = json!({"jsonrpc":"2.0","error":{"code":-32700,"message":e.to_string()}});
                stdout.write_all(err.to_string().as_bytes()).await?;
                stdout.write_all(b"\n").await?;
                continue;
            }
        };
        let id = req.get("id").cloned().unwrap_or(Value::Null);
        let method = req.get("method").and_then(|m| m.as_str()).unwrap_or("");

        let result = match method {
            "initialize" => handle_initialize().await,
            "resources/list" => handle_resources_list().await,
            "resources/read" => {
                if let Some(uri) = req
                    .get("params")
                    .and_then(|p| p.get("uri"))
                    .and_then(|u| u.as_str())
                {
                    handle_resources_read(uri).await
                } else {
                    error_response("Missing uri")
                }
            }
            _ => error_response("Unknown method"),
        };

        let response = if result.get("error").is_some() {
            json!({"jsonrpc": "2.0", "id": id, "error": result["error"]})
        } else {
            json!({"jsonrpc": "2.0", "id": id, "result": result})
        };
        stdout.write_all(response.to_string().as_bytes()).await?;
        stdout.write_all(b"\n").await?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lists_files_relative_and_sorted() {
        let files = list_avatar_files().expect("list avatar files");
        assert_eq!(
            files,
            vec![
                "ANALYST.md",
                "ARCHITECT.md",
                "DEVELOPER.md",
                "DEVOPS.md",
                "SECURITY.md",
                "TECH_LEAD.md",
                "TESTER.md",
            ]
        );
    }

    #[tokio::test]
    async fn reads_avatar_inside_directory() {
        let result = handle_resources_read("avatars/ANALYST.md").await;
        assert!(result.get("contents").is_some());
    }

    #[tokio::test]
    async fn blocks_traversal_outside_avatars() {
        let result = handle_resources_read("avatars/../Cargo.toml").await;
        assert!(result.get("error").is_some());
    }

    #[tokio::test]
    async fn lists_resources_returns_catalog_and_base() {
        let result = handle_resources_list().await;
        let resources = result
            .get("resources")
            .and_then(|r| r.as_array())
            .expect("resources array");
        let uris: Vec<&str> = resources
            .iter()
            .map(|v| v.get("uri").and_then(|u| u.as_str()).unwrap())
            .collect();
        assert!(uris.contains(&"avatars.json"));
        assert!(uris.contains(&"AGENTS.md"));
    }

    #[tokio::test]
    async fn reads_avatar_catalog() {
        let result = handle_resources_read("avatars.json").await;
        assert!(result.get("contents").is_some());
    }

    #[tokio::test]
    async fn reads_base_instructions() {
        let result = handle_resources_read("AGENTS.md").await;
        assert!(result.get("contents").is_some());
    }
}
