// search.ts のテスト。collectTimestamp のテスト (timestamp.test.ts) と同型の
// DOM 組み立てパターンに加え、renderSearchList / addSearchRow / showSearchPicker /
// initSearchForm も含めて coverage.include の per-file 80% 閾値を満たす。
import { afterEach, describe, expect, it } from 'vitest';
import {
  addSearchRow,
  collectSearch,
  initSearchForm,
  renderSearchList,
  showSearchPicker,
} from '../search';
import { resetConfig, setConfig, setSearchPresets } from '../../lib/state';
import type { CollectedConfig } from '../../lib/config-io';
import type { Config, TimestampConfig } from '../../lib/config';

// createPickerModal の Promise executor は同期実行されるため、モーダル起動直後は
// list 要素まで同期的に DOM へ追加済み。選択後の resolve → 呼び出し側の続き (await の
// 後続処理) はマイクロタスク経由になるため、明示的にフラッシュする必要がある。
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

function addRow(container: HTMLElement, name: string, url: string, dispatchKey = ''): void {
  const row = document.createElement('div');
  row.className = 'list-row';
  row.innerHTML = `
    <select class="dispatch-key-select"><option value="${dispatchKey}" selected>${dispatchKey}</option></select>
    <input type="text" class="key-input" value="${name}">
    <input type="text" class="url-input" value="${url}">
  `;
  container.appendChild(row);
}

afterEach(() => {
  document.body.innerHTML = '';
});

describe('collectSearch', () => {
  it('collects a row with name, url and dispatch key', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, 'Google', 'https://google.com/search?q={query}', 'q');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(collected.search['Google']).toEqual({
      url: 'https://google.com/search?q={query}',
      key: 'q',
    });
  });

  it('omits the key field when no dispatch key is selected', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, 'Bing', 'https://bing.com/search?q={query}', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(collected.search['Bing']).toEqual({ url: 'https://bing.com/search?q={query}' });
    expect(collected.search['Bing']).not.toHaveProperty('key');
  });

  it('trims whitespace from name and url before collecting', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, '  Google  ', '  https://google.com  ', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(Object.keys(collected.search)).toEqual(['Google']);
    expect(collected.search['Google']?.url).toBe('https://google.com');
  });

  it('skips a row when the name is empty', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, '   ', 'https://example.com', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(Object.keys(collected.search)).toHaveLength(0);
  });

  it('skips a row when the url is empty', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, 'Empty', '   ', '');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(Object.keys(collected.search)).toHaveLength(0);
  });

  it('skips a row missing one of the required inputs', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    const row = document.createElement('div');
    row.className = 'list-row';
    // .url-input が無い不完全な行 (continue 分岐を pin する)
    row.innerHTML = `
      <select class="dispatch-key-select"><option value=""></option></select>
      <input type="text" class="key-input" value="NoUrl">
    `;
    container.appendChild(row);
    document.body.appendChild(container);

    const collected = emptyCollected();
    expect(() => collectSearch(collected)).not.toThrow();
    expect(Object.keys(collected.search)).toHaveLength(0);
  });

  it('collects multiple rows independently', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    addRow(container, 'Google', 'https://google.com/{query}', 'q');
    addRow(container, 'Bing', 'https://bing.com/{query}', 'w');
    document.body.appendChild(container);

    const collected = emptyCollected();
    collectSearch(collected);

    expect(Object.keys(collected.search)).toEqual(['Google', 'Bing']);
    expect(collected.search['Bing']?.key).toBe('w');
  });

  it('does nothing when the #search-list container is absent', () => {
    const collected = emptyCollected();
    expect(() => collectSearch(collected)).not.toThrow();
    expect(Object.keys(collected.search)).toHaveLength(0);
  });
});

function makeConfig(search: Config['search']): Config {
  return {
    search,
    folders: {},
    apps: {},
    timestamp: { format: '%Y%m%d', position: 'before', delimiter: '_' },
    punctuation_style: '、。',
  };
}

describe('renderSearchList', () => {
  afterEach(() => {
    resetConfig();
  });

  it('returns early without throwing when no config is set', () => {
    const container = document.createElement('div');
    container.id = 'search-list';
    document.body.appendChild(container);

    resetConfig();
    expect(() => renderSearchList()).not.toThrow();
    expect(container.innerHTML).toBe('');
  });

  it('returns early without throwing when the #search-list container is absent', () => {
    setConfig(makeConfig({ Google: { url: 'https://google.com/{query}' } }));
    expect(() => renderSearchList()).not.toThrow();
  });

  it('renders one row per configured search entry, with and without a dispatch key', () => {
    setConfig(
      makeConfig({
        Google: { url: 'https://google.com/{query}', key: 'q' },
        Bing: { url: 'https://bing.com/{query}' },
      }),
    );
    const container = document.createElement('div');
    container.id = 'search-list';
    document.body.appendChild(container);

    renderSearchList();

    const rows = container.querySelectorAll('.list-row');
    expect(rows).toHaveLength(2);
    const firstName = rows[0]?.querySelector<HTMLInputElement>('.key-input');
    const firstUrl = rows[0]?.querySelector<HTMLInputElement>('.url-input');
    const firstKey = rows[0]?.querySelector<HTMLSelectElement>('.dispatch-key-select');
    expect(firstName?.value).toBe('Google');
    expect(firstUrl?.value).toBe('https://google.com/{query}');
    expect(firstKey?.value).toBe('q');
  });

  it('clears any previously rendered rows before re-rendering', () => {
    setConfig(makeConfig({ Google: { url: 'https://google.com/{query}' } }));
    const container = document.createElement('div');
    container.id = 'search-list';
    container.innerHTML = '<div class="list-row stale"></div>';
    document.body.appendChild(container);

    renderSearchList();

    expect(container.querySelectorAll('.list-row.stale')).toHaveLength(0);
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);
  });
});

