// folders.ts のテスト。collectTimestamp / collectSearch のテストと同型の DOM
// 組み立てパターンに加え、renderFoldersList / addFolderRow / initFoldersForm も
// 含めて coverage.include の per-file 80% 閾値を満たす。
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { addFolderRow, collectFolders, initFoldersForm, renderFoldersList } from '../folders';
import { invoke } from '../../lib/tauri';
import { resetConfig, setConfig } from '../../lib/state';
import type { CollectedConfig } from '../../lib/config-io';
import type { Config, TimestampConfig } from '../../lib/config';

vi.mock('../../lib/tauri', () => ({
  invoke: vi.fn(),
}));

function emptyCollected(): CollectedConfig {
  return {
    search: {},
    folders: {},
    apps: {},
    timestamp: {} as TimestampConfig,
    punctuation_style: '、。',
  };
}

function addRow(container: HTMLElement, name: string, path: string, dispatchKey = ''): void {
  const row = document.createElement('div');
  row.className = 'list-row';
  row.innerHTML = `
    <select class="dispatch-key-select"><option value="${dispatchKey}" selected>${dispatchKey}</option></select>
    <input type="text" class="key-input" value="${name}">
    <input type="text" class="path-input" value="${path}">
  `;
  container.appendChild(row);
}

afterEach(() => {
  document.body.innerHTML = '';
});

describe('collectFolders', () => {
  it('collects a row with name, path and dispatch key', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, 'Documents', '~/Documents', 'a');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(collected.folders['Documents']).toEqual({ path: '~/Documents', key: 'a' });
  });

  it('omits the key field when no dispatch key is selected', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, 'Downloads', '~/Downloads', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(collected.folders['Downloads']).toEqual({ path: '~/Downloads' });
    expect(collected.folders['Downloads']).not.toHaveProperty('key');
  });

  it('trims whitespace from the name but preserves the path value as-is except surrounding trim', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, '  Documents  ', '  ~/Documents  ', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(Object.keys(collected.folders)).toEqual(['Documents']);
    expect(collected.folders['Documents']?.path).toBe('~/Documents');
  });

  it('still collects an entry with an empty path as long as the name is present', () => {
    // folders.ts の実装は `if (name)` のみをガードにしており、
    // path が空でも entry を作る (search.ts / apps.ts と異なる非対称仕様)。
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, 'Empty', '   ', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(collected.folders['Empty']).toEqual({ path: '' });
  });

  it('skips a row when the name is empty', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, '   ', '~/Documents', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(Object.keys(collected.folders)).toHaveLength(0);
  });

  it('skips a row missing one of the required inputs', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    const row = document.createElement('div');
    row.className = 'list-row';
    // .path-input が無い不完全な行 (continue 分岐を pin する)
    row.innerHTML = `
      <select class="dispatch-key-select"><option value=""></option></select>
      <input type="text" class="key-input" value="NoPath">
    `;
    container.appendChild(row);
    document.body.appendChild(container);

    const collected = emptyCollected();
    expect(() => collectFolders(collected)).not.toThrow();
    expect(Object.keys(collected.folders)).toHaveLength(0);
  });

  it('collects multiple rows independently', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    addRow(container, 'Documents', '~/Documents', 'a');
    addRow(container, 'Downloads', '~/Downloads', 's');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectFolders(collected);

    expect(Object.keys(collected.folders)).toEqual(['Documents', 'Downloads']);
    expect(collected.folders['Downloads']?.key).toBe('s');
  });

  it('does nothing when the #folders-list container is absent', () => {
    const collected = emptyCollected();
    expect(() => collectFolders(collected)).not.toThrow();
    expect(Object.keys(collected.folders)).toHaveLength(0);
  });
});

function makeConfig(folders: Config['folders']): Config {
  return {
    search: {},
    folders,
    apps: {},
    timestamp: { format: '%Y%m%d', position: 'before', delimiter: '_' },
    punctuation_style: '、。',
  };
}

