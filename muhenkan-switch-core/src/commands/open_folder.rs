use anyhow::Result;
use std::path::PathBuf;

use crate::config::{self, Config};

pub fn run(target: &str, config: &Config) -> Result<()> {
    let path_str = config::get_folder_path(&config.folders, target)?;

    if path_str.is_empty() {
        anyhow::bail!("Folder '{}' has no path configured in config.toml", target);
    }

    // ~ をホームディレクトリに展開
    let path = expand_home(path_str);

    if !path.exists() {
        anyhow::bail!("Folder does not exist: {}", path.display());
    }

    open::that(&path)?;
    Ok(())
}

/// "~" または "~/" で始まるパスをホームディレクトリに展開する
fn expand_home(path_str: &str) -> PathBuf {
    if let Some(rest) = path_str.strip_prefix("~/") {
        if let Some(home) = dirs::home_dir() {
            return home.join(rest);
        }
    } else if path_str == "~" {
        if let Some(home) = dirs::home_dir() {
            return home;
        }
    }
    PathBuf::from(path_str)
}

// ── Tests ──

#[cfg(test)]
mod tests {
    use super::*;

    // ── expand_home ──

    #[test]
    fn expand_home_with_tilde_prefix() {
        let result = expand_home("~/Documents");
        let home = dirs::home_dir().unwrap();
        assert_eq!(result, home.join("Documents"));
    }

    #[test]
    fn expand_home_tilde_only() {
        let result = expand_home("~");
        let home = dirs::home_dir().unwrap();
        assert_eq!(result, home);
    }

    #[test]
    fn expand_home_absolute_path_unchanged() {
        let result = expand_home("/tmp/test");
        assert_eq!(result, PathBuf::from("/tmp/test"));
    }

    #[test]
    fn expand_home_relative_path_unchanged() {
        let result = expand_home("relative/path");
        assert_eq!(result, PathBuf::from("relative/path"));
    }

    #[test]
    fn expand_home_tilde_in_middle_unchanged() {
        // "foo/~/bar" のような場合は展開しない
        let result = expand_home("foo/~/bar");
        assert_eq!(result, PathBuf::from("foo/~/bar"));
    }

    // ── run (統合テスト) ──

    #[test]
    fn run_missing_folder_errors() {
        let config = Config {
            punctuation_style: "、。".to_string(),
            search: Default::default(),
            folders: Default::default(),
            apps: Default::default(),
            timestamp: Default::default(),
        };
        let result = run("nonexistent", &config);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("not defined"));
    }

    #[test]
    fn run_nonexistent_path_errors() {
        use indexmap::IndexMap;
        use crate::config::FolderEntry;
        let mut folders = IndexMap::new();
        folders.insert(
            "test".to_string(),
            FolderEntry {
                key: Some("9".to_string()),
                path: "/tmp/__muhenkan_test_nonexistent_dir_12345__".to_string(),
            },
        );
        let config = Config {
            punctuation_style: "、。".to_string(),
            search: Default::default(),
            folders,
            apps: Default::default(),
            timestamp: Default::default(),
        };
        let result = run("test", &config);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("does not exist"));
    }

    #[test]
    fn run_empty_path_unknown_target_errors() {
        use indexmap::IndexMap;
        use crate::config::FolderEntry;
        let mut folders = IndexMap::new();
        folders.insert(
            "unknown".to_string(),
            FolderEntry {
                key: Some("9".to_string()),
                path: "".to_string(),
            },
        );
        let config = Config {
            punctuation_style: "、。".to_string(),
            search: Default::default(),
            folders,
            apps: Default::default(),
            timestamp: Default::default(),
        };
        let result = run("unknown", &config);
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("no path configured"));
    }
}
