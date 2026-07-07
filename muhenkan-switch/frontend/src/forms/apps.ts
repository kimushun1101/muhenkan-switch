// ── Apps form ──
import { invoke } from '../lib/tauri';
import { getConfig, getAppPresets } from '../lib/state';
import { createDispatchKeySelect } from '../lib/dispatch-key';
import { escapeHtml } from '../lib/utils';
import { createPickerModal } from '../lib/picker-modal';
import type { AppEntry } from '../lib/config';
import type { CollectedConfig } from '../lib/config-io';
import type { ProcessInfo } from '../lib/ipc-types';

// ── App select dropdown helper ──
export function createAppSelect(currentProcess = '', currentCommand = ''): HTMLSelectElement {
  const APP_PRESETS = getAppPresets();
  const select = document.createElement('select');
  select.className = 'app-select';

  const noneOpt = document.createElement('option');
  noneOpt.value = '';
  noneOpt.textContent = '—';
  select.appendChild(noneOpt);

  let hasCurrentProcess = !currentProcess;

  for (const [category, apps] of Object.entries(APP_PRESETS)) {
    const group = document.createElement('optgroup');
    group.label = category;
    for (const app of apps) {
      const opt = document.createElement('option');
      opt.value = app.process;
      opt.textContent = app.label;
      opt.dataset['command'] = app.command;
      group.appendChild(opt);
      if (app.process === currentProcess) hasCurrentProcess = true;
    }
    select.appendChild(group);
  }

  if (currentProcess && !hasCurrentProcess) {
    const opt = document.createElement('option');
    opt.value = currentProcess;
    opt.textContent = `${currentProcess}（カスタム）`;
    opt.dataset['command'] = currentCommand || currentProcess.toLowerCase();
    select.appendChild(opt);
  }

  select.value = currentProcess || '';
  return select;
}

export function renderAppsList(): void {
  const config = getConfig();
  if (!config) return;
  const container = document.getElementById('apps-list');
  if (!container) return;
  container.innerHTML = '';
  for (const [name, entry] of Object.entries(config.apps ?? {})) {
    addAppRow(container, name, entry.process, entry.command ?? '', entry.key ?? '');
  }
}

// Collect apps-list rows into the shared collected object.
// Mirrors the original logic from lib/config-io.ts so behavior is unchanged.
// 機能名の重複を防ぐ（IndexMap のキー重複で上書きされるのを回避）
export function collectApps(collected: CollectedConfig): void {
  for (const row of document.querySelectorAll<HTMLElement>('#apps-list .list-row')) {
    const nameInput = row.querySelector<HTMLInputElement>('.key-input');
    const appSelect = row.querySelector<HTMLSelectElement>('.app-select');
    const keySelect = row.querySelector<HTMLSelectElement>('.dispatch-key-select');
    if (!nameInput || !appSelect || !keySelect) continue;
    let name = nameInput.value.trim();
    const process = appSelect.value;
    const selectedOpt = appSelect.options[appSelect.selectedIndex] as HTMLOptionElement | undefined;
    const command = selectedOpt?.dataset?.['command'] ?? '';
    const dispatchKey = keySelect.value;
    if (name && process) {
      if (collected.apps[name]) {
        const appLabel = selectedOpt?.textContent ?? process;
        name = `${name} (${appLabel})`;
      }
      const entry: AppEntry = { process };
      if (dispatchKey) entry.key = dispatchKey;
      if (command) entry.command = command;
      collected.apps[name] = entry;
    }
  }
}

export function addAppRow(
  container: HTMLElement,
  name = '',
  process = '',
  command = '',
  dispatchKey = '',
): void {
  const row = document.createElement('div');
  row.className = 'list-row';
  row.innerHTML = `
    <input type="text" class="key-input" placeholder="機能名" value="${escapeHtml(name)}">
    <button class="btn-pick-process" title="実行中のプロセスから選択">選択</button>
    <button class="btn-remove" title="削除">&times;</button>
  `;
  const keySelect = createDispatchKeySelect(dispatchKey);
  row.insertBefore(keySelect, row.firstChild);

  const appSelect = createAppSelect(process, command);
  const nameInput = row.querySelector<HTMLInputElement>('.key-input');
  if (!nameInput) return;
  nameInput.insertAdjacentElement('afterend', appSelect);

  appSelect.addEventListener('change', () => {
    const selected = appSelect.options[appSelect.selectedIndex] as HTMLOptionElement | undefined;
    if (selected && selected.parentElement?.tagName === 'OPTGROUP') {
      const parent = selected.parentElement as HTMLOptGroupElement;
      const category = parent.label;
      nameInput.value = `${category} (${selected.textContent ?? ''})`;
    }
  });

  row
    .querySelector<HTMLButtonElement>('.btn-remove')
    ?.addEventListener('click', () => row.remove());
  row.querySelector<HTMLButtonElement>('.btn-pick-process')?.addEventListener('click', async () => {
    const selected = await showProcessPicker();
    if (selected) {
      let found = false;
      for (const opt of appSelect.options) {
        if (opt.value === selected) {
          found = true;
          break;
        }
      }
      if (!found) {
        const opt = document.createElement('option');
        opt.value = selected;
        opt.textContent = `${selected}（カスタム）`;
        opt.dataset['command'] = selected.toLowerCase();
        appSelect.appendChild(opt);
      }
      appSelect.value = selected;
    }
  });
  container.appendChild(row);
}

// ── Process picker modal ──
export async function showProcessPicker(): Promise<string | null> {
  let processes: ProcessInfo[] = [];
  try {
    processes = await invoke<ProcessInfo[]>('get_running_processes');
  } catch (e) {
    console.error('プロセス一覧の取得に失敗:', e);
    return null;
  }

  return createPickerModal<string>({
    title: 'プロセスを選択',
    renderList: (list, filter, select) => {
      list.innerHTML = '';
      const filtered = processes.filter((p) => p.name.toLowerCase().includes(filter.toLowerCase()));
      for (const p of filtered) {
        const li = document.createElement('li');
        li.textContent = p.name;
        li.addEventListener('click', () => {
          // Remove .exe extension
          let name = p.name;
          if (name.toLowerCase().endsWith('.exe')) {
            name = name.slice(0, -4);
          }
          select(name);
        });
        list.appendChild(li);
      }
    },
  });
}

export function initAppsForm(): void {
  const btn = document.getElementById('btn-add-app');
  const list = document.getElementById('apps-list');
  if (!btn || !list) return;
  btn.addEventListener('click', () => {
    addAppRow(list);
  });
}
