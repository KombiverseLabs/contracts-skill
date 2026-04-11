/**
 * @fileoverview Integration tests for installer interactive and non-interactive modes.
 *
 * Tests validate the simplified numbered-list selection UI and flag-based modes.
 */

const { test, expect } = require('@playwright/test');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn } = require('child_process');

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

/**
 * Run PowerShell script with optional stdin input.
 */
function runPowershellWithInput({ filePath, args = [], cwd, env = {}, stdinInput = null }) {
  return new Promise((resolve, reject) => {
    const ps = spawn(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', filePath, ...args],
      {
        cwd,
        env: { ...process.env, ...env },
        windowsHide: true,
        stdio: ['pipe', 'pipe', 'pipe']
      }
    );

    let out = '';
    let errOut = '';

    ps.stdout.on('data', (b) => {
      out += b.toString('utf8');
    });

    ps.stderr.on('data', (b) => {
      errOut += b.toString('utf8');
    });

    // Send stdin input after a short delay to let the prompt appear
    if (stdinInput !== null) {
      setTimeout(() => {
        ps.stdin.write(stdinInput + '\r\n');
        ps.stdin.end();
      }, 2000);
    }

    ps.on('error', reject);
    ps.on('exit', (code) => {
      resolve({
        output: out + errOut,
        exitCode: code
      });
    });
  });
}

test.describe('Non-Interactive Mode', () => {
  let repoRoot;
  let installPs1;

  test.beforeAll(() => {
    repoRoot = path.resolve(__dirname, '../..');
    installPs1 = path.join(repoRoot, 'installers', 'install.ps1');
  });

  test('-Auto installs all detected agents', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-test-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);
    mkdirp(path.join(projectRoot, '.git'));
    mkdirp(path.join(fakeHome, '.copilot'));
    mkdirp(path.join(fakeHome, '.claude'));

    const env = {
      USERPROFILE: fakeHome,
      TEMP: tmp,
    };

    try {
      const ps = spawn(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', installPs1,
         '-Auto', '-UseLocalSource', '-NoUI'],
        {
          cwd: projectRoot,
          env: { ...process.env, ...env },
          windowsHide: true,
        }
      );

      let output = '';
      ps.stdout.on('data', (b) => (output += b.toString('utf8')));
      ps.stderr.on('data', (b) => (output += b.toString('utf8')));

      const exitCode = await new Promise((resolve) => {
        ps.on('exit', resolve);
      });

      expect(exitCode).toBe(0);
      expect(output).toMatch(/Done:\s+\d+\/\d+\s+agents?\s+installed/i);

      // Verify installations happened
      const copilotSkillPath = path.join(fakeHome, '.copilot', 'skills', 'contracts');
      const claudeSkillPath = path.join(fakeHome, '.claude', 'skills', 'contracts');

      expect(fs.existsSync(copilotSkillPath)).toBe(true);
      expect(fs.existsSync(claudeSkillPath)).toBe(true);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  test('-Agents installs specified agents only', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-test-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);
    mkdirp(path.join(projectRoot, '.git'));
    mkdirp(path.join(fakeHome, '.copilot'));
    mkdirp(path.join(fakeHome, '.claude'));
    mkdirp(path.join(fakeHome, '.cursor'));

    const env = {
      USERPROFILE: fakeHome,
      TEMP: tmp,
    };

    try {
      const ps = spawn(
        'powershell',
        ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', installPs1,
         '-Agents', 'copilot,claude', '-UseLocalSource', '-NoUI'],
        {
          cwd: projectRoot,
          env: { ...process.env, ...env },
          windowsHide: true,
        }
      );

      let output = '';
      ps.stdout.on('data', (b) => (output += b.toString('utf8')));
      ps.stderr.on('data', (b) => (output += b.toString('utf8')));

      const exitCode = await new Promise((resolve) => {
        ps.on('exit', resolve);
      });

      expect(exitCode).toBe(0);

      // Verify only specified agents got installed
      const copilotSkillPath = path.join(fakeHome, '.copilot', 'skills', 'contracts');
      const claudeSkillPath = path.join(fakeHome, '.claude', 'skills', 'contracts');
      const cursorSkillPath = path.join(fakeHome, '.cursor', 'skills', 'contracts');

      expect(fs.existsSync(copilotSkillPath)).toBe(true);
      expect(fs.existsSync(claudeSkillPath)).toBe(true);
      expect(fs.existsSync(cursorSkillPath)).toBe(false); // Not installed
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });
});