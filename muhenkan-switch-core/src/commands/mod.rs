pub mod context;
pub mod dispatch;
pub mod keys;
pub mod open_folder;
pub mod open_gui;
pub mod search;
pub mod switch_app;
pub mod timestamp;
pub mod timestamp_settings;
pub mod toast;

/// Wayland セッション判定
#[cfg(target_os = "linux")]
pub fn is_wayland() -> bool {
    std::env::var("WAYLAND_DISPLAY").is_ok()
        || std::env::var("XDG_SESSION_TYPE")
            .map(|v| v == "wayland")
            .unwrap_or(false)
}

/// AppleScript の文字列リテラル (`"..."`) に埋め込むための値をエスケープする。
///
/// `\` を先に、`"` を後にエスケープする必要がある
/// (順序を逆にすると `"` のエスケープで挿入した `\` が再度エスケープされてしまう)。
/// これを怠ると、選択テキスト・アプリ名・パス等に `"` や `\` を含む値で
/// AppleScript 文字列リテラルが壊れ、細工されたコマンドが注入されうる。
///
/// 呼び出し元は全て `#[cfg(target_os = "macos")]` 配下だが、このマシン (Linux) では
/// macOS 分岐がコンパイルされずテストできないため、関数自体は cfg の外に置いて
/// 全 OS でユニットテスト可能にしている。macOS 以外のビルドでは未使用になるため
/// dead_code を許容する。
#[allow(dead_code)]
pub(crate) fn escape_applescript_string(s: &str) -> String {
    s.replace('\\', r"\\").replace('"', r#"\""#)
}

#[cfg(test)]
mod tests {
    use super::escape_applescript_string;

    #[test]
    fn test_escape_applescript_string_plain_text() {
        assert_eq!(escape_applescript_string("hello"), "hello");
    }

    #[test]
    fn test_escape_applescript_string_double_quote() {
        assert_eq!(escape_applescript_string(r#"say "hi""#), r#"say \"hi\""#);
    }

    #[test]
    fn test_escape_applescript_string_backslash() {
        assert_eq!(escape_applescript_string(r"C:\path"), r"C:\\path");
    }

    #[test]
    fn test_escape_applescript_string_backslash_and_quote_order() {
        // バックスラッシュを先にエスケープしないと、"\"" のエスケープで
        // 生成した `\` がさらにエスケープされて壊れる。
        assert_eq!(escape_applescript_string(r#"\""#), r#"\\\""#);
    }

    #[test]
    fn test_escape_applescript_string_empty() {
        assert_eq!(escape_applescript_string(""), "");
    }
}
