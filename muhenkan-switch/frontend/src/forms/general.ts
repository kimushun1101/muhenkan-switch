// ── General tab: autostart / export-import / help / github / open-dir / quit / kanata status / updater ──
import { invoke, listen, message, ask, shellOpen } from '../lib/tauri';
import { setConfig } from '../lib/state';
import type { Config } from '../lib/config';
import type { KanataStatus, UpdateInfo } from '../lib/ipc-types';

// ── Kanata status ──
export async function refreshKanataStatus(): Promise<void> {
  try {
    const status = await invoke<KanataStatus>('get_kanata_status');
    updateKanataUI(status.running);
  } catch {
    updateKanataUI(false);
  }
}

function updateKanataUI(running: boolean): void {
  // Footer
  const footerDot = document.getElementById('footer-kanata-dot');
  const footerText = document.getElementById('footer-kanata-text');
  if (footerDot) footerDot.classList.toggle('running', running);
  if (footerText) footerText.textContent = running ? 'キー割当: 実行中' : 'キー割当: 停止中';
}

// ── Autostart checkbox ──
// トレイの CheckMenuItem と GUI チェックボックスは同じ自動起動状態を指すため、
// どちらから変更しても 'autostart-changed' イベント (実状態) でもう一方に反映する。
function setAutostartCheckbox(enabled: boolean): void {
  const autostartCheckbox = document.getElementById('opt-autostart') as HTMLInputElement | null;
  if (autostartCheckbox) autostartCheckbox.checked = enabled;
}

export async function loadAutostart(): Promise<void> {
  try {
    setAutostartCheckbox(await invoke<boolean>('get_autostart_enabled'));
  } catch (e) {
    console.error('自動起動状態の取得に失敗:', e);
  }
}

// ── Footer 更新バッジ (Zed / VS Code のステータスバー風) ──
// 起動時のサイレントチェックではダイアログを出さず、バージョン番号の隣に
// 控えめなバッジを出すだけにする。クリック時に実行する更新フローは
// プラットフォーム依存なので関数として保持しておく。
let runUpdate: (() => Promise<void>) | null = null;

function showUpdateBadge(version: string, run: () => Promise<void>): void {
  runUpdate = run;
  const btn = document.getElementById('footer-update');
  if (!btn) return;
  btn.textContent = `↑ v${version}`;
  btn.title = `新しいバージョン v${version} が利用可能です（クリックで更新）`;
  btn.classList.remove('hidden');
}

function hideUpdateBadge(): void {
  runUpdate = null;
  document.getElementById('footer-update')?.classList.add('hidden');
}

// ── Updater 共通スケルトン ──
// 「バージョン取得 → 見つかればバッジ提示 (+ 非 silent 時は run 実行) → 見つからなければ
// バッジ非表示 (+ 非 silent 時は最新メッセージ)」の分岐は installer / script 共通。
// 取得元 (fetchUpdate) と実際の更新処理 (run) だけが実装ごとに異なるため引数化する。
interface UpdateFound {
  /** バッジ・ダイアログに表示するバージョン文字列 */
  version: string;
  /** 実際の更新処理 (バッジクリック or 非 silent 時の即時実行の両方から呼ばれる) */
  run: () => Promise<void>;
}

async function runUpdateCheck(
  silent: boolean,
  fetchUpdate: (currentVersion: string) => Promise<UpdateFound | null>,
): Promise<void> {
  try {
    const currentVersion = await invoke<string>('get_app_version');
    const found = await fetchUpdate(currentVersion);
    if (found) {
      showUpdateBadge(found.version, found.run);
      // トレイからの手動チェックは即ダイアログ。サイレント時はバッジのみ。
      if (!silent) await found.run();
    } else {
      hideUpdateBadge();
      if (!silent) await message(`v${currentVersion} は最新です。`, { title: 'アップデート' });
    }
  } catch (e) {
    console.error('[updater]', e);
    if (!silent)
      await message('アップデート確認に失敗しました:\n' + String(e), {
        title: 'エラー',
        kind: 'error',
      });
  }
}

// ── Updater (installer: Windows / tauri-plugin-updater) ──
async function checkForUpdate(silent = true): Promise<void> {
  await runUpdateCheck(silent, async (currentVersion) => {
    const update = await invoke<UpdateInfo | null>('check_update');
    if (!update) return null;
    return {
      version: update.version,
      run: async () => {
        if (
          await ask(`現在: v${currentVersion} → 最新: v${update.version}\nアップデートしますか？`, {
            title: 'アップデート',
          })
        ) {
          await invoke('stop_kanata');
          await invoke('install_update');
        }
      },
    };
  });
}

// ── Updater (script: Linux/macOS / GitHub API + terminal spawn) ──
const GITHUB_LATEST_RELEASE_URL =
  'https://api.github.com/repos/kimushun1101/muhenkan-switch/releases/latest';

