use avatars_generator::Index;
use std::env;
use std::error::Error;
use std::fs;

fn main() -> Result<(), Box<dyn Error>> {
    let index_path = env::args()
        .nth(1)
        .unwrap_or_else(|| "avatars/catalog.json".to_string());
    let data = fs::read_to_string(&index_path)?;
    let index: Index = serde_json::from_str(&data)?;
    for uri in index.avatar_uris() {
        println!("{}", uri);
    }
    Ok(())
}
