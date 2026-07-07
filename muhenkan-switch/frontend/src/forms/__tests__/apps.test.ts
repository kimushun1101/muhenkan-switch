// apps.ts のテスト。collectTimestamp / collectSearch / collectFolders のテストと
// 同型の DOM 組み立てパターンに加え、createAppSelect / renderAppsList / addAppRow /
// showProcessPicker / initAppsForm も含めて coverage.include の per-file 80% 閾値を
// 満たす。
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  addAppRow,
  collectApps,
  createAppSelect,
  initAppsForm,
  renderAppsList,
  showProcessPicker,
} from '../apps';
import { invoke } from '../../lib/tauri';
import { resetConfig, setAppPresets, setConfig } from '../../lib/state';
import type { CollectedConfig } from '../../lib/config-io';
import type { Config, TimestampConfig } from '../../lib/config';
import type { AppPresetMap } from '../../lib/state';

vi.mock('../../lib/tauri', () => ({
  invoke: vi.fn(),
}));

function flushMicrotasks(): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

function emptyCollected(): CollectedConfig {
  return {
    search: {},
    folders: {},
    apps: {},
    timestamp: {} as TimestampConfig,
    punctuation_style: '、。',
  };
}

function addRow(
  container: HTMLElement,
  name: string,
  process: string,
  command: string,
  dispatchKey = '',
  label = '',
): void {
  const row = document.createElement('div');
  row.className = 'list-row';
  row.innerHTML = `
    <select class="dispatch-key-select"><option value="${dispatchKey}" selected>${dispatchKey}</option></select>
    <input type="text" class="key-input" value="${name}">
    <select class="app-select">
      <option value="${process}" data-command="${command}">${label || process}</option>
    </select>
  `;
  container.appendChild(row);
}

afterEach(() => {
  document.body.innerHTML = '';
});

describe('collectApps', () => {
  it('collects a row with name, process, command and dispatch key', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, 'ブラウザ', 'chrome.exe', 'chrome', 'a', 'Chrome');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(collected.apps['ブラウザ']).toEqual({
      process: 'chrome.exe',
      key: 'a',
      command: 'chrome',
    });
  });

  it('omits key and command fields when absent', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, 'エディタ', 'code.exe', '', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(collected.apps['エディタ']).toEqual({ process: 'code.exe' });
    expect(collected.apps['エディタ']).not.toHaveProperty('key');
    expect(collected.apps['エディタ']).not.toHaveProperty('command');
  });

  it('skips a row when the name is empty', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, '   ', 'chrome.exe', 'chrome');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(Object.keys(collected.apps)).toHaveLength(0);
  });

  it('skips a row when no process is selected', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, 'なし', '', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(Object.keys(collected.apps)).toHaveLength(0);
  });

  it('skips a row missing one of the required elements', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    const row = document.createElement('div');
    row.className = 'list-row';
    // .app-select が無い不完全な行 (continue 分岐を pin する)
    row.innerHTML = `
      <select class="dispatch-key-select"><option value=""></option></select>
      <input type="text" class="key-input" value="NoAppSelect">
    `;
    container.appendChild(row);
    document.body.appendChild(container);

    const collected = emptyCollected();
    expect(() => collectApps(collected)).not.toThrow();
    expect(Object.keys(collected.apps)).toHaveLength(0);
  });

  it('renames the duplicate entry using the selected option label to avoid overwriting', () => {
    // 同名の機能名が 2 行あるとき、2 行目は "name (appLabel)" にリネームされる
    // (IndexMap のキー重複上書き回避、Issue コメント参照)。
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, '共通', 'chrome.exe', 'chrome', '', 'Chrome');
    addRow(container, '共通', 'firefox.exe', 'firefox', '', 'Firefox');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(Object.keys(collected.apps)).toEqual(['共通', '共通 (Firefox)']);
    expect(collected.apps['共通 (Firefox)']).toEqual({
      process: 'firefox.exe',
      command: 'firefox',
    });
  });

  it('uses an empty label when the duplicate option has no text content (textContent is "" not nullish)', () => {
    // selectedOpt?.textContent は要素があれば常に string ('' を含む) を返すため、
    // `?? process` フォールバックは textContent が空文字のケースでは発動しない
    // (undefined/null のときだけ発動する nullish coalescing の挙動を pin する)。
    const container = document.createElement('div');
    container.id = 'apps-list';
    const row1 = document.createElement('div');
    row1.className = 'list-row';
    row1.innerHTML = `
      <select class="dispatch-key-select"><option value=""></option></select>
      <input type="text" class="key-input" value="共通">
      <select class="app-select"><option value="proc1" data-command=""></option></select>
    `;
    const row2 = document.createElement('div');
    row2.className = 'list-row';
    row2.innerHTML = `
      <select class="dispatch-key-select"><option value=""></option></select>
      <input type="text" class="key-input" value="共通">
      <select class="app-select"><option value="proc2" data-command=""></option></select>
    `;
    container.appendChild(row1);
    container.appendChild(row2);
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(Object.keys(collected.apps)).toEqual(['共通', '共通 ()']);
  });

  it('collects multiple non-duplicate rows independently', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    addRow(container, 'ブラウザ', 'chrome.exe', 'chrome', 'a', 'Chrome');
    addRow(container, 'メール', 'outlook.exe', 'outlook', 's', 'Outlook');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectApps(collected);

    expect(Object.keys(collected.apps)).toEqual(['ブラウザ', 'メール']);
    expect(collected.apps['メール']?.key).toBe('s');
  });

  it('does nothing when the #apps-list container is absent', () => {
    const collected = emptyCollected();
    expect(() => collectApps(collected)).not.toThrow();
    expect(Object.keys(collected.apps)).toHaveLength(0);
  });
});

