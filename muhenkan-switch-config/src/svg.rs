use crate::Config;

/// キーの物理配置を定義する構造体。
struct KeyDef {
    /// 物理キー名（大文字表示用）
    label: &'static str,
    /// config 検索用（小文字）
    dispatch_key: Option<&'static str>,
    /// SVG 上の x 座標
    x: f64,
    /// SVG 上の y 座標
    y: f64,
    /// キーのカテゴリ
    category: KeyCategory,
}

#[derive(Clone, Copy, PartialEq)]
enum KeyCategory {
    /// 左手割当キー（config で色が決まる）
    Dispatch,
    /// タイムスタンプキー（V, C, X）
    Timestamp,
    /// 右手テキスト編集キー（固定）
    TextEdit,
    /// 無変換レイヤーで未使用のキー
    Unused,
}

/// 右手キーの固定機能名。
/// 右手キーの固定機能名（kanata/muhenkan.kbd の mh-layer 定義に準拠）。
fn text_edit_label(key: &str, punctuation_style: &str) -> &'static str {
    match key {
        // hjkl: Vim 風カーソル移動
        "H" => "←",
        "J" => "↓",
        "K" => "↑",
        "L" => "→",
        // uiyo: 単語移動 / 行頭行末
        "U" => "単語←",
        "I" => "単語→",
        "Y" => "Home",
        "O" => "End",
        // nm;: 削除
        "N" => "BS",
        "M" => "Del",
        ";" => "Esc",
        // ,.: 句読点
        "," => if punctuation_style == "，．" { "，" } else { "、" },
        "." => if punctuation_style == "，．" { "．" } else { "。" },
        _ => "",
    }
}

/// タイムスタンプキーの固定機能名。
fn timestamp_label(key: &str) -> &'static str {
    match key {
        "V" => "付与",
        "C" => "複製",
        "X" => "除去",
        _ => "",
    }
}

const KEY_W: f64 = 52.0;
const KEY_H: f64 = 52.0;
const KEY_GAP: f64 = 4.0;
const KEY_PITCH: f64 = KEY_W + KEY_GAP; // 56.0
const CORNER_R: f64 = 6.0;
const FONT_SIZE_TOP: f64 = 13.0;
const FONT_SIZE_BOTTOM: f64 = 11.0;

/// QWERTY 物理配列の (row, col) から SVG 座標を計算するヘルパー。
/// row: 0=数字行, 1=Q行, 2=A行(ホーム), 3=Z行
/// col: QWERTY 列番号 (1→0, Q→0, A→0, Z→0)
/// hand_gap: 左右の手の間に挿入する追加幅
fn qwerty_pos(row: usize, col: usize, hand_gap: f64) -> (f64, f64) {
    let pad = 20.0;
    // QWERTY 行スタガー（左端キーからの X オフセット）
    let row_offset = match row {
        0 => 0.0,                // 数字行
        1 => KEY_PITCH * 0.5,   // Q行（Tab 幅分）
        2 => KEY_PITCH * 0.75,  // A行（CapsLock 幅分）
        _ => KEY_PITCH * 1.25,  // Z行（Shift 幅分）
    };
    let x = pad + row_offset + col as f64 * KEY_PITCH + hand_gap;
    let y = pad + row as f64 * KEY_PITCH;
    (x, y)
}

