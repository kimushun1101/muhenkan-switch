// ── Timestamp form ──
import { invoke } from "../lib/tauri.js";
import { getConfig } from "../lib/state.js";

export function renderTimestamp() {
  const config = getConfig();
  // Format
  const formatPreset = document.getElementById("ts-format-preset");
  const formatCustom = document.getElementById("ts-format-custom");
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
  const delimPreset = document.getElementById("ts-delimiter-preset");
  const delimCustom = document.getElementById("ts-delimiter-custom");
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
  document.querySelector(`input[name="ts-position"][value="${config.timestamp.position}"]`).checked = true;

  updateTimestampPreview();
}

export function getTimestampFormat() {
  const preset = document.getElementById("ts-format-preset").value;
  if (preset === "custom") {
    return document.getElementById("ts-format-custom").value;
  }
  return preset;
}

export function getTimestampDelimiter() {
  const preset = document.getElementById("ts-delimiter-preset").value;
  if (preset === "custom") {
    return document.getElementById("ts-delimiter-custom").value;
  }
  return preset;
}

export async function updateTimestampPreview() {
  const format = getTimestampFormat();
  const delimiter = getTimestampDelimiter();
  const position = document.querySelector('input[name="ts-position"]:checked').value;
  try {
    const preview = await invoke("validate_timestamp_format", { format, delimiter, position });
    document.getElementById("ts-preview").textContent = preview;
    document.getElementById("ts-preview").style.color = "";
  } catch (e) {
    document.getElementById("ts-preview").textContent = e;
    document.getElementById("ts-preview").style.color = "var(--red)";
  }
}

export function initTimestampForm() {
  document.getElementById("ts-format-preset").addEventListener("change", (e) => {
    const customInput = document.getElementById("ts-format-custom");
    if (e.target.value === "custom") {
      customInput.classList.remove("hidden");
      customInput.focus();
    } else {
      customInput.classList.add("hidden");
    }
    updateTimestampPreview();
  });

  document.getElementById("ts-format-custom").addEventListener("input", () => {
    updateTimestampPreview();
  });

  document.getElementById("ts-delimiter-preset").addEventListener("change", (e) => {
    const customInput = document.getElementById("ts-delimiter-custom");
    if (e.target.value === "custom") {
      customInput.classList.remove("hidden");
      customInput.focus();
    } else {
      customInput.classList.add("hidden");
    }
    updateTimestampPreview();
  });

  document.getElementById("ts-delimiter-custom").addEventListener("input", () => {
    updateTimestampPreview();
  });

  document.querySelectorAll('input[name="ts-position"]').forEach((radio) => {
    radio.addEventListener("change", () => updateTimestampPreview());
  });
}