const APP_PRESETS: AppPresetMap = {
  ブラウザ: [
    { label: 'Chrome', process: 'chrome.exe', command: 'chrome' },
    { label: 'Firefox', process: 'firefox.exe', command: 'firefox' },
  ],
};

function makeConfig(apps: Config['apps']): Config {
  return {
    search: {},
    folders: {},
    apps,
    timestamp: { format: '%Y%m%d', position: 'before', delimiter: '_' },
    punctuation_style: '、。',
  };
}

describe('createAppSelect', () => {
  afterEach(() => {
    setAppPresets({});
  });

  it('creates a <select> with only the "—" placeholder when there are no presets and no current process', () => {
    const select = createAppSelect();
    expect(select.className).toBe('app-select');
    expect(select.options).toHaveLength(1);
    expect(select.options[0]?.value).toBe('');
    expect(select.options[0]?.textContent).toBe('—');
    expect(select.value).toBe('');
  });

  it('builds an optgroup per category with options carrying the command in dataset', () => {
    setAppPresets(APP_PRESETS);
    const select = createAppSelect('firefox.exe', 'firefox');

    const group = select.querySelector('optgroup');
    expect(group?.label).toBe('ブラウザ');
    expect(select.querySelectorAll('option')).toHaveLength(3); // "—" + Chrome + Firefox
    expect(select.value).toBe('firefox.exe');
    const firefoxOpt = Array.from(select.options).find((o) => o.value === 'firefox.exe');
    expect(firefoxOpt?.dataset['command']).toBe('firefox');
    expect(firefoxOpt?.textContent).toBe('Firefox');
  });

  it('appends a custom option when currentProcess is not among the presets', () => {
    setAppPresets(APP_PRESETS);
    const select = createAppSelect('custom.exe', 'custom-cmd');

    const customOpt = Array.from(select.options).find((o) => o.value === 'custom.exe');
    expect(customOpt?.textContent).toBe('custom.exe（カスタム）');
    expect(customOpt?.dataset['command']).toBe('custom-cmd');
    expect(select.value).toBe('custom.exe');
  });

  it('falls back to the lowercased process name as the command when currentCommand is empty', () => {
    setAppPresets(APP_PRESETS);
    const select = createAppSelect('Custom.EXE', '');

    const customOpt = Array.from(select.options).find((o) => o.value === 'Custom.EXE');
    expect(customOpt?.dataset['command']).toBe('custom.exe');
  });
});

