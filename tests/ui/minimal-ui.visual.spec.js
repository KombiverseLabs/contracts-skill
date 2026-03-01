const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const net = require('net');
const { spawn } = require('child_process');

async function getFreePort() {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.unref();
    server.on('error', reject);
    server.listen(0, '127.0.0.1', () => {
      const addr = server.address();
      const port = typeof addr === 'object' && addr ? addr.port : null;
      server.close(() => resolve(port));
    });
  });
}

function copyDir(src, dst) {
  fs.mkdirSync(dst, { recursive: true });
  for (const ent of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, ent.name);
    const d = path.join(dst, ent.name);
    if (ent.isDirectory()) copyDir(s, d);
    else if (ent.isFile()) fs.copyFileSync(s, d);
  }
}

function startServer({ port, projectRoot }) {
  const serverJs = path.resolve(__dirname, '../../skill/ui/minimal-ui/server.js');
  const child = spawn(process.execPath, [serverJs, '--port', String(port), '--project-root', projectRoot], {
    stdio: ['ignore', 'pipe', 'pipe'],
    windowsHide: true,
  });

  return {
    child,
    async waitReady() {
      const deadline = Date.now() + 10_000;
      let out = '';
      return new Promise((resolve, reject) => {
        const onData = (b) => {
          out += b.toString('utf8');
          if (out.includes('live server running')) resolve();
          if (Date.now() > deadline) reject(new Error('Server did not become ready in time.'));
        };
        child.stdout.on('data', onData);
        child.stderr.on('data', onData);
        child.on('exit', (code) => reject(new Error(`Server exited early (${code}). Output:\n${out}`)));
        const tick = setInterval(() => {
          if (Date.now() > deadline) {
            clearInterval(tick);
            reject(new Error('Server did not become ready in time.'));
          }
        }, 250);
      });
    },
    stop() {
      try { child.kill(); } catch {}
    },
  };
}

test('UI: list, open, apply edit', async ({ page }) => {
  const repoRoot = path.resolve(__dirname, '../..');
  const sample = path.join(repoRoot, 'examples', 'sample-project');

  const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-ui-'));
  const projectRoot = path.join(tmpRoot, 'sample-project');
  copyDir(sample, projectRoot);

  const port = await getFreePort();
  const server = startServer({ port, projectRoot });
  await server.waitReady();

  try {
    await page.goto(`http://127.0.0.1:${port}/`, { waitUntil: 'domcontentloaded' });

    await page.waitForSelector('#tbl:not([hidden])');

    // Visual: list view
    await expect(page).toHaveScreenshot('minimal-ui-list.png', { fullPage: true });

    // Open a known contract
    const row = page.locator('tr', { hasText: 'src/core/auth' });
    await expect(row).toBeVisible();
    await row.getByRole('button', { name: 'Open MD' }).click();

    await page.waitForSelector('#dlg[open]');
    await expect(page).toHaveScreenshot('minimal-ui-editor.png', { fullPage: true });

    const mdPath = path.join(projectRoot, 'src', 'core', 'auth', 'CONTRACT.md');
    const before = fs.readFileSync(mdPath, 'utf8');

    const marker = `\n\n<!-- ui-test:${Date.now()} -->\n`;
    const nextText = before + marker;
    await page.locator('#ta').evaluate((el, value) => { el.value = value; }, nextText);

    // Apply writes via localhost API
    await page.getByRole('button', { name: 'Apply' }).click();

    // UI closes the dialog after a successful write
    await page.waitForFunction(() => {
      const d = document.querySelector('#dlg');
      return !d || d.open === false;
    });

    // Ensure file changed on disk
    const after = fs.readFileSync(mdPath, 'utf8');
    expect(after).toContain(marker.trim());
  } finally {
    server.stop();
    try { fs.rmSync(tmpRoot, { recursive: true, force: true }); } catch {}
  }
});