/// JIS キーボードの QWERTY 物理配列に基づくキー定義を生成する。
fn key_definitions() -> Vec<KeyDef> {
    // 左右の手の間（col 4→5 の間）に挿入するギャップ
    let gap = KEY_PITCH * 1.5;

    // ヘルパー: 左手キー (gap なし)
    let l = |row, col| -> (f64, f64) { qwerty_pos(row, col, 0.0) };
    // ヘルパー: 右手キー (gap あり)
    let r = |row, col| -> (f64, f64) { qwerty_pos(row, col, gap) };

    vec![
        // ── 数字行 (row 0) ──
        //   1(c0) 2(c1) 3(c2) 4(c3) 5(c4)  6(c5) 7(c6) 8(c7) 9(c8) 0(c9)
        KeyDef { label: "1", dispatch_key: Some("1"), x: l(0,0).0, y: l(0,0).1, category: KeyCategory::Dispatch },
        KeyDef { label: "2", dispatch_key: Some("2"), x: l(0,1).0, y: l(0,1).1, category: KeyCategory::Dispatch },
        KeyDef { label: "3", dispatch_key: Some("3"), x: l(0,2).0, y: l(0,2).1, category: KeyCategory::Dispatch },
        KeyDef { label: "4", dispatch_key: Some("4"), x: l(0,3).0, y: l(0,3).1, category: KeyCategory::Dispatch },
        KeyDef { label: "5", dispatch_key: Some("5"), x: l(0,4).0, y: l(0,4).1, category: KeyCategory::Dispatch },
        KeyDef { label: "6", dispatch_key: None, x: r(0,5).0, y: r(0,5).1, category: KeyCategory::Unused },
        KeyDef { label: "7", dispatch_key: None, x: r(0,6).0, y: r(0,6).1, category: KeyCategory::Unused },
        KeyDef { label: "8", dispatch_key: None, x: r(0,7).0, y: r(0,7).1, category: KeyCategory::Unused },
        KeyDef { label: "9", dispatch_key: None, x: r(0,8).0, y: r(0,8).1, category: KeyCategory::Unused },
        KeyDef { label: "0", dispatch_key: None, x: r(0,9).0, y: r(0,9).1, category: KeyCategory::Unused },
        // ── Q行 (row 1) ──
        //   Q(c0) W(c1) E(c2) R(c3) T(c4)  |  Y(c5) U(c6) I(c7) O(c8) P(c9)
        KeyDef { label: "Q", dispatch_key: Some("q"), x: l(1,0).0, y: l(1,0).1, category: KeyCategory::Dispatch },
        KeyDef { label: "W", dispatch_key: Some("w"), x: l(1,1).0, y: l(1,1).1, category: KeyCategory::Dispatch },
        KeyDef { label: "E", dispatch_key: Some("e"), x: l(1,2).0, y: l(1,2).1, category: KeyCategory::Dispatch },
        KeyDef { label: "R", dispatch_key: Some("r"), x: l(1,3).0, y: l(1,3).1, category: KeyCategory::Dispatch },
        KeyDef { label: "T", dispatch_key: Some("t"), x: l(1,4).0, y: l(1,4).1, category: KeyCategory::Dispatch },
        KeyDef { label: "Y", dispatch_key: None, x: r(1,5).0, y: r(1,5).1, category: KeyCategory::TextEdit },
        KeyDef { label: "U", dispatch_key: None, x: r(1,6).0, y: r(1,6).1, category: KeyCategory::TextEdit },
        KeyDef { label: "I", dispatch_key: None, x: r(1,7).0, y: r(1,7).1, category: KeyCategory::TextEdit },
        KeyDef { label: "O", dispatch_key: None, x: r(1,8).0, y: r(1,8).1, category: KeyCategory::TextEdit },
        KeyDef { label: "P", dispatch_key: None, x: r(1,9).0, y: r(1,9).1, category: KeyCategory::Unused },
        // ── A行 / ホーム行 (row 2) ──
        //   A(c0) S(c1) D(c2) F(c3) G(c4)  |  H(c5) J(c6) K(c7) L(c8) ;(c9)
        KeyDef { label: "A", dispatch_key: Some("a"), x: l(2,0).0, y: l(2,0).1, category: KeyCategory::Dispatch },
        KeyDef { label: "S", dispatch_key: Some("s"), x: l(2,1).0, y: l(2,1).1, category: KeyCategory::Dispatch },
        KeyDef { label: "D", dispatch_key: Some("d"), x: l(2,2).0, y: l(2,2).1, category: KeyCategory::Dispatch },
        KeyDef { label: "F", dispatch_key: Some("f"), x: l(2,3).0, y: l(2,3).1, category: KeyCategory::Dispatch },
        KeyDef { label: "G", dispatch_key: Some("g"), x: l(2,4).0, y: l(2,4).1, category: KeyCategory::Dispatch },
        KeyDef { label: "H", dispatch_key: None, x: r(2,5).0, y: r(2,5).1, category: KeyCategory::TextEdit },
        KeyDef { label: "J", dispatch_key: None, x: r(2,6).0, y: r(2,6).1, category: KeyCategory::TextEdit },
        KeyDef { label: "K", dispatch_key: None, x: r(2,7).0, y: r(2,7).1, category: KeyCategory::TextEdit },
        KeyDef { label: "L", dispatch_key: None, x: r(2,8).0, y: r(2,8).1, category: KeyCategory::TextEdit },
        KeyDef { label: ";", dispatch_key: None, x: r(2,9).0, y: r(2,9).1, category: KeyCategory::TextEdit },
        // ── Z行 / 下行 (row 3) ──
        //   Z(c0) X(c1) C(c2) V(c3) B(c4)  |  N(c5) M(c6) ,(c7) .(c8) /(c9)
        KeyDef { label: "Z", dispatch_key: Some("z"), x: l(3,0).0, y: l(3,0).1, category: KeyCategory::Dispatch },
        KeyDef { label: "X", dispatch_key: None, x: l(3,1).0, y: l(3,1).1, category: KeyCategory::Timestamp },
        KeyDef { label: "C", dispatch_key: None, x: l(3,2).0, y: l(3,2).1, category: KeyCategory::Timestamp },
        KeyDef { label: "V", dispatch_key: None, x: l(3,3).0, y: l(3,3).1, category: KeyCategory::Timestamp },
        KeyDef { label: "B", dispatch_key: Some("b"), x: l(3,4).0, y: l(3,4).1, category: KeyCategory::Dispatch },
        KeyDef { label: "N", dispatch_key: None, x: r(3,5).0, y: r(3,5).1, category: KeyCategory::TextEdit },
        KeyDef { label: "M", dispatch_key: None, x: r(3,6).0, y: r(3,6).1, category: KeyCategory::TextEdit },
        KeyDef { label: ",", dispatch_key: None, x: r(3,7).0, y: r(3,7).1, category: KeyCategory::TextEdit },
        KeyDef { label: ".", dispatch_key: None, x: r(3,8).0, y: r(3,8).1, category: KeyCategory::TextEdit },
        KeyDef { label: "/", dispatch_key: None, x: r(3,9).0, y: r(3,9).1, category: KeyCategory::Unused },
    ]
}

