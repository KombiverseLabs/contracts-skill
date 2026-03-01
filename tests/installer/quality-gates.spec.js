const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function readFile(p) {
  return fs.readFileSync(p, 'utf8');
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

function getNonEmptyLines(text) {
  return text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0);
}

function assertInstructionQuality({ text, fileLabel }) {
  // Required concepts
  expect(text, `${fileLabel}: should mention CONTRACT.md`).toMatch(/CONTRACT\.md/i);
  expect(text, `${fileLabel}: should mention CONTRACT.yaml`).toMatch(/CONTRACT\.ya?ml/i);
  expect(text, `${fileLabel}: should mention drift/hash`).toMatch(/drift|source_hash|hash/i);
  expect(text, `${fileLabel}: should mention MUST`).toMatch(/\bMUST\b/i);
  expect(text, `${fileLabel}: should mention MUST NOT`).toMatch(/MUST\s+NOT/i);
  expect(text, `${fileLabel}: should enforce brevity`).toMatch(/max\s*5\s*sentences/i);

  // Quality gate: keep snippet compact
  const lines = getNonEmptyLines(text);
  expect(lines.length, `${fileLabel}: instruction too long (non-empty lines)`).toBeLessThanOrEqual(14);
  expect(text.length, `${fileLabel}: instruction too long (chars)`).toBeLessThanOrEqual(1200);

  // Quality gate: avoid ambiguous wording (heuristic)
  expect(text, `${fileLabel}: should be imperative`).toMatch(/Before\s+(starting|any|work)/i);
}

test('quality gates: instruction hooks compact + required semantics', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-quality-'));
  const fakeHome = path.join(tmp, 'home');
  const fakeAppData = path.join(tmp, 'appdata');
  const projectRoot = path.join(tmp, 'project');

  mkdirp(fakeHome);
  mkdirp(fakeAppData);
  mkdirp(projectRoot);

  mkdirp(path.join(fakeHome, '.copilot'));
  mkdirp(path.join(fakeHome, '.claude'));
  mkdirp(path.join(fakeHome, '.cursor'));
  mkdirp(path.join(fakeHome, '.windsurf'));
  mkdirp(path.join(fakeHome, '.cline'));
  mkdirp(path.join(fakeHome, '.opencode'));

  mkdirp(path.join(projectRoot, '.git'));

  const env = {
    USERPROFILE: fakeHome,
    APPDATA: fakeAppData,
    LOCALAPPDATA: path.join(fakeAppData, 'Local'),
    TEMP: tmp,
  };

  const instructionFiles = {
    'copilot-instructions.md': path.join(projectRoot, '.github', 'copilot-instructions.md'),
    'CLAUDE.md': path.join(projectRoot, 'CLAUDE.md'),
    '.cursor/rules/contracts-system.mdc': path.join(projectRoot, '.cursor', 'rules', 'contracts-system.mdc'),
    '.windsurf/rules/01-contracts-system.md': path.join(projectRoot, '.windsurf', 'rules', '01-contracts-system.md'),
    '.clinerules/01-contracts-system.md': path.join(projectRoot, '.clinerules', '01-contracts-system.md'),
    '.opencodesettings': path.join(projectRoot, '.opencodesettings'),
  };

  try {
    await runPowershellFile({
      filePath: installPs1,
      cwd: projectRoot,
      env,
      args: [
        '-Agents',
        'copilot,claude,cursor,windsurf,cline,opencode,local',
        '-UseLocalSource',
        '-UpdateInstructions',
        '-SkipUI',
        '-SkipAgentMd',
      ],
    });

    for (const [label, p] of Object.entries(instructionFiles)) {
      expect(fs.existsSync(p), `${label} should exist`).toBeTruthy();
      const text = readFile(p);
      assertInstructionQuality({ text, fileLabel: label });
    }
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});
