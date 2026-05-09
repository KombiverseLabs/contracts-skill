const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function writeFile(p, content) {
  mkdirp(path.dirname(p));
  fs.writeFileSync(p, content, 'utf8');
}

function runPowershellFile({ filePath, args = [], cwd }) {
  return new Promise((resolve, reject) => {
    const ps = spawn(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', filePath, ...args],
      { cwd, windowsHide: true }
    );

    let output = '';
    ps.stdout.on('data', (b) => (output += b.toString('utf8')));
    ps.stderr.on('data', (b) => (output += b.toString('utf8')));
    ps.on('error', reject);
    ps.on('exit', (code) => {
      if (code === 0) resolve(output);
      else reject(new Error(`PowerShell exited ${code}. Output:\n${output}`));
    });
  });
}

function hasOwnerWrite(filePath) {
  return (fs.statSync(filePath).mode & 0o200) !== 0;
}

test('contract lock scripts lock CONTRACT.md while leaving CONTRACT.yaml writable', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const lockPs1 = path.join(repoRoot, 'skill', 'scripts', 'lock-contracts.ps1');
  const unlockPs1 = path.join(repoRoot, 'skill', 'scripts', 'unlock-contracts.ps1');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-lock-'));
  const projectRoot = path.join(tmp, 'project');
  const moduleRoot = path.join(projectRoot, 'src', 'core', 'auth');
  const mdPath = path.join(moduleRoot, 'CONTRACT.md');
  const yamlPath = path.join(moduleRoot, 'CONTRACT.yaml');

  writeFile(mdPath, '# Auth\n\n## Purpose\nApproved contract.\n');
  writeFile(yamlPath, 'meta:\n  source_hash: "sha256:test"\n');

  try {
    await runPowershellFile({
      filePath: lockPs1,
      cwd: projectRoot,
      args: ['-Path', projectRoot],
    });

    expect(hasOwnerWrite(mdPath)).toBe(false);
    expect(hasOwnerWrite(yamlPath)).toBe(true);
    fs.appendFileSync(yamlPath, '  last_sync: "2026-05-09T00:00:00Z"\n');

    await runPowershellFile({
      filePath: unlockPs1,
      cwd: projectRoot,
      args: ['-Files', mdPath],
    });

    expect(hasOwnerWrite(mdPath)).toBe(true);
  } finally {
    try {
      fs.chmodSync(mdPath, 0o600);
    } catch {}
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