describe('renderFoldersList', () => {
  afterEach(() => {
    resetConfig();
  });

  it('returns early without throwing when no config is set', () => {
    const container = document.createElement('div');
    container.id = 'folders-list';
    document.body.appendChild(container);

    resetConfig();
    expect(() => renderFoldersList()).not.toThrow();
    expect(container.innerHTML).toBe('');
  });

  it('returns early without throwing when the #folders-list container is absent', () => {
    setConfig(makeConfig({ Documents: { path: '~/Documents' } }));
    expect(() => renderFoldersList()).not.toThrow();
  });

  it('renders one row per configured folder entry, with and without a dispatch key', () => {
    setConfig(
      makeConfig({
        Documents: { path: '~/Documents', key: 'a' },
        Downloads: { path: '~/Downloads' },
      }),
    );
    const container = document.createElement('div');
    container.id = 'folders-list';
    document.body.appendChild(container);

    renderFoldersList();

    const rows = container.querySelectorAll('.list-row');
    expect(rows).toHaveLength(2);
    expect(rows[0]?.querySelector<HTMLInputElement>('.key-input')?.value).toBe('Documents');
    expect(rows[0]?.querySelector<HTMLInputElement>('.path-input')?.value).toBe('~/Documents');
    expect(rows[0]?.querySelector<HTMLSelectElement>('.dispatch-key-select')?.value).toBe('a');
  });

  it('clears any previously rendered rows before re-rendering', () => {
    setConfig(makeConfig({ Documents: { path: '~/Documents' } }));
    const container = document.createElement('div');
    container.id = 'folders-list';
    container.innerHTML = '<div class="list-row stale"></div>';
    document.body.appendChild(container);

    renderFoldersList();

    expect(container.querySelectorAll('.list-row.stale')).toHaveLength(0);
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);
  });
});

describe('addFolderRow', () => {
  beforeEach(() => {
    vi.mocked(invoke).mockReset();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('appends a row with key-input, path-input and dispatch-key-select prefilled', () => {
    const container = document.createElement('div');
    addFolderRow(container, 'Documents', '~/Documents', 'a');

    const row = container.querySelector('.list-row');
    expect(row).not.toBeNull();
    expect(row?.querySelector<HTMLInputElement>('.key-input')?.value).toBe('Documents');
    expect(row?.querySelector<HTMLInputElement>('.path-input')?.value).toBe('~/Documents');
    expect(row?.querySelector<HTMLSelectElement>('.dispatch-key-select')?.value).toBe('a');
  });

  it('removes the row when the remove button is clicked', () => {
    const container = document.createElement('div');
    addFolderRow(container, 'Documents', '~/Documents');
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);

    container.querySelector<HTMLButtonElement>('.btn-remove')?.click();

    expect(container.querySelectorAll('.list-row')).toHaveLength(0);
  });

  it('fills the path input with the folder selected via the browse dialog', async () => {
    vi.mocked(invoke).mockResolvedValueOnce('/home/user/Selected');
    const container = document.createElement('div');
    addFolderRow(container);

    container.querySelector<HTMLButtonElement>('.btn-browse')?.dispatchEvent(new Event('click'));
    // click ハンドラは async のため、invoke の解決をまたぐ 1 tick を挟む
    await Promise.resolve();
    await Promise.resolve();

    expect(invoke).toHaveBeenCalledWith('browse_folder');
    expect(container.querySelector<HTMLInputElement>('.path-input')?.value).toBe(
      '/home/user/Selected',
    );
  });

  it('leaves the path input untouched when the browse dialog is cancelled (null)', async () => {
    vi.mocked(invoke).mockResolvedValueOnce(null);
    const container = document.createElement('div');
    addFolderRow(container, '', 'original');

    container.querySelector<HTMLButtonElement>('.btn-browse')?.dispatchEvent(new Event('click'));
    await Promise.resolve();
    await Promise.resolve();

    expect(container.querySelector<HTMLInputElement>('.path-input')?.value).toBe('original');
  });

  it('logs an error and leaves the path input untouched when invoke rejects', async () => {
    const consoleError = vi.spyOn(console, 'error').mockImplementation(() => undefined);
    vi.mocked(invoke).mockRejectedValueOnce(new Error('dialog failed'));
    const container = document.createElement('div');
    addFolderRow(container, '', 'original');

    container.querySelector<HTMLButtonElement>('.btn-browse')?.dispatchEvent(new Event('click'));
    await Promise.resolve();
    await Promise.resolve();

    expect(container.querySelector<HTMLInputElement>('.path-input')?.value).toBe('original');
    expect(consoleError).toHaveBeenCalledWith('フォルダ選択に失敗:', expect.any(Error));
    consoleError.mockRestore();
  });
});

describe('initFoldersForm', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('adds a new row to #folders-list when #btn-add-folder is clicked', () => {
    document.body.innerHTML = `
      <button id="btn-add-folder"></button>
      <div id="folders-list"></div>
    `;
    initFoldersForm();

    document.getElementById('btn-add-folder')?.dispatchEvent(new Event('click'));

    expect(document.querySelectorAll('#folders-list .list-row')).toHaveLength(1);
  });

  it('does nothing when the button or list element is missing', () => {
    document.body.innerHTML = `<button id="btn-add-folder"></button>`;
    expect(() => initFoldersForm()).not.toThrow();
  });
});
