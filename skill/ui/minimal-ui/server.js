#!/usr/bin/env node
/* eslint-disable no-console */

const http = require('http');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function parseArgs(argv) {
  const args = { port: 8787, projectRoot: process.cwd() };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--port' || a === '-p') {
      args.port = Number(argv[++i] || args.port);
    } else if (a === '--project-root' || a === '--root') {
      args.projectRoot = path.resolve(argv[++i] || args.projectRoot);
    }
  }
  return args;
}

function send(res, status, body, headers = {}) {
  res.writeHead(status, {
    'content-type': 'text/plain; charset=utf-8',
    'cache-control': 'no-store',
    ...headers,
  });
  res.end(body);
}

function sendJson(res, status, obj, headers = {}) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    ...headers,
  });
  res.end(JSON.stringify(obj));
}

function toPosix(p) {
  return p.replace(/\\/g, '/');
}

function rel(base, full) {
  const r = path.relative(base, full);
  return toPosix(r);
}

function yamlSourceHash(yamlText) {
  const m = String(yamlText).match(/^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$/im);
  return m ? m[2].trim() : null;
}

function sha256Text(text) {
  return crypto.createHash('sha256').update(String(text), 'utf8').digest('hex');
}

function extractSummary(mdText) {
  const t = String(mdText || '').replace(/\r\n/g, '\n');
  const lines = t.split('\n');

  let title = null;
  for (const line of lines) {
    const s = line.trim();
    if (!s) continue;
    if (s.startsWith('# ')) {
      title = s.slice(2).trim();
      break;
    }
  }

  const paras = t
    .split(/\n\s*\n/g)
    .map((p) => p.trim())
    .filter(Boolean)
    .map((p) => p.replace(/\s+/g, ' '));

  const summary = paras.find((p) => !p.startsWith('#')) || null;
  return {
    title,
    summary,
  };
}

function safeResolveWithin(root, relPath) {
  const rel = String(relPath || '').replace(/\\/g, '/').replace(/^\//, '');
  if (!rel || rel.includes('\0')) return null;
  if (path.isAbsolute(rel)) return null;
  const resolved = path.resolve(root, rel);
  const rootResolved = path.resolve(root) + path.sep;
  if (!resolved.startsWith(rootResolved)) return null;
  return resolved;
}

async function readJsonBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw.trim()) return null;
  return JSON.parse(raw);
}

function scanContracts(projectRoot) {
  const ignore = new Set([
    '.git',
    'node_modules',
    'vendor',
    '.idea',
    '.vscode',
    '.agent',
    'dist',
    'build',
    'out',
    '.next',
    'coverage',
    'contracts-ui',
  ]);

  const map = new Map();

  /** @param {string} dir */
  function walk(dir) {
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }

    for (const ent of entries) {
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        if (ignore.has(ent.name)) continue;
        walk(full);
        continue;
      }

      if (!ent.isFile()) continue;
      if (ent.name !== 'CONTRACT.md' && ent.name !== 'CONTRACT.yaml') continue;

      const relDirRaw = rel(projectRoot, path.dirname(full));
      const relDir = relDirRaw === '' ? '.' : relDirRaw;
      const obj = map.get(relDir) || { dir: relDir };

      const txt = fs.readFileSync(full, 'utf8');
      if (ent.name === 'CONTRACT.md') {
        obj.md_path = rel(projectRoot, full);
        obj.md_text = txt;
        obj.md_hash = sha256Text(txt);

        const s = extractSummary(txt);
        if (s.title) obj.title = s.title;
        if (s.summary) obj.summary = s.summary;
      } else {
        obj.yaml_path = rel(projectRoot, full);
        obj.yaml_text = txt;
        obj.yaml_source_hash = yamlSourceHash(txt);
      }

      map.set(relDir, obj);
    }
  }

  walk(projectRoot);

  const contracts = Array.from(map.values()).sort((a, b) => String(a.dir).localeCompare(String(b.dir)));
  return {
    generated_at: new Date().toISOString(),
    project_root: '.',
    contracts,
  };
}