describe('addSearchRow', () => {
  afterEach(() => {
    document.body.innerHTML = '';
    setSearchPresets({});
  });

  it('appends a row with key-input, url-input and dispatch-key-select prefilled', () => {
    const container = document.createElement('div');
    addSearchRow(container, 'Google', 'https://google.com/{query}', 'q');

    const row = container.querySelector('.list-row');
    expect(row).not.toBeNull();
    expect(row?.querySelector<HTMLInputElement>('.key-input')?.value).toBe('Google');
    expect(row?.querySelector<HTMLInputElement>('.url-input')?.value).toBe(
      'https://google.com/{query}',
    );
    expect(row?.querySelector<HTMLSelectElement>('.dispatch-key-select')?.value).toBe('q');
  });

  it('removes the row when the remove button is clicked', () => {
    const container = document.createElement('div');
    addSearchRow(container, 'Google', 'https://google.com/{query}');
    expect(container.querySelectorAll('.list-row')).toHaveLength(1);

    container.querySelector<HTMLButtonElement>('.btn-remove')?.click();

    expect(container.querySelectorAll('.list-row')).toHaveLength(0);
  });

  it('fills name/url from the selected preset when the pick button is used', async () => {
    setSearchPresets({
      検索: [{ label: 'Google', url: 'https://google.com/search?q={query}' }],
    });
    const container = document.createElement('div');
    addSearchRow(container);
    document.body.appendChild(container);

    container.querySelector<HTMLButtonElement>('.btn-pick-search')?.click();

    const item = document.querySelector<HTMLLIElement>('.modal-list li:not(.modal-list-header)');
    expect(item?.textContent).toBe('Google');
    item?.click();
    await flushMicrotasks();

    expect(container.querySelector<HTMLInputElement>('.key-input')?.value).toBe('Google');
    expect(container.querySelector<HTMLInputElement>('.url-input')?.value).toBe(
      'https://google.com/search?q={query}',
    );
  });

  it('leaves the inputs untouched when the picker is cancelled', async () => {
    setSearchPresets({
      検索: [{ label: 'Google', url: 'https://google.com/search?q={query}' }],
    });
    const container = document.createElement('div');
    addSearchRow(container);
    document.body.appendChild(container);

    container.querySelector<HTMLButtonElement>('.btn-pick-search')?.click();
    document.querySelector<HTMLButtonElement>('.btn-cancel')?.click();
    await flushMicrotasks();

    expect(container.querySelector<HTMLInputElement>('.key-input')?.value).toBe('');
    expect(container.querySelector<HTMLInputElement>('.url-input')?.value).toBe('');
  });
});

describe('showSearchPicker', () => {
  afterEach(() => {
    document.body.innerHTML = '';
    setSearchPresets({});
  });

  it('groups presets by category and filters by label or category (case-insensitive)', async () => {
    setSearchPresets({
      検索エンジン: [
        { label: 'Google', url: 'https://google.com/{query}' },
        { label: 'Bing', url: 'https://bing.com/{query}' },
      ],
      辞書: [{ label: 'Weblio', url: 'https://weblio.jp/{query}' }],
    });

    const pending = showSearchPicker();
    const searchInput = document.querySelector<HTMLInputElement>('.modal-search');
    expect(searchInput).not.toBeNull();

    // 初期表示は全カテゴリ・全件
    expect(document.querySelectorAll('.modal-list-header')).toHaveLength(2);
    expect(document.querySelectorAll('.modal-list li:not(.modal-list-header)')).toHaveLength(3);

    // ラベルでフィルタ (大文字小文字を無視)
    if (searchInput) searchInput.value = 'GOOGLE';
    searchInput?.dispatchEvent(new Event('input'));
    let items = document.querySelectorAll<HTMLLIElement>('.modal-list li:not(.modal-list-header)');
    expect(items).toHaveLength(1);
    expect(items[0]?.textContent).toBe('Google');

    // カテゴリ名でフィルタ
    if (searchInput) searchInput.value = '辞書';
    searchInput?.dispatchEvent(new Event('input'));
    items = document.querySelectorAll<HTMLLIElement>('.modal-list li:not(.modal-list-header)');
    expect(items).toHaveLength(1);
    expect(items[0]?.textContent).toBe('Weblio');

    items[0]?.click();
    const result = await pending;
    expect(result).toEqual({ label: 'Weblio', url: 'https://weblio.jp/{query}' });
  });

  it('resolves to null when cancelled', async () => {
    setSearchPresets({ 検索: [{ label: 'Google', url: 'https://google.com/{query}' }] });
    const pending = showSearchPicker();
    document.querySelector<HTMLButtonElement>('.btn-cancel')?.click();
    expect(await pending).toBeNull();
  });
});

describe('initSearchForm', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('adds a new row to #search-list when #btn-add-search is clicked', () => {
    document.body.innerHTML = `
      <button id="btn-add-search"></button>
      <div id="search-list"></div>
    `;
    initSearchForm();

    document.getElementById('btn-add-search')?.dispatchEvent(new Event('click'));

    expect(document.querySelectorAll('#search-list .list-row')).toHaveLength(1);
  });

  it('does nothing when the button or list element is missing', () => {
    document.body.innerHTML = `<button id="btn-add-search"></button>`;
    expect(() => initSearchForm()).not.toThrow();
  });
});