async function checkGithubLatestRelease(silent = true): Promise<void> {
  await runUpdateCheck(silent, async (currentVersion) => {
    const res = await fetch(GITHUB_LATEST_RELEASE_URL);
    if (!res.ok) {
      throw new Error(`GitHub API エラー: HTTP ${res.status}`);
    }
    const release = (await res.json()) as { tag_name?: string };
    if (!release.tag_name) {
      throw new Error('tag_name が取得できませんでした');
    }
    const latestVersion = release.tag_name.replace(/^v/, '');

    if (latestVersion === currentVersion) return null;

    return {
      version: latestVersion,
      run: async () => {
        const proceed = await ask(
          `現在: v${currentVersion} → 最新: v${latestVersion}\n\n` +
            `ターミナルでアップデートを実行しますか？`,
          { title: 'アップデート' },
        );
        if (!proceed) return;

        try {
          await invoke('spawn_update_terminal');
        } catch (e) {
          await message(
            `ターミナルの起動に失敗しました:\n${String(e)}\n\n` +
              `手動で update.sh / update-macos.sh を実行してください。`,
            { title: 'エラー', kind: 'error' },
          );
        }
      },
    };
  });
}

export interface InitGeneralFormOptions {
  renderConfig: () => void;
}

export function initGeneralForm({ renderConfig }: InitGeneralFormOptions): void {
  // ── Config export / import ──
  document.getElementById('btn-export-config')?.addEventListener('click', async () => {
    try {
      const exported = await invoke<boolean>('export_config');
      if (exported) {
        await message('設定ファイルをエクスポートしました。', { title: 'エクスポート' });
      }
    } catch (e) {
      await message('エクスポートに失敗しました:\n' + String(e), {
        title: 'エラー',
        kind: 'error',
      });
    }
  });

  document.getElementById('btn-import-config')?.addEventListener('click', async () => {
    const ok = await ask('現在の設定を上書きします。よろしいですか？', {
      title: 'インポート',
      kind: 'warning',
    });
    if (!ok) return;
    try {
      const newConfig = await invoke<Config | null>('import_config');
      if (newConfig) {
        setConfig(newConfig);
        renderConfig();
        await message('設定ファイルをインポートしました。', { title: 'インポート' });
      }
    } catch (e) {
      await message('インポートに失敗しました:\n' + String(e), { title: 'エラー', kind: 'error' });
    }
  });

  // ── General tab: help / install dir / quit ──
  document.getElementById('btn-help')?.addEventListener('click', async () => {
    try {
      await invoke('open_help_window');
    } catch (e) {
      console.error('ヘルプウィンドウの表示に失敗:', e);
    }
  });

  document.getElementById('btn-github')?.addEventListener('click', async () => {
    await shellOpen('https://github.com/kimushun1101/muhenkan-switch');
  });

  document.getElementById('btn-open-dir')?.addEventListener('click', async () => {
    try {
      await invoke('open_install_dir');
    } catch (e) {
      await message('インストール先を開けませんでした:\n' + String(e), {
        title: 'エラー',
        kind: 'error',
      });
    }
  });

  document.getElementById('btn-quit')?.addEventListener('click', async () => {
    await invoke('quit_app');
  });

  // ── Autostart checkbox listener ──
  // 実際の反映は 'autostart-changed' イベント経由 (バックエンドが実状態を読み直して
  // emit する) で行うため、ここでは呼び出しの成否をログするだけでよい。
  const autostartCheckbox = document.getElementById('opt-autostart') as HTMLInputElement | null;
  if (autostartCheckbox) {
    autostartCheckbox.addEventListener('change', async () => {
      try {
        await invoke('set_autostart_enabled', { enabled: autostartCheckbox.checked });
      } catch (e) {
        console.error('自動起動の切り替えに失敗:', e);
      }
    });
  }

  // ── Autostart 状態同期イベント (トレイ⇔GUI 双方向) ──
  void listen<boolean>('autostart-changed', (event) => {
    setAutostartCheckbox(event.payload);
  });

  // ── Kanata status event ──
  void listen<boolean>('kanata-status-changed', (event) => {
    updateKanataUI(event.payload);
  });
}

// ── Updater initialization (called from main init after install type check) ──
export async function initUpdater(): Promise<void> {
  // Footer の更新バッジクリックで更新フローを実行
  document.getElementById('footer-update')?.addEventListener('click', () => {
    void runUpdate?.();
  });

  const installType = await invoke<string>('get_install_type');
  // installer (Windows): tauri-plugin-updater 経由
  // script (Linux/macOS): GitHub API + ターミナルで update スクリプト spawn
  const check: (silent?: boolean) => Promise<void> =
    installType === 'installer' ? checkForUpdate : checkGithubLatestRelease;

  // 起動 5 秒後にサイレントチェック
  setTimeout(() => void check(true), 5000);

  // トレイメニュー「アップデートを確認...」からの手動チェック
  void listen('check-update-requested', () => void check(false));
}
