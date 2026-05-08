const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function runPowershellFile({ filePath, args = [], cwd, env = {} }) {
  return new Promise((resolve, reject) => {
    const ps = spawn(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', filePath, ...args],
      {
        cwd,
        env: { ...process.env, ...env },
        windowsHide: true,
      }
    );

    let out = '';
    ps.stdout.on('data', (b) => (out += b.toString('utf8')));
    ps.stderr.on('data', (b) => (out += b.toString('utf8')));

    ps.on('error', reject);
    ps.on('exit', (code) => {
      if (code === 0) resolve(out);
      else reject(new Error(`PowerShell exited ${code}. Output:\n${out}`));
    });
  });
}

test.describe('Standards-first installer compatibility', () => {
  let repoRoot;
  let installPs1;

  test.beforeAll(() => {
    repoRoot = path.resolve(__dirname, '../..');
    installPs1 = path.join(repoRoot, 'installers', 'install.ps1');
  });

  test('-Auto is accepted as a legacy no-op and uses the default Codex target', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-default-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);

    const env = {
      USERPROFILE: fakeHome,
      HOME: fakeHome,
      TEMP: tmp,
    };

    try {
      const output = await runPowershellFile({
        filePath: installPs1,
        cwd: projectRoot,
        env,
        args: ['-Auto', '-UseLocalSource', '-Hooks', 'none'],
      });

      expect(output).toMatch(/Installed Contracts skill/i);
      expect(fs.existsSync(path.join(fakeHome, '.codex', 'skills', 'contracts', 'SKILL.md'))).toBe(true);
      expect(fs.existsSync(path.join(fakeHome, '.claude', 'skills', 'contracts'))).toBe(false);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  test('-Profiles installs specified profiles only', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-profiles-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);

    const env = {
      USERPROFILE: fakeHome,
      HOME: fakeHome,
      TEMP: tmp,
    };

    try {
      await runPowershellFile({
        filePath: installPs1,
        cwd: projectRoot,
        env,
        args: ['-Profiles', 'claude,cursor', '-UseLocalSource', '-Hooks', 'none'],
      });

      expect(fs.existsSync(path.join(fakeHome, '.claude', 'skills', 'contracts', 'SKILL.md'))).toBe(true);
      expect(fs.existsSync(path.join(fakeHome, '.cursor', 'skills', 'contracts', 'SKILL.md'))).toBe(true);
      expect(fs.existsSync(path.join(fakeHome, '.codex', 'skills', 'contracts'))).toBe(false);
      expect(fs.existsSync(path.join(projectRoot, '.agent', 'skills', 'contracts'))).toBe(false);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });
});
