// ── Tab switching ──
export function initTabs(): void {
  document.querySelectorAll<HTMLElement>('.tab').forEach((tab) => {
    tab.addEventListener('click', () => {
      document.querySelectorAll<HTMLElement>('.tab').forEach((t) => t.classList.remove('active'));
      document.querySelectorAll<HTMLElement>('.panel').forEach((p) => p.classList.remove('active'));
      tab.classList.add('active');
      const panel = document.getElementById(`panel-${tab.dataset['tab'] ?? ''}`);
      if (panel) panel.classList.add('active');
    });
  });
}