describe('renderAppsList', () => {
  afterEach(() => {
    resetConfig();
  });

  it('returns early without throwing when no config is set', () => {
    const container = document.createElement('div');
    container.id = 'apps-list';
    document.body.appendChild(container);

    resetConfig();
    expect(() => renderAppsList()).not.toThrow();
    expect(container.innerHTML).toBe('');
  });

  it('returns early without throwing when the #apps-list container is absent', () => {
    setConfig(makeConfig({ ブラウザ: { process: 'chrome.exe' } }));
    expect(() => renderAppsList()).not.toThrow();
  });

  it('renders one row per configured app entry, with and without key/command', () => {
    setConfig(
      makeConfig({
        ブラウザ: { process: 'chrome.exe', command: 'chrome', key: 'a' },
        エディタ: { process: 'code.exe' },
      }),
    );
    const container = document.createElement('div');
    container.id = 'apps-list';
    document.body.appendChild(container);

    renderAppsList();

    const rows = container.querySelectorAll('.list-row');
    expect(rows).toHaveLength(2);
    expect(rows[0]?.querySelector<HTMLInputElement>('.key-input')?.value).toBe('ブラウザ');
    expect(rows[0]?.querySelector<HTMLSelectElement>('.dispatch-key-select')?.value).toBe('a');
  });

  it('clears any previously rendered rows before re-rendering', () => {
    setConfig(makeConfig({ ブラウザ: { process: 'chrome.exe' } }));
    const container = document.createElement('div');
    container.id = 'apps-list';
    container.innerHTML = '<div class="list-row stale"></div>';
    document.body.appendChild(container);

    renderAppsList();

    expect(container.querySelectorAll('.list-row.stale')).toHaveLength(0);
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);
  });
});

describe('addAppRow', () => {
  beforeEach(() => {
    vi.mocked(invoke).mockReset();
  });

  afterEach(() => {
    document.body.innerHTML = '';
    setAppPresets({});
  });

  it('appends a row with key-input, app-select and dispatch-key-select prefilled', () => {
    setAppPresets(APP_PRESETS);
    const container = document.createElement('div');
    addAppRow(container, 'ブラウザ', 'chrome.exe', 'chrome', 'a');

    const row = container.querySelector('.list-row');
    expect(row?.querySelector<HTMLInputElement>('.key-input')?.value).toBe('ブラウザ');
    expect(row?.querySelector<HTMLSelectElement>('.app-select')?.value).toBe('chrome.exe');
    expect(row?.querySelector<HTMLSelectElement>('.dispatch-key-select')?.value).toBe('a');
  });

  it('removes the row when the remove button is clicked', () => {
    const container = document.createElement('div');
    addAppRow(container);
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);

    container.querySelector<HTMLButtonElement>('.btn-remove')?.click();

    expect(container.querySelectorAll('.list-row')).toHaveLength(0);
  });

  it('renames the row to "category (label)" when an optgroup option is selected', () => {
    setAppPresets(APP_PRESETS);
    const container = document.createElement('div');
    addAppRow(container);
    const row = container.querySelector('.list-row') as HTMLElement;
    const appSelect = row.querySelector<HTMLSelectElement>('.app-select');
    const nameInput = row.querySelector<HTMLInputElement>('.key-input');
    if (!appSelect || !nameInput) throw new Error('missing elements');

    appSelect.value = 'chrome.exe';
    appSelect.dispatchEvent(new Event('change'));

    expect(nameInput.value).toBe('ブラウザ (Chrome)');
  });

  it('leaves the name input untouched when the selected option is not inside an optgroup', () => {
    setAppPresets(APP_PRESETS);
    const container = document.createElement('div');
    addAppRow(container, '既存の名前');
    const row = container.querySelector('.list-row') as HTMLElement;
    const appSelect = row.querySelector<HTMLSelectElement>('.app-select');
    const nameInput = row.querySelector<HTMLInputElement>('.key-input');
    if (!appSelect || !nameInput) throw new Error('missing elements');

    appSelect.value = ''; // "—" は optgroup の外
    appSelect.dispatchEvent(new Event('change'));

    expect(nameInput.value).toBe('既存の名前');
  });

  it('adds and selects a new custom option when a not-yet-listed process is picked', async () => {
    vi.mocked(invoke).mockResolvedValueOnce([{ name: 'MyApp.exe', pid: 123 }]);
    const container = document.createElement('div');
    addAppRow(container);
    document.body.appendChild(container);

    container.querySelector<HTMLButtonElement>('.btn-pick-process')?.click();
    await flushMicrotasks();

    const item = document.querySelector<HTMLLIElement>('.modal-list li');
    expect(item?.textContent).toBe('MyApp.exe');
    item?.click();
    await flushMicrotasks();

    const appSelect = container.querySelector<HTMLSelectElement>('.app-select');
    expect(appSelect?.value).toBe('MyApp');
    const customOpt = Array.from(appSelect?.options ?? []).find((o) => o.value === 'MyApp');
    expect(customOpt?.textContent).toBe('MyApp（カスタム）');
  });

  it('selects an already-listed option without duplicating it when picked', async () => {
    // showProcessPicker は選択時に ".exe" を除去するため、既存オプションと一致
    // させるには拡張子なしのプロセス名を使う必要がある。
    setAppPresets({
      ツール: [{ label: 'MyTool', process: 'mytool', command: 'mytool' }],
    });
    vi.mocked(invoke).mockResolvedValueOnce([{ name: 'mytool', pid: 1 }]);
    const container = document.createElement('div');
    addAppRow(container);
    document.body.appendChild(container);

    const optionsBefore = container.querySelector<HTMLSelectElement>('.app-select')?.options.length;

    container.querySelector<HTMLButtonElement>('.btn-pick-process')?.click();
    await flushMicrotasks();
    document.querySelector<HTMLLIElement>('.modal-list li')?.click();
    await flushMicrotasks();

    const appSelect = container.querySelector<HTMLSelectElement>('.app-select');
    expect(appSelect?.value).toBe('mytool');
    expect(appSelect?.options.length).toBe(optionsBefore);
  });

  it('leaves the app-select untouched when the process picker is cancelled', async () => {
    vi.mocked(invoke).mockResolvedValueOnce([{ name: 'MyApp.exe', pid: 123 }]);
    const container = document.createElement('div');
    addAppRow(container);
    document.body.appendChild(container);

    container.querySelector<HTMLButtonElement>('.btn-pick-process')?.click();
    await flushMicrotasks();
    document.querySelector<HTMLButtonElement>('.btn-cancel')?.click();
    await flushMicrotasks();

    expect(container.querySelector<HTMLSelectElement>('.app-select')?.value).toBe('');
  });
});