/// config の割当キーに対する割当カテゴリとエントリ名を返す。
fn lookup_dispatch<'a>(config: &'a Config, key: &str) -> Option<(&'static str, &'a str)> {
    for (name, entry) in &config.folders {
        if entry.dispatch_key() == Some(key) {
            return Some(("folder", name.as_str()));
        }
    }
    for (name, entry) in &config.search {
        if entry.dispatch_key() == Some(key) {
            return Some(("search", name.as_str()));
        }
    }
    for (name, entry) in &config.apps {
        if entry.dispatch_key() == Some(key) {
            return Some(("app", name.as_str()));
        }
    }
    None
}

/// カテゴリに応じた塗り色を返す。
fn fill_color(category: &str) -> &'static str {
    match category {
        "folder" => "#fff2cc",
        "search" => "#ffe6cc",
        "app" => "#f8cecc",
        "timestamp" => "#e1d5e7",
        "textedit" => "#dae8fc",
        "unused" => "#d9d9d9",
        _ => "#f5f5f5", // 未割当（ディスパッチ可能だが config 未設定）
    }
}

/// XML 特殊文字をエスケープする。
fn xml_escape(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

/// config.toml の内容からキーボードレイアウト SVG を生成する。
pub fn generate(config: &Config) -> String {
    let keys = key_definitions();

    // SVG サイズを計算
    let max_x = keys.iter().map(|k| k.x + KEY_W).fold(0.0f64, f64::max);
    let max_y = keys.iter().map(|k| k.y + KEY_H).fold(0.0f64, f64::max);
    let svg_w = max_x + 20.0;
    let svg_h = max_y + 20.0;

    let mut svg = format!(
        r#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {svg_w} {svg_h}" width="{svg_w}" height="{svg_h}" font-family="sans-serif">"#,
    );

    // 背景
    svg.push_str(&format!(
        r##"<rect width="{svg_w}" height="{svg_h}" fill="#ffffff" rx="8"/>"##,
    ));

    for key in &keys {
        let (fill, bottom_label) = match key.category {
            KeyCategory::TextEdit => {
                (fill_color("textedit"), text_edit_label(key.label, &config.punctuation_style).to_string())
            }
            KeyCategory::Timestamp => {
                (fill_color("timestamp"), timestamp_label(key.label).to_string())
            }
            KeyCategory::Unused => {
                (fill_color("unused"), String::new())
            }
            KeyCategory::Dispatch => {
                if let Some(dk) = key.dispatch_key {
                    if let Some((cat, name)) = lookup_dispatch(config, dk) {
                        (fill_color(cat), name.to_string())
                    } else {
                        (fill_color("unassigned"), String::new())
                    }
                } else {
                    (fill_color("unassigned"), String::new())
                }
            }
        };

        // キー矩形
        svg.push_str(&format!(
            r##"<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="#999" stroke-width="1"/>"##,
            x = key.x,
            y = key.y,
            w = KEY_W,
            h = KEY_H,
            r = CORNER_R,
        ));

        // 上段ラベル（物理キー名）
        let top_y = key.y + 18.0;
        let cx = key.x + KEY_W / 2.0;
        svg.push_str(&format!(
            r##"<text x="{cx}" y="{top_y}" text-anchor="middle" font-size="{fs}" font-weight="bold" fill="#333">{label}</text>"##,
            fs = FONT_SIZE_TOP,
            label = xml_escape(key.label),
        ));

        // 下段ラベル（機能名/エントリ名）
        if !bottom_label.is_empty() {
            let bot_y = key.y + 38.0;
            let escaped = xml_escape(&bottom_label);
            // 長いラベルはフォントサイズを縮小
            let fs = if bottom_label.len() > 6 {
                FONT_SIZE_BOTTOM - 2.0
            } else {
                FONT_SIZE_BOTTOM
            };
            svg.push_str(&format!(
                r##"<text x="{cx}" y="{bot_y}" text-anchor="middle" font-size="{fs}" fill="#666">{escaped}</text>"##,
            ));
        }
    }

    svg.push_str("</svg>");
    svg
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::default_config;

    #[test]
    fn test_generate_default_config() {
        let config = default_config();
        let svg = generate(&config);
        assert!(svg.starts_with("<svg"));
        assert!(svg.ends_with("</svg>"));
    }

    #[test]
    fn test_svg_contains_entry_names() {
        let config = default_config();
        let svg = generate(&config);
        assert!(svg.contains("Google"), "SVG should contain 'Google'");
        assert!(svg.contains("英和和英辞典"), "SVG should contain '英和和英辞典'");
    }

    #[test]
    fn test_svg_contains_text_edit_labels() {
        let config = default_config();
        let svg = generate(&config);
        assert!(svg.contains("←"), "SVG should contain arrow label");
        assert!(svg.contains("Home"), "SVG should contain 'Home'");
    }

    #[test]
    fn test_empty_config_no_error() {
        let config: Config = toml::from_str("[search]\n[folders]\n[apps]\n").unwrap();
        let svg = generate(&config);
        assert!(svg.starts_with("<svg"));
        assert!(svg.ends_with("</svg>"));
    }

    #[test]
    fn test_svg_valid_xml_structure() {
        let config = default_config();
        let svg = generate(&config);
        let rect_count = svg.matches("<rect ").count();
        let expected_keys = key_definitions().len();
        assert_eq!(
            rect_count,
            expected_keys + 1,
            "Expected {} rects (1 bg + {} keys)",
            expected_keys + 1,
            expected_keys
        );
    }
}
