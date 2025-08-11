use serde_json::{Value, json};
use std::fs;
use std::path::Path;
use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::task;

async fn handle_initialize() -> Value {
    json!({
        "serverInfo": {"name": "Avatars MCP", "version": "0.1"},
        "capabilities": {"resources": true}
    })
}

fn list_avatar_files() -> std::io::Result<Vec<String>> {
    let avatars_dir = Path::new("avatars");
    let mut files = Vec::new();
    let entries = fs::read_dir(avatars_dir)?;
    for entry_result in entries {
        match entry_result {
            Ok(entry) => {
                let path = entry.path();
                if path.extension().and_then(|s| s.to_str()) == Some("md") {
                    match path.strip_prefix(avatars_dir) {
                        Ok(relative) => files.push(relative.to_string_lossy().to_string()),
                        Err(e) => eprintln!("Failed to strip prefix for {:?}: {}", path, e),
                    }
                }
            }
            Err(e) => eprintln!("Failed to read directory entry: {}", e),
        }
    }
    files.sort();
    Ok(files)
}

fn list_resources() -> Vec<String> {
    let mut files: Vec<String> = vec!["BASE_AGENTS.md".to_string()];
    match list_avatar_files() {
        Ok(avatars) => {
            for avatar in avatars {
                files.push(format!("avatars/{}", avatar));
            }
        }
        Err(e) => eprintln!("Failed to list avatar files: {}", e),
    }
    files.sort();
    files
}

async fn handle_resources_list() -> Value {
    let resources: Vec<Value> = list_resources()
        .into_iter()
        .map(|uri| json!({"uri": uri}))
        .collect();
    json!({"resources": resources})
}

async fn handle_resources_read(uri: &str) -> Value {
    if uri == "BASE_AGENTS.md" {
        return match task::spawn_blocking(|| fs::read_to_string("BASE_AGENTS.md")).await {
            Ok(Ok(content)) => json!({"contents": content}),
            Ok(Err(e)) => json!({"error": {"code": -32000, "message": e.to_string()}}),
            Err(e) => json!({"error": {"code": -32000, "message": e.to_string()}}),
        };
    }

    let avatars_dir = match task::spawn_blocking(|| fs::canonicalize("avatars")).await {
        Ok(Ok(dir)) => dir,
        Ok(Err(e)) => {
            return json!({
                "error": {"code": -32000, "message": e.to_string()}
            });
        }
        Err(e) => {
            return json!({
                "error": {"code": -32000, "message": e.to_string()}
            });
        }
    };

    let uri_owned = uri.to_owned();
    let normalized = match task::spawn_blocking(move || fs::canonicalize(uri_owned)).await {
        Ok(Ok(path)) => path,
        Ok(Err(e)) => {
            return json!({
                "error": {"code": -32000, "message": e.to_string()}
            });
        }
        Err(e) => {
            return json!({
                "error": {"code": -32000, "message": e.to_string()}
            });
        }
    };

    if !normalized.starts_with(&avatars_dir) {
        return json!({
            "error": {"code": -32000, "message": "Access denied"}
        });
    }

    match task::spawn_blocking(move || fs::read_to_string(normalized)).await {
        Ok(Ok(content)) => json!({"contents": content}),
        Ok(Err(e)) => json!({"error": {"code": -32000, "message": e.to_string()}}),
        Err(e) => json!({"error": {"code": -32000, "message": e.to_string()}}),
    }
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
                    json!({"error": {"code": -32602, "message": "Missing uri"}})
                }
            }
            _ => json!({"error": {"code": -32601, "message": "Unknown method"}}),
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
    async fn lists_resources_with_prefix_and_order() {
        let result = handle_resources_list().await;
        let resources = result
            .get("resources")
            .and_then(|r| r.as_array())
            .expect("resources array");
        let uris: Vec<&str> = resources
            .iter()
            .map(|v| v.get("uri").and_then(|u| u.as_str()).unwrap())
            .collect();
        assert_eq!(
            uris,
            vec![
                "BASE_AGENTS.md",
                "avatars/ANALYST.md",
                "avatars/ARCHITECT.md",
                "avatars/DEVELOPER.md",
                "avatars/DEVOPS.md",
                "avatars/SECURITY.md",
                "avatars/TESTER.md",
            ]
        );
    }

    #[tokio::test]
    async fn reads_base_agents_md() {
        let result = handle_resources_read("BASE_AGENTS.md").await;
        assert!(result.get("contents").is_some());
    }
}