describe('showProcessPicker', () => {
  beforeEach(() => {
    vi.mocked(invoke).mockReset();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('resolves to null and logs an error when invoke rejects', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    vi.mocked(invoke).mockRejectedValueOnce(new Error('failed'));

    const result = await showProcessPicker();

    expect(result).toBeNull();
    expect(consoleError).toHaveBeenCalledWith('プロセス一覧の取得に失敗:', expect.any(Error));
    consoleError.mockRestore();
  });

  it('filters the process list by name (case-insensitive) and strips .exe on selection', async () => {
    vi.mocked(invoke).mockResolvedValueOnce([
      { name: 'Chrome.EXE', pid: 1 },
      { name: 'firefox', pid: 2 },
    ]);

    const pending = showProcessPicker();
    await flushMicrotasks();

    const searchInput = document.querySelector<HTMLInputElement>('.modal-search');
    expect(document.querySelectorAll('.modal-list li')).toHaveLength(2);

    if (searchInput) searchInput.value = 'chrome';
    searchInput?.dispatchEvent(new Event('input'));
    const items = document.querySelectorAll<HTMLLIElement>('.modal-list li');
    expect(items).toHaveLength(1);

    items[0]?.click();
    expect(await pending).toBe('Chrome'); // .exe が除去される
  });

  it('resolves to null when cancelled', async () => {
    vi.mocked(invoke).mockResolvedValueOnce([]);
    const pending = showProcessPicker();
    await flushMicrotasks();
    document.querySelector<HTMLButtonElement>('.btn-cancel')?.click();
    expect(await pending).toBeNull();
  });
});

describe('initAppsForm', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('adds a new row to #apps-list when #btn-add-app is clicked', () => {
    document.body.innerHTML = `
      <button id="btn-add-app"></button>
      <div id="apps-list"></div>
    `;
    initAppsForm();

    document.getElementById('btn-add-app')?.dispatchEvent(new Event('click'));

    expect(document.querySelectorAll('#apps-list .list-row')).toHaveLength(1);
  });

  it('does nothing when the button or list element is missing', () => {
    document.body.innerHTML = `<button id="btn-add-app"></button>`;
    expect(() => initAppsForm()).not.toThrow();
  });
});
