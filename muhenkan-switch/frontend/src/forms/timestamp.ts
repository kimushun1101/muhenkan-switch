// ── Timestamp form ──
import { invoke } from '../lib/tauri';
import { getConfig } from '../lib/state';
import type { CollectedConfig } from '../lib/config-io';
import { requireEl } from '../lib/dom-utils';

// 設定値がプリセット一覧の値と一致すればそのプリセットを選択し custom 入力を隠す。
// 一致しなければ 'custom' を選択して custom 入力にその値を反映して表示する
// (renderTimestamp の format / delimiter 初期化で使う same-shape 処理を集約)。
function applyPresetOrCustom(presetId: string, customId: string, value: string): void {
  const presetEl = requireEl<HTMLSelectElement>(presetId);
  const customEl = requireEl<HTMLInputElement>(customId);
  const matched = Array.from(presetEl.options).find((o) => o.value === value);
  if (matched) {
    presetEl.value = value;
    customEl.classList.add('hidden');
  } else {
    presetEl.value = 'custom';
    customEl.value = value;
    customEl.classList.remove('hidden');
  }
}

export function renderTimestamp(): void {
  const config = getConfig();
  if (!config) return;

  applyPresetOrCustom('ts-format-preset', 'ts-format-custom', config.timestamp.format);
  applyPresetOrCustom(
    'ts-delimiter-preset',
    'ts-delimiter-custom',
    config.timestamp.delimiter ?? '_',
  );

  // Position
  const posRadio = document.querySelector<HTMLInputElement>(
    `input[name="ts-position"][value="${config.timestamp.position}"]`,
  );
  if (posRadio) posRadio.checked = true;

  void updateTimestampPreview();
}

export function getTimestampFormat(): string {
  const preset = requireEl<HTMLSelectElement>('ts-format-preset').value;
  if (preset === 'custom') {
    return requireEl<HTMLInputElement>('ts-format-custom').value;
  }
  return preset;
}

export function getTimestampDelimiter(): string {
  const preset = requireEl<HTMLSelectElement>('ts-delimiter-preset').value;
  if (preset === 'custom') {
    return requireEl<HTMLInputElement>('ts-delimiter-custom').value;
  }
  return preset;
}

// Collect timestamp settings into the shared collected object.
// Mirrors the original logic from lib/config-io.ts so behavior is unchanged.
export function collectTimestamp(collected: CollectedConfig): void {
  const positionEl = document.querySelector<HTMLInputElement>('input[name="ts-position"]:checked');
  collected.timestamp = {
    format: getTimestampFormat(),
    position: positionEl?.value ?? 'before',
    delimiter: getTimestampDelimiter(),
  };
}

export async function updateTimestampPreview(): Promise<void> {
  const format = getTimestampFormat();
  const delimiter = getTimestampDelimiter();
  const positionEl = document.querySelector<HTMLInputElement>('input[name="ts-position"]:checked');
  const position = positionEl?.value ?? 'before';
  const previewEl = requireEl<HTMLElement>('ts-preview');
  try {
    const preview = await invoke<string>('validate_timestamp_format', {
      format,
      delimiter,
      position,
    });
    previewEl.textContent = preview;
    previewEl.style.color = '';
  } catch (e) {
    previewEl.textContent = String(e);
    previewEl.style.color = 'var(--red)';
  }
}

// preset select の change で custom 入力欄の表示/非表示 (+ フォーカス) を切り替え、
// custom 入力の input でプレビュー更新をトリガーする配線
// (initTimestampForm の format / delimiter 初期化で使う same-shape 処理を集約)。
function initPresetCustomToggle(presetId: string, customId: string): void {
  requireEl<HTMLSelectElement>(presetId).addEventListener('change', (e) => {
    const target = e.target as HTMLSelectElement;
    const customInput = requireEl<HTMLInputElement>(customId);
    if (target.value === 'custom') {
      customInput.classList.remove('hidden');
      customInput.focus();
    } else {
      customInput.classList.add('hidden');
    }
    void updateTimestampPreview();
  });

  requireEl<HTMLInputElement>(customId).addEventListener('input', () => {
    void updateTimestampPreview();
  });
}

export function initTimestampForm(): void {
  initPresetCustomToggle('ts-format-preset', 'ts-format-custom');
  initPresetCustomToggle('ts-delimiter-preset', 'ts-delimiter-custom');

  document.querySelectorAll<HTMLInputElement>('input[name="ts-position"]').forEach((radio) => {
    radio.addEventListener('change', () => void updateTimestampPreview());
  });
}
