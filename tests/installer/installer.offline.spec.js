const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function readFile(p) {
  return fs.readFileSync(p, 'utf8');
}

function writeFile(p, content) {
  mkdirp(path.dirname(p));
  fs.writeFileSync(p, content, 'utf8');
}

function sha256File(filePath) {
  const text = fs.readFileSync(filePath, 'utf8').replace(/\r\n/g, '\n');
  const h = crypto.createHash('sha256').update(text, 'utf8').digest('hex');
  return `sha256:${h}`;
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

test('offline install: explicit target + idempotent AGENTS hook only', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-installer-'));
  const projectRoot = path.join(tmp, 'project');
  const targetPath = path.join(tmp, 'skills', 'contracts');

  mkdirp(projectRoot);

  try {
    for (let i = 0; i < 2; i++) {
      await runPowershellFile({
        filePath: installPs1,
        cwd: projectRoot,
        args: [
          '-TargetPath',
          targetPath,
          '-UseLocalSource',
          '-Hooks',
          'base',
        ],
      });
    }

    expect(fs.existsSync(path.join(targetPath, 'SKILL.md'))).toBeTruthy();
    expect(fs.existsSync(path.join(targetPath, 'agents', 'openai.yaml'))).toBeTruthy();
    expect(fs.existsSync(path.join(targetPath, 'references', 'instruction-hooks', 'base.md'))).toBeTruthy();

    const agentsPath = path.join(projectRoot, 'AGENTS.md');
    expect(fs.existsSync(agentsPath)).toBeTruthy();
    const agentsText = readFile(agentsPath);
    expect(agentsText).toMatch(/contracts-skill:start/);
    expect(agentsText).toMatch(/CONTRACT\.md/);
    expect(agentsText).toMatch(/contract preflight/i);
    expect((agentsText.match(/contracts-skill:start/g) || []).length).toBe(1);

    expect(fs.existsSync(path.join(projectRoot, '.contracts'))).toBeFalsy();
    expect(fs.existsSync(path.join(projectRoot, 'contracts-ui'))).toBeFalsy();
    expect(fs.existsSync(path.join(projectRoot, 'CLAUDE.md'))).toBeFalsy();
    expect(fs.existsSync(path.join(projectRoot, 'codex.md'))).toBeFalsy();
    expect(fs.existsSync(path.join(projectRoot, '.github', 'copilot-instructions.md'))).toBeFalsy();
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});

test('offline install: profile aliases install without agent auto-detection', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-profiles-'));
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
      args: [
        '-Agents',
        'codex,local',
        '-UseLocalSource',
        '-Hooks',
        'none',
      ],
    });

    expect(fs.existsSync(path.join(fakeHome, '.codex', 'skills', 'contracts', 'SKILL.md'))).toBeTruthy();
    expect(fs.existsSync(path.join(projectRoot, '.agent', 'skills', 'contracts', 'SKILL.md'))).toBeTruthy();
    expect(fs.existsSync(path.join(fakeHome, '.claude', 'skills', 'contracts'))).toBeFalsy();
    expect(fs.existsSync(path.join(projectRoot, 'AGENTS.md'))).toBeFalsy();
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});

test('offline install: beads auto hook and legacy mirrors', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-hooks-'));
  const projectRoot = path.join(tmp, 'project');
  const targetPath = path.join(tmp, 'skills', 'contracts');

  mkdirp(path.join(projectRoot, '.beads'));

  try {
    await runPowershellFile({
      filePath: installPs1,
      cwd: projectRoot,
      args: [
        '-TargetPath',
        targetPath,
        '-UseLocalSource',
        '-Hooks',
        'auto',
        '-LegacyHooks',
      ],
    });

    const agentsText = readFile(path.join(projectRoot, 'AGENTS.md'));
    expect(agentsText).toMatch(/Beads/i);
    expect(agentsText).toMatch(/bd\s+list|bd\s+create/i);

    const legacyFiles = [
      path.join(projectRoot, 'CLAUDE.md'),
      path.join(projectRoot, 'codex.md'),
      path.join(projectRoot, '.github', 'copilot-instructions.md'),
      path.join(projectRoot, '.cursor', 'rules', 'contracts-system.mdc'),
    ];

    for (const p of legacyFiles) {
      expect(fs.existsSync(p), `${p} should exist`).toBeTruthy();
      const text = readFile(p);
      expect(text).toMatch(/contracts-skill:start/);
      expect(text).toMatch(/Beads/i);
    }
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});

test('preflight: finds nearest contract + detects drift', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const preflightPs1 = path.join(repoRoot, 'skill', 'scripts', 'contract-preflight.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-preflight-'));
  const projectRoot = path.join(tmp, 'project');
  const modDir = path.join(projectRoot, 'src', 'core', 'auth');

  mkdirp(modDir);

  const mdPath = path.join(modDir, 'CONTRACT.md');
  const yamlPath = path.join(modDir, 'CONTRACT.yaml');
  const targetFile = path.join(modDir, 'index.ts');

  writeFile(mdPath, [
    '# Authentication',
    '',
    '## Purpose',
    'Test module.',
    '',
    '## Constraints',
    '- MUST: Keep API stable',
    '- MUST NOT: Log secrets',
    '',
  ].join('\n'));

  writeFile(targetFile, 'export const x = 1;\n');

  const hash1 = sha256File(mdPath);
  writeFile(yamlPath, [
    'meta:',
    `  source_hash: "${hash1}"`,
    '  last_sync: "2026-01-31T00:00:00Z"',
    '  tier: standard',
    '  version: "1.0"',
    'module:',
    '  name: "Authentication"',
    '  type: "core"',
    '  path: "src/core/auth"',
    'features: []',
    'constraints:',
    '  must: []',
    '  must_not: []',
    'relationships:',
    '  depends_on: []',
    '  consumed_by: []',
    'validation:',
    '  exports: []',
    'changelog: []',
    '',
  ].join('\n'));

  try {
    const out1 = await runPowershellFile({
      filePath: preflightPs1,
      cwd: projectRoot,
      args: ['-Path', projectRoot, '-Files', targetFile, '-OutputFormat', 'json'],
    });
    const res1 = JSON.parse(out1);

    expect(res1.modules.length).toBe(1);
    expect(res1.modules[0].drift.status).toBe('ok');
    expect(res1.modules[0].constraints.must).toContain('Keep API stable');
    expect(res1.modules[0].constraints.must_not).toContain('Log secrets');

    writeFile(mdPath, readFile(mdPath) + '\n- MUST: Add unit tests\n');

    const out2 = await runPowershellFile({
      filePath: preflightPs1,
      cwd: projectRoot,
      args: ['-Path', projectRoot, '-Files', targetFile, '-OutputFormat', 'json'],
    });
    const res2 = JSON.parse(out2);
    expect(res2.modules[0].drift.status).toBe('mismatch');
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});
