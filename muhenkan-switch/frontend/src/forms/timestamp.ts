// ── Timestamp form ──
import { invoke } from "../lib/tauri";
import { getConfig } from "../lib/state";
import type { CollectedConfig } from "../lib/config-io";

/**
 * 必須 DOM 要素を取得するヘルパー (見つからなければ throw)。
 * 元 .js では non-null 前提で書かれていたので strict 化後も例外で fail-fast する。
 */
function requireEl<T extends HTMLElement>(id: string): T {
  const el = document.getElementById(id) as T | null;
  if (!el) throw new Error(`Required element #${id} not found`);
  return el;
}

export function renderTimestamp(): void {
  const config = getConfig();
  if (!config) return;

  // Format
  const formatPreset = requireEl<HTMLSelectElement>("ts-format-preset");
  const formatCustom = requireEl<HTMLInputElement>("ts-format-custom");
  const format = config.timestamp.format;

  const formatOption = Array.from(formatPreset.options).find((o) => o.value === format);
  if (formatOption) {
    formatPreset.value = format;
    formatCustom.classList.add("hidden");
  } else {
    formatPreset.value = "custom";
    formatCustom.value = format;
    formatCustom.classList.remove("hidden");
  }

  // Delimiter
  const delimPreset = requireEl<HTMLSelectElement>("ts-delimiter-preset");
  const delimCustom = requireEl<HTMLInputElement>("ts-delimiter-custom");
  const delimiter = config.timestamp.delimiter ?? "_";

  const delimOption = Array.from(delimPreset.options).find((o) => o.value === delimiter);
  if (delimOption) {
    delimPreset.value = delimiter;
    delimCustom.classList.add("hidden");
  } else {
    delimPreset.value = "custom";
    delimCustom.value = delimiter;
    delimCustom.classList.remove("hidden");
  }

  // Position
  const posRadio = document.querySelector<HTMLInputElement>(
    `input[name="ts-position"][value="${config.timestamp.position}"]`
  );
  if (posRadio) posRadio.checked = true;

  void updateTimestampPreview();
}

export function getTimestampFormat(): string {
  const preset = requireEl<HTMLSelectElement>("ts-format-preset").value;
  if (preset === "custom") {
    return requireEl<HTMLInputElement>("ts-format-custom").value;
  }
  return preset;
}

export function getTimestampDelimiter(): string {
  const preset = requireEl<HTMLSelectElement>("ts-delimiter-preset").value;
  if (preset === "custom") {
    return requireEl<HTMLInputElement>("ts-delimiter-custom").value;
  }
  return preset;
}

// Collect timestamp settings into the shared collected object.
// Mirrors the original logic from lib/config-io.ts so behavior is unchanged.
export function collectTimestamp(collected: CollectedConfig): void {
  const positionEl = document.querySelector<HTMLInputElement>('input[name="ts-position"]:checked');
  collected.timestamp = {
    format: getTimestampFormat(),
    position: positionEl?.value ?? "before",
    delimiter: getTimestampDelimiter(),
  };
}

export async function updateTimestampPreview(): Promise<void> {
  const format = getTimestampFormat();
  const delimiter = getTimestampDelimiter();
  const positionEl = document.querySelector<HTMLInputElement>('input[name="ts-position"]:checked');
  const position = positionEl?.value ?? "before";
  const previewEl = requireEl<HTMLElement>("ts-preview");
  try {
    const preview = await invoke<string>("validate_timestamp_format", { format, delimiter, position });
    previewEl.textContent = preview;
    previewEl.style.color = "";
  } catch (e) {
    previewEl.textContent = String(e);
    previewEl.style.color = "var(--red)";
  }
}

export function initTimestampForm(): void {
  requireEl<HTMLSelectElement>("ts-format-preset").addEventListener("change", (e) => {
    const target = e.target as HTMLSelectElement;
    const customInput = requireEl<HTMLInputElement>("ts-format-custom");
    if (target.value === "custom") {
      customInput.classList.remove("hidden");
      customInput.focus();
    } else {
      customInput.classList.add("hidden");
    }
    void updateTimestampPreview();
  });

  requireEl<HTMLInputElement>("ts-format-custom").addEventListener("input", () => {
    void updateTimestampPreview();
  });

  requireEl<HTMLSelectElement>("ts-delimiter-preset").addEventListener("change", (e) => {
    const target = e.target as HTMLSelectElement;
    const customInput = requireEl<HTMLInputElement>("ts-delimiter-custom");
    if (target.value === "custom") {
      customInput.classList.remove("hidden");
      customInput.focus();
    } else {
      customInput.classList.add("hidden");
    }
    void updateTimestampPreview();
  });

  requireEl<HTMLInputElement>("ts-delimiter-custom").addEventListener("input", () => {
    void updateTimestampPreview();
  });

  document.querySelectorAll<HTMLInputElement>('input[name="ts-position"]').forEach((radio) => {
    radio.addEventListener("change", () => void updateTimestampPreview());
  });
}
