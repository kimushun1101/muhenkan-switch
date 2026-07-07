// dom-utils.ts の requireEl テスト
import { afterEach, describe, expect, it } from 'vitest';
import { requireEl } from '../dom-utils';

afterEach(() => {
  document.body.innerHTML = '';
});

describe('requireEl', () => {
  it('returns the element when it exists', () => {
    const el = document.createElement('div');
    el.id = 'existing';
    document.body.appendChild(el);

    expect(requireEl<HTMLDivElement>('existing')).toBe(el);
  });

  it('throws a descriptive error when the element does not exist', () => {
    expect(() => requireEl('missing')).toThrow('Required element #missing not found');
  });

  it('returns a typed element usable as the requested HTMLElement subtype', () => {
    const input = document.createElement('input');
    input.id = 'ts-format-custom';
    input.value = 'hello';
    document.body.appendChild(input);

    const found = requireEl<HTMLInputElement>('ts-format-custom');
    expect(found.value).toBe('hello');
  });
});
