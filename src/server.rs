use serde_json::{json, Value};
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
            if entry.path().extension().and_then(|s| s.to_str()) == Some("md") {
                files.push(entry.path().to_string_lossy().to_string());
            }
        }
    }
    files
}

async fn handle_resources_list() -> Value {
    let resources: Vec<Value> = list_avatar_files()
        .into_iter()
        .map(|uri| json!({"uri": uri}))
        .collect();
    json!({"resources": resources})
}

async fn handle_resources_read(uri: &str) -> Value {
    match fs::read_to_string(uri) {
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
                if let Some(uri) = req.get("params").and_then(|p| p.get("uri")).and_then(|u| u.as_str()) {
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