function serveStatic(uiDir, reqUrl, res) {
  const u = new URL(reqUrl, 'http://localhost');
  const pathname = decodeURIComponent(u.pathname);
  const file = pathname === '/' ? '/index.html' : pathname;

  const candidate = path.join(uiDir, file);
  const resolved = path.resolve(candidate);
  if (!resolved.startsWith(path.resolve(uiDir) + path.sep)) {
    send(res, 400, 'Bad path');
    return;
  }

  if (!fs.existsSync(resolved) || !fs.statSync(resolved).isFile()) {
    send(res, 404, 'Not found');
    return;
  }

  const ext = path.extname(resolved).toLowerCase();
  const ct =
    ext === '.html' ? 'text/html; charset=utf-8' :
    ext === '.js' ? 'text/javascript; charset=utf-8' :
    ext === '.css' ? 'text/css; charset=utf-8' :
    ext === '.json' ? 'application/json; charset=utf-8' :
    'application/octet-stream';

  res.writeHead(200, { 'content-type': ct, 'cache-control': 'no-store' });
  fs.createReadStream(resolved).pipe(res);
}

function main() {
  const { port, projectRoot } = parseArgs(process.argv);
  const uiDir = __dirname;

  const projectRootAbs = path.resolve(projectRoot);

  const server = http.createServer((req, res) => {
    try {
      const u = new URL(req.url || '/', 'http://localhost');
      if (req.method === 'OPTIONS') {
        res.writeHead(204, {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET,PUT,OPTIONS',
          'access-control-allow-headers': 'content-type',
          'cache-control': 'no-store',
        });
        res.end();
        return;
      }

      if (u.pathname === '/api/contracts') {
        if (req.method !== 'GET') {
          sendJson(res, 405, { error: 'Method not allowed' });
          return;
        }
        const payload = scanContracts(projectRoot);
        sendJson(res, 200, payload);
        return;
      }

      if (u.pathname === '/api/file') {
        if (req.method !== 'PUT') {
          sendJson(res, 405, { error: 'Method not allowed' });
          return;
        }

        readJsonBody(req).then((body) => {
          const relPath = body && body.path ? String(body.path) : '';
          const text = body && typeof body.text === 'string' ? body.text : null;

          if (!relPath || text === null) {
            sendJson(res, 400, { error: 'Invalid body. Expected { path, text }.' });
            return;
          }

          const base = path.basename(relPath.replace(/\\/g, '/'));
          if (base !== 'CONTRACT.md' && base !== 'CONTRACT.yaml') {
            sendJson(res, 400, { error: 'Only CONTRACT.md / CONTRACT.yaml can be written.' });
            return;
          }

          const abs = safeResolveWithin(projectRootAbs, relPath);
          if (!abs) {
            sendJson(res, 400, { error: 'Invalid path.' });
            return;
          }

          fs.writeFileSync(abs, text, 'utf8');
          const newHash = sha256Text(text);
          sendJson(res, 200, { ok: true, path: relPath.replace(/\\/g, '/'), sha256: newHash });
        }).catch((e) => {
          sendJson(res, 400, { error: String(e && e.message ? e.message : e) });
        });
        return;
      }

      serveStatic(uiDir, req.url || '/', res);
    } catch (e) {
      send(res, 500, String(e && e.stack ? e.stack : e));
    }
  });

  server.listen(port, '127.0.0.1', () => {
    const addr = server.address();
    const actualPort = addr && typeof addr === 'object' ? addr.port : port;
    console.log(`Contracts minimal-ui live server running:`);
    console.log(`  UI:  http://127.0.0.1:${actualPort}/`);
    console.log(`  API: http://127.0.0.1:${actualPort}/api/contracts`);
    console.log(`  Project root: ${projectRootAbs}`);
  });
}

main();
