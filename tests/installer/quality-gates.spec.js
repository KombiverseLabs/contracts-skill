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

function assertHookQuality({ text, fileLabel }) {
  expect(text, `${fileLabel}: should mention CONTRACT.md`).toMatch(/CONTRACT\.md/i);
  expect(text, `${fileLabel}: should mention drift/hash`).toMatch(/drift|source_hash|hash|constraints/i);
  expect(text, `${fileLabel}: should mention contract preflight`).toMatch(/contract preflight/i);
  expect(text, `${fileLabel}: should be idempotently marked`).toMatch(/contracts-skill:start[\s\S]*contracts-skill:end/i);

  const lines = getNonEmptyLines(text);
  expect(lines.length, `${fileLabel}: hook too long`).toBeLessThanOrEqual(18);
  expect(text.length, `${fileLabel}: hook too long`).toBeLessThanOrEqual(1400);
}

test('quality gates: AGENTS hook and optional legacy hooks are compact', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const installPs1 = path.join(repoRoot, 'installers', 'install.ps1');

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-skill-quality-'));
  const projectRoot = path.join(tmp, 'project');
  const targetPath = path.join(tmp, 'skills', 'contracts');

  mkdirp(projectRoot);

  try {
    await runPowershellFile({
      filePath: installPs1,
      cwd: projectRoot,
      args: [
        '-TargetPath',
        targetPath,
        '-UseLocalSource',
        '-Hooks',
        'base',
        '-LegacyHooks',
      ],
    });

    const hookFiles = {
      'AGENTS.md': path.join(projectRoot, 'AGENTS.md'),
      'copilot-instructions.md': path.join(projectRoot, '.github', 'copilot-instructions.md'),
      'CLAUDE.md': path.join(projectRoot, 'CLAUDE.md'),
      '.cursor/rules/contracts-system.mdc': path.join(projectRoot, '.cursor', 'rules', 'contracts-system.mdc'),
      'codex.md': path.join(projectRoot, 'codex.md'),
    };

    for (const [label, p] of Object.entries(hookFiles)) {
      expect(fs.existsSync(p), `${label} should exist`).toBeTruthy();
      assertHookQuality({ text: readFile(p), fileLabel: label });
    }
  } finally {
    try { fs.rmSync(tmp, { recursive: true, force: true }); } catch {}
  }
});

test('quality gates: installed skill has current metadata surface', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const skillDir = path.join(repoRoot, 'skill');
  const openAiYaml = path.join(skillDir, 'agents', 'openai.yaml');

  expect(fs.existsSync(openAiYaml)).toBeTruthy();
  const text = readFile(openAiYaml);
  expect(text).toContain('display_name: "Contracts"');
  expect(text).toContain('short_description: "Keep code aligned with living contracts"');
  expect(text).toContain('default_prompt: "Use $contracts to run a contract preflight before changing this module."');

  const skillMd = readFile(path.join(skillDir, 'SKILL.md'));
  expect(skillMd).toMatch(/^---\nname: contracts\ndescription: Use when/m);
  expect(skillMd.length).toBeLessThan(6500);
});
