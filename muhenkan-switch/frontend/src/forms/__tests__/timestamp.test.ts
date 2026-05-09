// timestamp.ts の薄い DOM 操作 (フォーム値 → string) テスト
//
// collectTimestamp は invoke を経由する preview 更新を含まないため、
// Tauri バックエンドのモック無しでも純粋に DOM だけで検証できる。
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { collectTimestamp, getTimestampDelimiter, getTimestampFormat } from '../timestamp';
import type { CollectedConfig } from '../../lib/config-io';
import type { TimestampConfig } from '../../lib/config';

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

beforeEach(() => {
  setupTimestampDom();
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
});
