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

function sha256Contract(text) {
  return `sha256:${crypto.createHash('sha256').update(text.replace(/\r\n/g, '\n'), 'utf8').digest('hex')}`;
}

function runNode({ script, args = [], cwd }) {
  return new Promise((resolve, reject) => {
    const node = spawn(process.execPath, [script, ...args], { cwd, windowsHide: true });
    let output = '';
    node.stdout.on('data', (b) => (output += b.toString('utf8')));
    node.stderr.on('data', (b) => (output += b.toString('utf8')));
    node.on('error', reject);
    node.on('exit', (exitCode) => resolve({ exitCode, output }));
  });
}

function createProject(root) {
  writeFile(path.join(root, 'package.json'), JSON.stringify({ name: 'sample-init-project' }, null, 2));
  writeFile(path.join(root, 'src', 'core', 'auth', 'index.js'), [
    'export function login(user, password) {',
    '  if (!user || !password) throw new Error("missing credentials");',
    '  return { token: `token-${user}` };',
    '}',
    '',
    'export function logout() {',
    '  return true;',
    '}',
    '',
  ].join('\n'));
}

test('init-agent analyze mode does not write project files', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const initAgent = path.join(repoRoot, 'skill', 'ai', 'init-agent', 'index.js');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-init-analyze-'));
  const projectRoot = path.join(tmp, 'project');

  createProject(projectRoot);

  try {
    const result = await runNode({
      script: initAgent,
      cwd: projectRoot,
      args: ['--path', projectRoot, '--analyze'],
    });

    expect(result.exitCode).toBe(0);
    expect(fs.existsSync(path.join(projectRoot, '.contracts'))).toBe(false);
    expect(fs.existsSync(path.join(projectRoot, 'src', 'core', 'auth', 'CONTRACT.md'))).toBe(false);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('init-agent refuses apply without --yes', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const initAgent = path.join(repoRoot, 'skill', 'ai', 'init-agent', 'index.js');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-init-refuse-'));
  const projectRoot = path.join(tmp, 'project');

  createProject(projectRoot);

  try {
    const result = await runNode({
      script: initAgent,
      cwd: projectRoot,
      args: ['--path', projectRoot, '--apply'],
    });

    expect(result.exitCode).toBe(1);
    expect(result.output).toMatch(/requires --yes/i);
    expect(fs.existsSync(path.join(projectRoot, '.contracts'))).toBe(false);
    expect(fs.existsSync(path.join(projectRoot, 'src', 'core', 'auth', 'CONTRACT.md'))).toBe(false);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('init-agent apply --yes writes synced contract hash', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const initAgent = path.join(repoRoot, 'skill', 'ai', 'init-agent', 'index.js');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-init-apply-'));
  const projectRoot = path.join(tmp, 'project');

  createProject(projectRoot);

  try {
    const result = await runNode({
      script: initAgent,
      cwd: projectRoot,
      args: ['--path', projectRoot, '--apply', '--yes'],
    });

    expect(result.exitCode).toBe(0);

    const mdPath = path.join(projectRoot, 'src', 'core', 'auth', 'CONTRACT.md');
    const yamlPath = path.join(projectRoot, 'src', 'core', 'auth', 'CONTRACT.yaml');
    const registryPath = path.join(projectRoot, '.contracts', 'registry.yaml');
    const guidePath = path.join(projectRoot, '.contracts', 'CONTRACTS-GUIDE.md');

    expect(fs.existsSync(mdPath)).toBe(true);
    expect(fs.existsSync(yamlPath)).toBe(true);
    expect(fs.existsSync(registryPath)).toBe(true);
    expect(fs.existsSync(guidePath)).toBe(true);

    const expectedHash = sha256Contract(readFile(mdPath));
    expect(readFile(yamlPath)).toContain(`source_hash: "${expectedHash}"`);
    expect(readFile(guidePath)).toContain('sample-init-project');
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});

test('init-agent module apply preserves existing contracts unless forced', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  const initAgent = path.join(repoRoot, 'skill', 'ai', 'init-agent', 'index.js');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-init-existing-'));
  const projectRoot = path.join(tmp, 'project');
  const moduleDir = path.join(projectRoot, 'src', 'core', 'auth');
  const mdPath = path.join(moduleDir, 'CONTRACT.md');

  createProject(projectRoot);
  writeFile(mdPath, '# Existing Contract\n');

  try {
    const result = await runNode({
      script: initAgent,
      cwd: projectRoot,
      args: ['--path', projectRoot, '--module', 'src/core/auth', '--apply', '--yes'],
    });

    expect(result.exitCode).toBe(0);
    expect(readFile(mdPath)).toBe('# Existing Contract\n');

    const forced = await runNode({
      script: initAgent,
      cwd: projectRoot,
      args: ['--path', projectRoot, '--module', 'src/core/auth', '--apply', '--yes', '--force'],
    });

    expect(forced.exitCode).toBe(0);
    expect(readFile(mdPath)).toMatch(/<!-- DRAFT/);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
});
