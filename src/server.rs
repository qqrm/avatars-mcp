use serde_json::{Value, json};
use std::fs;
use std::path::Path;
use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt, BufReader};

async fn handle_initialize() -> Value {
    json!({
        "serverInfo": {"name": "Avatars MCP", "version": "0.1"},
        "capabilities": {"resources": true}
    })
}

fn list_avatar_files() -> Vec<String> {
    let avatars_dir = Path::new("avatars");
    let mut files = Vec::new();
    if let Ok(entries) = fs::read_dir(avatars_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("md") {
                if let Ok(relative) = path.strip_prefix(avatars_dir) {
                    files.push(relative.to_string_lossy().to_string());
                }
            }
        }
    }
    files.sort();
    files
}

fn list_resources() -> Vec<String> {
    let mut files: Vec<String> = vec!["AGENTS.md".to_string()];
    for avatar in list_avatar_files() {
        files.push(format!("avatars/{}", avatar));
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
    if uri == "AGENTS.md" {
        return match fs::read_to_string("AGENTS.md") {
            Ok(content) => json!({"contents": content}),
            Err(e) => json!({"error": {"code": -32000, "message": e.to_string()}}),
        };
    }

    let avatars_dir = match fs::canonicalize("avatars") {
        Ok(dir) => dir,
        Err(e) => {
            return json!({
                "error": {"code": -32000, "message": e.to_string()}
            });
        }
    };

    let normalized = match fs::canonicalize(uri) {
        Ok(path) => path,
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

    match fs::read_to_string(normalized) {
        Ok(content) => json!({"contents": content}),
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
        let files = list_avatar_files();
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
                "AGENTS.md",
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
    async fn reads_agents_md() {
        let result = handle_resources_read("AGENTS.md").await;
        assert!(result.get("contents").is_some());
    }
}
