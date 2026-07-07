// state.ts の getter / setter テスト (元 main.js の module-level `let` 相当)
import { afterEach, describe, expect, it } from 'vitest';
import {
  DISPATCH_KEYS,
  getAppPresets,
  getConfig,
  getSearchPresets,
  resetConfig,
  setAppPresets,
  setConfig,
  setSearchPresets,
} from '../state';
import type { Config } from '../config';
import type { AppPresetMap, SearchPresetMap } from '../state';

function makeConfig(): Config {
  return {
    search: {},
    folders: {},
    apps: {},
    timestamp: { format: '%Y%m%d', position: 'before', delimiter: '_' },
    punctuation_style: '、。',
  };
}

afterEach(() => {
  resetConfig();
  setAppPresets({});
  setSearchPresets({});
});

describe('config getter/setter', () => {
  it('returns null before any config has been set', () => {
    expect(getConfig()).toBeNull();
  });

  it('returns the value passed to setConfig', () => {
    const config = makeConfig();
    setConfig(config);
    expect(getConfig()).toBe(config);
  });

  it('resetConfig clears the stored config back to null', () => {
    setConfig(makeConfig());
    resetConfig();
    expect(getConfig()).toBeNull();
  });
});

describe('app presets getter/setter', () => {
  it('starts as an empty object', () => {
    expect(getAppPresets()).toEqual({});
  });

  it('returns the value passed to setAppPresets', () => {
    const presets: AppPresetMap = {
      ブラウザ: [{ label: 'Chrome', process: 'chrome.exe', command: 'chrome' }],
    };
    setAppPresets(presets);
    expect(getAppPresets()).toBe(presets);
  });
});

describe('search presets getter/setter', () => {
  it('starts as an empty object', () => {
    expect(getSearchPresets()).toEqual({});
  });

  it('returns the value passed to setSearchPresets', () => {
    const presets: SearchPresetMap = {
      検索: [{ label: 'Google', url: 'https://google.com/search?q={query}' }],
    };
    setSearchPresets(presets);
    expect(getSearchPresets()).toBe(presets);
  });
});

describe('DISPATCH_KEYS', () => {
  it('contains only unique, lowercase single-character keys', () => {
    expect(new Set(DISPATCH_KEYS).size).toBe(DISPATCH_KEYS.length);
    for (const key of DISPATCH_KEYS) {
      expect(key).toMatch(/^[a-z0-9]$/);
    }
  });
});
