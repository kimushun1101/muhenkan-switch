// dispatch-key.ts の DOM 系ロジックテスト (happy-dom)
import { afterEach, describe, expect, it } from 'vitest';
import { createDispatchKeySelect, validateDispatchKeys } from '../dispatch-key';
import { DISPATCH_KEYS } from '../state';

afterEach(() => {
  document.body.innerHTML = '';
});

describe('createDispatchKeySelect', () => {
  it('creates a <select> element with dispatch-key-select class', () => {
    const select = createDispatchKeySelect();
    expect(select.tagName).toBe('SELECT');
    expect(select.className).toBe('dispatch-key-select');
  });

  it('starts with an empty "—" placeholder option followed by all DISPATCH_KEYS', () => {
    const select = createDispatchKeySelect();
    expect(select.options.length).toBe(DISPATCH_KEYS.length + 1);
    expect(select.options[0]?.value).toBe('');
    expect(select.options[0]?.textContent).toBe('—');
    // 末尾のオプションが DISPATCH_KEYS の末尾と一致することを確認
    const last = select.options[select.options.length - 1];
    expect(last?.value).toBe(DISPATCH_KEYS[DISPATCH_KEYS.length - 1]);
  });

  it('preselects the given key when it exists in DISPATCH_KEYS', () => {
    const select = createDispatchKeySelect('a');
    expect(select.value).toBe('a');
  });

  it('falls back to empty value when no key is provided', () => {
    const select = createDispatchKeySelect();
    expect(select.value).toBe('');
  });

  it('falls back to empty value when the preselect key is not in DISPATCH_KEYS', () => {
    // WHATWG HTML 仕様 (HTMLSelectElement.value setter) により、マッチする option が
    // 無い value をセットすると selectedIndex=-1 となり、value getter は空文字を返す
    // (= 最初の '—' option ではなく "選択なし")。happy-dom も同仕様に従うことを pin する。
    const select = createDispatchKeySelect('qqqqqqq');
    expect(select.value).toBe('');
  });
});

describe('validateDispatchKeys', () => {
  function appendSelect(value: string): void {
    const select = createDispatchKeySelect(value);
    document.body.appendChild(select);
  }

  it('returns null when no selects are present', () => {
    expect(validateDispatchKeys()).toBeNull();
  });

  it('returns null when keys are unique', () => {
    appendSelect('a');
    appendSelect('s');
    expect(validateDispatchKeys()).toBeNull();
  });

  it('ignores empty values when checking duplicates', () => {
    appendSelect('');
    appendSelect('');
    appendSelect('a');
    expect(validateDispatchKeys()).toBeNull();
  });

  it('returns an error message when keys are duplicated', () => {
    appendSelect('a');
    appendSelect('a');
    expect(validateDispatchKeys()).toBe('割当キー "A" が重複しています');
  });
});
