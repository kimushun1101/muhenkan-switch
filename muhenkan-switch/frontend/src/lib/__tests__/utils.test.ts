// utils.ts の純粋関数テスト
import { describe, expect, it } from 'vitest';
import { escapeHtml } from '../utils';

describe('escapeHtml', () => {
  it('returns the same string when no special characters are present', () => {
    expect(escapeHtml('hello world')).toBe('hello world');
  });

  it('escapes ampersand', () => {
    expect(escapeHtml('A & B')).toBe('A &amp; B');
  });

  it('escapes angle brackets', () => {
    expect(escapeHtml('<div>')).toBe('&lt;div&gt;');
  });

  it('escapes double quotes', () => {
    expect(escapeHtml('say "hi"')).toBe('say &quot;hi&quot;');
  });

  it('escapes ampersand first to avoid double-escaping', () => {
    // & が再エスケープされないよう、置換順序が正しいことを確認
    expect(escapeHtml('&lt;')).toBe('&amp;lt;');
  });

  it('escapes a mix of all special characters', () => {
    expect(escapeHtml('<a href="x&y">')).toBe('&lt;a href=&quot;x&amp;y&quot;&gt;');
  });

  it('returns an empty string for empty input', () => {
    expect(escapeHtml('')).toBe('');
  });
});
