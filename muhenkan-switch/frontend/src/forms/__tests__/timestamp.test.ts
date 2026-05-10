// timestamp.ts の薄い DOM 操作 (フォーム値 → string) テスト
//
// collectTimestamp は invoke を経由する preview 更新を含まないため、
// Tauri バックエンドのモック無しでも純粋に DOM だけで検証できる。
// renderTimestamp / initTimestampForm / updateTimestampPreview は
// `../lib/tauri` の `invoke` を経由するので vi.mock で差し替える。
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  collectTimestamp,
  getTimestampDelimiter,
  getTimestampFormat,
  initTimestampForm,
  renderTimestamp,
  updateTimestampPreview,
} from '../timestamp';
import { invoke } from '../../lib/tauri';
import { setConfig } from '../../lib/state';
import type { Config, TimestampConfig } from '../../lib/config';
import type { CollectedConfig } from '../../lib/config-io';

vi.mock('../../lib/tauri', () => ({
  invoke: vi.fn(),
}));

function setupTimestampDom(): void {
  document.body.innerHTML = `
    <select id="ts-format-preset">
      <option value="%Y%m%d">YYYYMMDD</option>
      <option value="%Y-%m-%d">YYYY-MM-DD</option>
      <option value="custom">カスタム</option>
    </select>
    <input id="ts-format-custom" type="text" value="" />
    <select id="ts-delimiter-preset">
      <option value="_">_</option>
      <option value="-">-</option>
      <option value="">なし</option>
      <option value="custom">カスタム</option>
    </select>
    <input id="ts-delimiter-custom" type="text" value="" />
    <input type="radio" name="ts-position" value="before" />
    <input type="radio" name="ts-position" value="after" />
    <span id="ts-preview"></span>
  `;
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

function makeConfig(timestamp: TimestampConfig): Config {
  return {
    search: {},
    folders: {},
    apps: {},
    timestamp,
    punctuation_style: '、。',
  };
}

beforeEach(() => {
  setupTimestampDom();
  vi.mocked(invoke).mockReset();
  // renderTimestamp の末尾 (`void updateTimestampPreview()`) で invoke が呼ばれるため、
  // 既定値を返さないと unhandled rejection 警告が出る。個別テストで mockResolvedValueOnce
  // / mockRejectedValueOnce で上書きする想定。
  vi.mocked(invoke).mockResolvedValue('preview-default');
});

afterEach(() => {
  document.body.innerHTML = '';
});

describe('getTimestampFormat', () => {
  it('returns the preset value when a non-custom preset is selected', () => {
    const preset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    preset.value = '%Y-%m-%d';
    expect(getTimestampFormat()).toBe('%Y-%m-%d');
  });

  it('returns the custom input value when "custom" is selected', () => {
    const preset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    const custom = document.getElementById('ts-format-custom') as HTMLInputElement;
    preset.value = 'custom';
    custom.value = '%Y/%m/%d';
    expect(getTimestampFormat()).toBe('%Y/%m/%d');
  });
});

describe('getTimestampDelimiter', () => {
  it('returns the preset value (including empty string) when a non-custom preset is selected', () => {
    const preset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    preset.value = '';
    expect(getTimestampDelimiter()).toBe('');
  });

  it('returns the custom input value when "custom" is selected', () => {
    const preset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    const custom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;
    preset.value = 'custom';
    custom.value = '+';
    expect(getTimestampDelimiter()).toBe('+');
  });
});

describe('collectTimestamp', () => {
  it('writes format / position / delimiter into the collected config', () => {
    (document.getElementById('ts-format-preset') as HTMLSelectElement).value = '%Y%m%d';
    (document.getElementById('ts-delimiter-preset') as HTMLSelectElement).value = '-';
    const radio = document.querySelector<HTMLInputElement>(
      'input[name="ts-position"][value="after"]',
    );
    if (radio) radio.checked = true;

    const collected = emptyCollected();
    collectTimestamp(collected);

    expect(collected.timestamp).toEqual({
      format: '%Y%m%d',
      position: 'after',
      delimiter: '-',
    });
  });

  it('falls back to position "before" when no radio is checked', () => {
    (document.getElementById('ts-format-preset') as HTMLSelectElement).value = '%Y%m%d';
    (document.getElementById('ts-delimiter-preset') as HTMLSelectElement).value = '_';

    const collected = emptyCollected();
    collectTimestamp(collected);

    expect(collected.timestamp.position).toBe('before');
  });

  it('propagates the custom delimiter input value via the "custom" preset path', () => {
    // delimiter preset='custom' + custom input='+' の組合せが
    // collected.timestamp.delimiter まで素通しで伝播することを確認 (Issue #162)。
    (document.getElementById('ts-format-preset') as HTMLSelectElement).value = '%Y%m%d';
    (document.getElementById('ts-delimiter-preset') as HTMLSelectElement).value = 'custom';
    (document.getElementById('ts-delimiter-custom') as HTMLInputElement).value = '+';

    const collected = emptyCollected();
    collectTimestamp(collected);

    expect(collected.timestamp.delimiter).toBe('+');
  });
});

describe('renderTimestamp', () => {
  it('reflects a preset-matched format / delimiter and hides custom inputs', () => {
    setConfig(
      makeConfig({
        format: '%Y-%m-%d',
        position: 'after',
        delimiter: '-',
      }),
    );

    renderTimestamp();

    const formatPreset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    const formatCustom = document.getElementById('ts-format-custom') as HTMLInputElement;
    const delimPreset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    const delimCustom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;

    expect(formatPreset.value).toBe('%Y-%m-%d');
    expect(formatCustom.classList.contains('hidden')).toBe(true);
    expect(delimPreset.value).toBe('-');
    expect(delimCustom.classList.contains('hidden')).toBe(true);

    const afterRadio = document.querySelector<HTMLInputElement>(
      'input[name="ts-position"][value="after"]',
    );
    expect(afterRadio?.checked).toBe(true);
  });

  it('switches to "custom" and reveals custom inputs when format / delimiter are not in presets', () => {
    setConfig(
      makeConfig({
        format: '%Y/%m/%d',
        position: 'before',
        delimiter: '+',
      }),
    );

    renderTimestamp();

    const formatPreset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    const formatCustom = document.getElementById('ts-format-custom') as HTMLInputElement;
    const delimPreset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    const delimCustom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;

    expect(formatPreset.value).toBe('custom');
    expect(formatCustom.value).toBe('%Y/%m/%d');
    expect(formatCustom.classList.contains('hidden')).toBe(false);

    expect(delimPreset.value).toBe('custom');
    expect(delimCustom.value).toBe('+');
    expect(delimCustom.classList.contains('hidden')).toBe(false);

    const beforeRadio = document.querySelector<HTMLInputElement>(
      'input[name="ts-position"][value="before"]',
    );
    expect(beforeRadio?.checked).toBe(true);
  });

  it('treats a null/undefined delimiter as the default "_" preset', () => {
    setConfig(
      makeConfig({
        format: '%Y%m%d',
        position: 'before',
        // 通常 Rust 側 (default_delimiter() が "_" を返す) で補完されるため undefined は
        // 来ないが、フロント側 defensive fallback (`?? '_'`) を pin するため強制注入する。
        delimiter: undefined as unknown as string,
      }),
    );

    renderTimestamp();

    const delimPreset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    const delimCustom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;
    expect(delimPreset.value).toBe('_');
    expect(delimCustom.classList.contains('hidden')).toBe(true);
  });

  it('returns early without throwing when no config is set', () => {
    // setConfig は型上 Config 必須だが、初期状態 (config==null) の早期 return 分岐
    // (timestamp.ts:9 `if (!config) return;`) を pin するため type cast で null を注入する。
    // state.ts に testability API (resetConfig 等) を追加して cast を解消する追跡 issue: #165
    setConfig(null as unknown as Config);
    expect(() => renderTimestamp()).not.toThrow();
  });
});

describe('updateTimestampPreview', () => {
  it('writes the invoke result into #ts-preview and clears the color on success', async () => {
    vi.mocked(invoke).mockResolvedValueOnce('20251231');
    (document.getElementById('ts-format-preset') as HTMLSelectElement).value = '%Y%m%d';
    (document.getElementById('ts-delimiter-preset') as HTMLSelectElement).value = '_';

    const previewEl = document.getElementById('ts-preview') as HTMLElement;
    previewEl.style.color = 'var(--red)'; // 前回のエラー残骸を再現
    await updateTimestampPreview();

    expect(previewEl.textContent).toBe('20251231');
    expect(previewEl.style.color).toBe('');
    expect(invoke).toHaveBeenCalledWith('validate_timestamp_format', {
      format: '%Y%m%d',
      delimiter: '_',
      position: 'before',
    });
  });

  it('writes the error string and a red color when invoke rejects', async () => {
    vi.mocked(invoke).mockRejectedValueOnce(new Error('bad format'));
    (document.getElementById('ts-format-preset') as HTMLSelectElement).value = '%Y%m%d';
    (document.getElementById('ts-delimiter-preset') as HTMLSelectElement).value = '_';

    const previewEl = document.getElementById('ts-preview') as HTMLElement;
    await updateTimestampPreview();

    expect(previewEl.textContent).toBe('Error: bad format');
    expect(previewEl.style.color).toBe('var(--red)');
  });
});

describe('initTimestampForm', () => {
  it('reveals format-custom on "custom" change and hides it for other presets', () => {
    initTimestampForm();
    const formatPreset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    const formatCustom = document.getElementById('ts-format-custom') as HTMLInputElement;

    formatPreset.value = 'custom';
    formatPreset.dispatchEvent(new Event('change'));
    expect(formatCustom.classList.contains('hidden')).toBe(false);

    formatPreset.value = '%Y%m%d';
    formatPreset.dispatchEvent(new Event('change'));
    expect(formatCustom.classList.contains('hidden')).toBe(true);
  });

  it('reveals delimiter-custom on "custom" change and hides it for other presets', () => {
    initTimestampForm();
    const delimPreset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    const delimCustom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;

    delimPreset.value = 'custom';
    delimPreset.dispatchEvent(new Event('change'));
    expect(delimCustom.classList.contains('hidden')).toBe(false);

    delimPreset.value = '_';
    delimPreset.dispatchEvent(new Event('change'));
    expect(delimCustom.classList.contains('hidden')).toBe(true);
  });

  it('triggers a preview update when format-custom receives input', () => {
    initTimestampForm();
    vi.mocked(invoke).mockClear();
    vi.mocked(invoke).mockResolvedValue('preview-format-custom');

    // format は preset='custom' のときだけ custom input が読まれる
    // (実コード getTimestampFormat 参照)。両方を準備した上で input 発火。
    const formatPreset = document.getElementById('ts-format-preset') as HTMLSelectElement;
    formatPreset.value = 'custom';
    const formatCustom = document.getElementById('ts-format-custom') as HTMLInputElement;
    formatCustom.value = '%Y/%m/%d';
    formatCustom.dispatchEvent(new Event('input'));

    // updateTimestampPreview の冒頭は同期で `invoke(...)` まで進むため
    // microtask flush なしでも呼び出し自体は assert 可能。
    expect(invoke).toHaveBeenCalledWith(
      'validate_timestamp_format',
      expect.objectContaining({ format: '%Y/%m/%d' }),
    );
  });

  it('triggers a preview update when delimiter-custom receives input', () => {
    initTimestampForm();
    vi.mocked(invoke).mockClear();
    vi.mocked(invoke).mockResolvedValue('preview-delim-custom');

    // delimiter は preset='custom' のときだけ custom input が読まれるので
    // 両方を準備した上で input イベントを発火させる。
    const delimPreset = document.getElementById('ts-delimiter-preset') as HTMLSelectElement;
    delimPreset.value = 'custom';
    const delimCustom = document.getElementById('ts-delimiter-custom') as HTMLInputElement;
    delimCustom.value = '+';
    delimCustom.dispatchEvent(new Event('input'));

    expect(invoke).toHaveBeenCalledWith(
      'validate_timestamp_format',
      expect.objectContaining({ delimiter: '+' }),
    );
  });

  it('triggers a preview update when a position radio changes', () => {
    initTimestampForm();
    vi.mocked(invoke).mockClear();
    vi.mocked(invoke).mockResolvedValue('preview-position');

    const afterRadio = document.querySelector<HTMLInputElement>(
      'input[name="ts-position"][value="after"]',
    );
    if (!afterRadio) throw new Error('after radio not found');
    afterRadio.checked = true;
    afterRadio.dispatchEvent(new Event('change'));

    expect(invoke).toHaveBeenCalledWith(
      'validate_timestamp_format',
      expect.objectContaining({ position: 'after' }),
    );
  });
});
