/**
 * @fileoverview Integration tests for interactive installer features.
 * 
 * These tests validate the interactive checkbox UI in the installer,
 * including keyboard navigation and selection confirmation.
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
 * Run PowerShell script with simulated keyboard input.
 * @param {Object} options
 * @param {string} options.filePath - Path to PowerShell script
 * @param {string[]} options.args - Script arguments
 * @param {string} options.cwd - Working directory
 * @param {Object} options.env - Environment variables
 * @param {string[]} options.keySequence - Array of key sequences to send
 * @returns {Promise<{output: string, exitCode: number}>}
 */
function runPowershellWithKeys({ filePath, args = [], cwd, env = {}, keySequence = [] }) {
  return new Promise((resolve, reject) => {
    const ps = spawn(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', filePath, ...args],
      {
        cwd,
        env: { ...process.env, ...env },
        windowsHide: false,
        stdio: ['pipe', 'pipe', 'pipe']
      }
    );

    let out = '';
    let errOut = '';
    
    ps.stdout.on('data', (b) => {
      const data = b.toString('utf8');
      out += data;
      
      // Detect prompts and send keys
      if (data.includes('Space=toggle, Enter=confirm')) {
        // Wait a bit for UI to stabilize
        setTimeout(() => {
          keySequence.forEach((key, index) => {
            setTimeout(() => {
              ps.stdin.write(key + '\r\n');
            }, index * 100);
          });
        }, 500);
      }
    });
    
    ps.stderr.on('data', (b) => {
      errOut += b.toString('utf8');
    });

    ps.on('error', reject);
    ps.on('exit', (code) => {
      resolve({ 
        output: out + errOut, 
        exitCode: code 
      });
    });
  });
}

test.describe('Interactive Installer', () => {
  let repoRoot;
  let installPs1;

  test.beforeAll(() => {
    repoRoot = path.resolve(__dirname, '../..');
    installPs1 = path.join(repoRoot, 'installers', 'install.ps1');
  });

  test('Enter key confirms selection and exits checkbox UI', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-test-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);
    mkdirp(path.join(projectRoot, '.git'));

    // Create detectable agent directories
    mkdirp(path.join(fakeHome, '.copilot'));
    mkdirp(path.join(fakeHome, '.claude'));

    const env = {
      USERPROFILE: fakeHome,
      TEMP: tmp,
    };

    try {
      const result = await runPowershellWithKeys({
        filePath: installPs1,
        cwd: projectRoot,
        env,
        args: [
          '-UseLocalSource',
          '-SkipUI',
          '-UpdateInstructions'
        ],
        keySequence: ['\r'] // Send Enter key
      });

      // The installer should complete successfully
      // If Enter doesn't work, it would timeout or hang
      expect(result.exitCode).toBe(0);
      expect(result.output).toContain('Installation complete');
    } finally {
      // Cleanup
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  test('Space key toggles selection', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-test-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);
    mkdirp(path.join(projectRoot, '.git'));

    // Create only one detectable agent
    mkdirp(path.join(fakeHome, '.copilot'));

    const env = {
      USERPROFILE: fakeHome,
      TEMP: tmp,
    };

    try {
      const result = await runPowershellWithKeys({
        filePath: installPs1,
        cwd: projectRoot,
        env,
        args: [
          '-UseLocalSource',
          '-SkipUI',
          '-UpdateInstructions'
        ],
        keySequence: [' ', '\r'] // Space to toggle, Enter to confirm
      });

      expect(result.exitCode).toBe(0);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  test('Q key quits without installation', async () => {
    const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'contracts-installer-test-'));
    const fakeHome = path.join(tmp, 'home');
    const projectRoot = path.join(tmp, 'project');

    mkdirp(fakeHome);
    mkdirp(projectRoot);
    mkdirp(path.join(projectRoot, '.git'));
    mkdirp(path.join(fakeHome, '.copilot'));

    const env = {
      USERPROFILE: fakeHome,
      TEMP: tmp,
    };

    try {
      const result = await runPowershellWithKeys({
        filePath: installPs1,
        cwd: projectRoot,
        env,
        args: [
          '-UseLocalSource',
          '-SkipUI'
        ],
        keySequence: ['Q'] // Quit
      });

      // Should exit without error but skip installation
      expect(result.output).toContain('No agents selected');
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });
});

test.describe('Non-Interactive Mode', () => {
  let repoRoot;
  let installPs1;

  test.beforeAll(() => {
    repoRoot = path.resolve(__dirname, '../..');
    installPs1 = path.join(repoRoot, 'installers', 'install.ps1');
  });

  test('Auto flag installs to all detected agents without prompting', async () => {
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
         '-Auto', '-UseLocalSource', '-SkipUI', '-UpdateInstructions'],
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
      expect(output).not.toContain('Space=toggle'); // No interactive prompt
      expect(output).toContain('Installation complete');

      // Verify installations happened
      const copilotSkillPath = path.join(fakeHome, '.copilot', 'skills', 'contracts');
      const claudeSkillPath = path.join(fakeHome, '.claude', 'skills', 'contracts');
      
      expect(fs.existsSync(copilotSkillPath)).toBe(true);
      expect(fs.existsSync(claudeSkillPath)).toBe(true);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  test('Agents parameter installs to specific agents', async () => {
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
         '-Agents', 'copilot,claude', '-UseLocalSource', '-SkipUI', '-UpdateInstructions'],
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
      expect(output).not.toContain('Space=toggle'); // No interactive prompt

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
