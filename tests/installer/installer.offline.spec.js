const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function writeFile(p, content) {
  mkdirp(path.dirname(p));
  fs.writeFileSync(p, content, 'utf8');
}

function readFile(p) {
  return fs.readFileSync(p, 'utf8');
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

test('offline install: multi-agent + instruction hooks', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-installer-'));
  const fakeHome = path.join(tmp, 'home');
  const fakeAppData = path.join(tmp, 'appdata');
  const projectRoot = path.join(tmp, 'project');

  mkdirp(fakeHome);
  mkdirp(fakeAppData);
  mkdirp(projectRoot);

  // Mark agents as "detected" (installer uses these paths)
  mkdirp(path.join(fakeHome, '.copilot'));
  mkdirp(path.join(fakeHome, '.claude'));
  mkdirp(path.join(fakeHome, '.cursor'));
  mkdirp(path.join(fakeHome, '.codex'));

  // Mark project as a project (for project-local agent)
  mkdirp(path.join(projectRoot, '.git'));

  const env = {
    USERPROFILE: fakeHome,
    APPDATA: fakeAppData,
    LOCALAPPDATA: path.join(fakeAppData, 'Local'),
    TEMP: tmp,
  };

  try {
    await runPowershellFile({
      filePath: installPs1,
      cwd: projectRoot,
      env,
      args: [
        '-Agents',
        'copilot,claude,cursor,codex,local',
        '-UseLocalSource',
        '-NoUI',
      ],
    });

    // Instruction hooks written into the project
    const copilotInstr = path.join(projectRoot, '.github', 'copilot-instructions.md');
    const claudeInstr = path.join(projectRoot, 'CLAUDE.md');
    const cursorInstr = path.join(projectRoot, '.cursor', 'rules', 'contracts-system.mdc');
    const codexInstr = path.join(projectRoot, 'codex.md');

    for (const p of [copilotInstr, claudeInstr, cursorInstr, codexInstr]) {
      expect(fs.existsSync(p), `${p} should exist`).toBeTruthy();
      const txt = readFile(p);
      expect(txt).toMatch(/Contracts?\s+System/i);
      expect(txt).toMatch(/CONTRACT\.md/i);
      expect(txt).toMatch(/source_hash|constraints/i);
    }

    // Skill installed into each agent home
    const installedSkillPaths = [
      path.join(fakeHome, '.copilot', 'skills', 'contracts'),
      path.join(fakeHome, '.claude', 'skills', 'contracts'),
      path.join(fakeHome, '.cursor', 'skills', 'contracts'),
      path.join(fakeHome, '.codex', 'skills', 'contracts'),
      path.join(projectRoot, '.agent', 'skills', 'contracts'),
    ];

    for (const p of installedSkillPaths) {
      expect(fs.existsSync(path.join(p, 'SKILL.md')), `${p}/SKILL.md should exist`).toBeTruthy();
      expect(fs.existsSync(path.join(p, 'references', 'assistant-hooks', 'contract-preflight.md'))).toBeTruthy();
      const skillMd = readFile(path.join(p, 'SKILL.md'));
      expect(skillMd).toMatch(/contract preflight/i);
    }

    // Cleanup (test verifies we can fully remove installed artifacts)
    for (const p of installedSkillPaths) {
      fs.rmSync(p, { recursive: true, force: true });
      expect(fs.existsSync(p)).toBeFalsy();
    }

    for (const p of [copilotInstr, claudeInstr, cursorInstr, codexInstr]) {
      fs.rmSync(p, { force: true });
      expect(fs.existsSync(p)).toBeFalsy();
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

    // Introduce drift
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
