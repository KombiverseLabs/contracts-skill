<?php
declare(strict_types=1);

session_start();

function h(string $v): string { return htmlspecialchars($v, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }

function root_dir(): string {
    $def = realpath(__DIR__ . DIRECTORY_SEPARATOR . '..') ?: __DIR__;
    $cfg = __DIR__ . DIRECTORY_SEPARATOR . 'config.local.php';
    if (is_file($cfg)) {
        $v = require $cfg;
        if (is_array($v) && isset($v['root']) && is_string($v['root'])) {
            $r = realpath($v['root']);
            if ($r !== false) return $r;
        }
    }
    $env = getenv('CONTRACTS_UI_ROOT');
    if (is_string($env) && $env !== '') {
        $r = realpath($env);
        if ($r !== false) return $r;
    }
    return $def;
}

function rel(string $p): string {
    $p = str_replace('\\', '/', $p);
    $p = preg_replace('~/+~', '/', $p) ?? $p;
    return ltrim($p, '/');
}

function must_csrf(): void {
    $tok = $_POST['csrf'] ?? '';
    if (!is_string($tok) || !isset($_SESSION['csrf']) || !hash_equals((string)$_SESSION['csrf'], $tok)) {
        throw new RuntimeException('Invalid CSRF token.');
    }
}

function ensure_csrf(): string {
    if (!isset($_SESSION['csrf']) || !is_string($_SESSION['csrf']) || $_SESSION['csrf'] === '') {
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    }
    return (string)$_SESSION['csrf'];
}

function flash(?array $set = null): ?array {
    if ($set !== null) { $_SESSION['flash'] = $set; return null; }
    $v = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return is_array($v) ? $v : null;
}

function resolve_contract_file(string $root, string $fileRel): string {
    $fileRel = rel($fileRel);
    $base = basename($fileRel);
    if ($fileRel === '' || ($base !== 'CONTRACT.md' && $base !== 'CONTRACT.yaml')) throw new RuntimeException('Invalid file.');
    $abs = realpath($root . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $fileRel));
    if ($abs === false || !is_file($abs)) throw new RuntimeException('File not found.');
    $rootReal = realpath($root);
    if ($rootReal === false) throw new RuntimeException('Invalid root.');
    $rootPrefix = rtrim(str_replace('\\', '/', $rootReal), '/') . '/';
    $absNorm = str_replace('\\', '/', $abs);
    if (stripos($absNorm, $rootPrefix) !== 0) throw new RuntimeException('Path traversal detected.');
    return $abs;
}

function resolve_contract_target(string $root, string $dirRel, string $fileName): string {
    $dirRel = rel($dirRel);
    if ($dirRel === '') $dirRel = '.';
    if (preg_match('~(?:^|/)\.\.(?:/|$)~', $dirRel)) throw new RuntimeException('Invalid dir.');
    if ($fileName !== 'CONTRACT.md' && $fileName !== 'CONTRACT.yaml') throw new RuntimeException('Invalid file.');

    $rootReal = realpath($root);
    if ($rootReal === false) throw new RuntimeException('Invalid root.');
    $dirAbs = $dirRel === '.' ? $rootReal : realpath($rootReal . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $dirRel));
    if ($dirAbs === false || !is_dir($dirAbs)) throw new RuntimeException('Directory not found.');

    $rootPrefix = rtrim(str_replace('\\', '/', $rootReal), '/') . '/';
    $dirNorm = rtrim(str_replace('\\', '/', $dirAbs), '/') . '/';
    if (stripos($dirNorm, $rootPrefix) !== 0) throw new RuntimeException('Path traversal detected.');

    return rtrim($dirAbs, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $fileName;
}

function yaml_source_hash(string $yaml): ?string {
    return preg_match('/^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$/mi', $yaml, $m)
        ? trim($m[2])
        : null;
}

function yaml_set_meta(string $yaml, string $key, string $value): string {
    $lines = preg_split('/\r\n|\r|\n/', $yaml) ?: [$yaml];
    $meta = null;
    for ($i=0; $i<count($lines); $i++) { if (trim($lines[$i]) === 'meta:') { $meta = $i; break; } }
    $val = '"' . str_replace('"', '\\"', $value) . '"';
    $newline = "  {$key}: {$val}";
    if ($meta === null) return "meta:\n{$newline}\n\n" . implode("\n", $lines) . "\n";
    for ($i=$meta+1; $i<count($lines); $i++) {
        if ($lines[$i] !== '' && preg_match('/^\S/', $lines[$i])) break;
        if (preg_match('/^\s*' . preg_quote($key, '/') . '\s*:/', $lines[$i])) { $lines[$i] = $newline; return implode("\n", $lines) . "\n"; }
    }
    array_splice($lines, $meta+1, 0, [$newline]);
    return implode("\n", $lines) . "\n";
}

function scan(string $root): array {
    $root = realpath($root) ?: $root;
    $ignore = ['.git','node_modules','vendor','.idea','.vscode','.agent','dist','build','out','.next','coverage','contracts-ui'];
    $rows = [];
    $it = new RecursiveIteratorIterator(
        new RecursiveCallbackFilterIterator(
            new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS),
            function (SplFileInfo $cur, $k, RecursiveCallbackFilterIterator $it) use ($ignore) {
                if ($cur->isDir()) return !in_array($cur->getFilename(), $ignore, true);
                $n = $cur->getFilename();
                return $n === 'CONTRACT.md' || $n === 'CONTRACT.yaml';
            }
        ),
        RecursiveIteratorIterator::LEAVES_ONLY
    );
    $rootNorm = rtrim(str_replace('\\', '/', $root), '/');
    foreach ($it as $fi) {
        /** @var SplFileInfo $fi */
        $abs = $fi->getRealPath();
        if ($abs === false) continue;
        $dirAbs = str_replace('\\', '/', dirname($abs));
        $dirRel = rel(substr($dirAbs, strlen($rootNorm) + 1));
        if ($dirRel === '') $dirRel = '.';
        if (!isset($rows[$dirRel])) $rows[$dirRel] = ['dir'=>$dirRel,'md'=>null,'yaml'=>null,'mdHash'=>null,'yamlHash'=>null,'match'=>null];
        $name = $fi->getFilename();
        $fileRel = ($dirRel === '.' ? '' : $dirRel . '/') . $name;
        if ($name === 'CONTRACT.md') {
            $rows[$dirRel]['md'] = $fileRel;
            $rows[$dirRel]['mdHash'] = hash_file('sha256', $abs) ?: null;
        } else {
            $rows[$dirRel]['yaml'] = $fileRel;
            $txt = @file_get_contents($abs);
            if (is_string($txt)) $rows[$dirRel]['yamlHash'] = yaml_source_hash($txt);
        }
    }
    foreach ($rows as &$r) {
        if (is_string($r['mdHash']) && is_string($r['yamlHash'])) {
            $r['match'] = strcasecmp(trim($r['yamlHash']), 'sha256:' . $r['mdHash']) === 0;
        }
    }
    unset($r);
    ksort($rows);
    return array_values($rows);
}

function page(string $title, string $body, ?array $flash, string $root): void {
    $f = '';
    if ($flash) {
        $cls = in_array(($flash['type'] ?? ''), ['ok','warn','err'], true) ? $flash['type'] : 'ok';
        $f = '<div class="flash ' . h($cls) . '">' . h((string)($flash['msg'] ?? '')) . '</div>';
    }
    echo "<!doctype html><html lang=de><head><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'>";
    echo '<title>' . h($title) . '</title>';
    echo "<style>
body{font-family:system-ui,Segoe UI,Roboto,Arial;margin:18px;background:#0b1020;color:#e7ecff}
a{color:#87a7ff;text-decoration:none} a:hover{text-decoration:underline}
.card{background:#111936;border:1px solid #24305a;border-radius:12px;padding:14px}
.top{display:flex;justify-content:space-between;gap:12px;flex-wrap:wrap;align-items:flex-end;margin-bottom:10px}
.muted{color:#9aa4bf;font-size:12px}
table{width:100%;border-collapse:collapse} th,td{padding:8px;border-bottom:1px solid rgba(36,48,90,.6);vertical-align:top}
th{color:#9aa4bf;font-size:12px;text-transform:uppercase;letter-spacing:.06em;text-align:left}
.badge{padding:2px 8px;border-radius:999px;border:1px solid #24305a;font-size:12px}
.ok{color:#26d07c;border-color:rgba(38,208,124,.35)} .bad{color:#ff5d5d;border-color:rgba(255,93,93,.35)} .warn{color:#ffd166;border-color:rgba(255,209,102,.35)}
input[type=text]{background:#0a0f22;border:1px solid #24305a;color:#e7ecff;border-radius:10px;padding:7px 10px;min-width:240px}
label{font-size:12px;color:#9aa4bf}
button,.btn{background:#0a1436;border:1px solid #24305a;color:#e7ecff;border-radius:10px;padding:7px 10px;cursor:pointer}
button:hover,.btn:hover{background:#0c1a44}
.flash{margin:0 0 10px 0;padding:9px 10px;border-radius:10px;border:1px solid #24305a;background:rgba(8,12,26,.65)}
textarea{width:100%;min-height:65vh;background:#0a0f22;border:1px solid #24305a;color:#e7ecff;border-radius:12px;padding:12px;font-family:ui-monospace,Consolas,monospace;font-size:13px;line-height:1.45}
code{background:rgba(255,255,255,.06);padding:2px 6px;border-radius:8px}
</style></head><body>";
    echo '<div class=top><div><div style="font-weight:700">Contracts UI</div><div class=muted>Lokales Dev-Tool — nicht öffentlich hosten</div></div>';
    echo '<div class=muted>Root: <code>' . h($root) . '</code></div></div>';
    echo $f . '<div class=card>' . $body . '</div></body></html>';
}

$root = root_dir();
$csrf = ensure_csrf();
$flash = flash();
$action = is_string($_GET['action'] ?? null) ? (string)$_GET['action'] : 'list';

try {
    if ($action === 'edit') {
        $file = is_string($_GET['file'] ?? null) ? (string)$_GET['file'] : '';
        $fileRel = rel($file);
        $abs = resolve_contract_file($root, $fileRel);
        $txt = file_get_contents($abs);
        if ($txt === false) throw new RuntimeException('Could not read file.');
        $body = '<div class=top><div><div class=muted>Bearbeite</div><div><code>' . h($fileRel) . '</code></div></div><a class=btn href="?">Zurück</a></div>';
        $body .= '<form method=post action="?action=save">'
            . '<input type=hidden name=csrf value="' . h($csrf) . '">' 
            . '<input type=hidden name=file value="' . h($fileRel) . '">' 
            . '<textarea name=content spellcheck=false>' . h($txt) . '</textarea>'
            . '<div class=top style="margin-top:10px"><div class=muted>Speichern schreibt direkt in die Datei.</div><button type=submit>Speichern</button></div>'
            . '</form>';
        page('Edit ' . $fileRel, $body, $flash, $root);
        exit;
    }

    if ($action === 'save' && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
        must_csrf();
        $file = $_POST['file'] ?? ''; $content = $_POST['content'] ?? '';
        if (!is_string($file) || !is_string($content)) throw new RuntimeException('Invalid payload.');
        $fileRel = rel($file);
        $abs = resolve_contract_file($root, $fileRel);
        $n = file_put_contents($abs, $content, LOCK_EX);
        if ($n === false) throw new RuntimeException('Write failed.');
        flash(['type'=>'ok','msg'=>"Saved {$fileRel} ({$n} bytes)"]); header('Location: ?'); exit;
    }

    if ($action === 'sync_yaml' && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
        must_csrf();
        $dir = is_string($_POST['dir'] ?? null) ? (string)$_POST['dir'] : '';
        $dir = rel($dir); if ($dir === '') $dir = '.';
        $mdRel = ($dir === '.' ? 'CONTRACT.md' : $dir . '/CONTRACT.md');
        $yRel  = ($dir === '.' ? 'CONTRACT.yaml' : $dir . '/CONTRACT.yaml');
        $mdAbs = resolve_contract_file($root, $mdRel);
        $yAbs  = resolve_contract_file($root, $yRel);
        $hash = hash_file('sha256', $mdAbs); if (!is_string($hash) || $hash === '') throw new RuntimeException('Hash failed.');
        $yaml = file_get_contents($yAbs); if ($yaml === false) throw new RuntimeException('Read YAML failed.');
        $yaml = yaml_set_meta($yaml, 'source_hash', 'sha256:' . $hash);
        $yaml = yaml_set_meta($yaml, 'last_sync', gmdate('c'));
        if (file_put_contents($yAbs, $yaml, LOCK_EX) === false) throw new RuntimeException('Write YAML failed.');
        flash(['type'=>'ok','msg'=>"Synced meta for {$yRel}"]); header('Location: ?'); exit;
    }

    if ($action === 'create_md' && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
        must_csrf();
        $dir = is_string($_POST['dir'] ?? null) ? (string)$_POST['dir'] : '';
        $dir = rel($dir); if ($dir === '') $dir = '.';
        $abs = resolve_contract_target($root, $dir, 'CONTRACT.md');
        if (file_exists($abs)) throw new RuntimeException('CONTRACT.md already exists.');
        $tpl = "# Contract\n\n## Overview\n\nDescribe the purpose, scope, and constraints of this module/feature.\n\n## Interfaces\n\n- Inputs:\n- Outputs:\n- Errors:\n\n## Notes\n\n- TODO\n";
        $n = file_put_contents($abs, $tpl, LOCK_EX);
        if ($n === false) throw new RuntimeException('Create failed.');
        flash(['type'=>'ok','msg'=>"Created {$dir}/CONTRACT.md"]); header('Location: ?'); exit;
    }

    if ($action === 'create_yaml' && ($_SERVER['REQUEST_METHOD'] ?? '') === 'POST') {
        must_csrf();
        $dir = is_string($_POST['dir'] ?? null) ? (string)$_POST['dir'] : '';
        $dir = rel($dir); if ($dir === '') $dir = '.';
        $yAbs = resolve_contract_target($root, $dir, 'CONTRACT.yaml');
        if (file_exists($yAbs)) throw new RuntimeException('CONTRACT.yaml already exists.');

        $mdRel = ($dir === '.' ? 'CONTRACT.md' : $dir . '/CONTRACT.md');
        $mdHash = null;
        try {
            $mdAbs = resolve_contract_file($root, $mdRel);
            $mdHash = hash_file('sha256', $mdAbs);
        } catch (Throwable $e) {
            $mdHash = null;
        }
        $sourceHash = is_string($mdHash) && $mdHash !== '' ? 'sha256:' . $mdHash : '';

        $yaml = "meta:\n";
        $yaml .= "  source_hash: \"" . str_replace("\"", "\\\"", $sourceHash) . "\"\n";
        $yaml .= "  last_sync: \"" . gmdate('c') . "\"\n";
        $yaml .= "\n";
        $yaml .= "# Add your YAML contract schema below\n";

        $n = file_put_contents($yAbs, $yaml, LOCK_EX);
        if ($n === false) throw new RuntimeException('Create failed.');
        flash(['type'=>'ok','msg'=>"Created {$dir}/CONTRACT.yaml"]); header('Location: ?'); exit;
    }

    $q = is_string($_GET['q'] ?? null) ? trim((string)$_GET['q']) : '';
    $driftOnly = (string)($_GET['drift'] ?? '') === '1';
    $rows = scan($root);

    $filtered = [];
    foreach ($rows as $r) {
        $path = (string)$r['dir'];
        if ($q !== '' && stripos($path, $q) === false) continue;
        if ($driftOnly) {
            $partial = ($r['md'] && !$r['yaml']) || (!$r['md'] && $r['yaml']);
            $mismatch = ($r['md'] && $r['yaml'] && $r['match'] === false);
            if (!$partial && !$mismatch) continue;
        }
        $filtered[] = $r;
    }

    $body = '<form method=get class=top>'
        . '<div><div class=muted>Filter Pfad</div><input type=text name=q value="' . h($q) . '" placeholder="z.B. src/core"></div>'
        . '<div style="align-self:flex-end"><label><input type=checkbox name=drift value=1 ' . ($driftOnly ? 'checked' : '') . '> nur Drift</label></div>'
        . '<div style="align-self:flex-end"><button type=submit>Apply</button> <a class=btn href="?">Reset</a></div>'
        . '</form>';

    $body .= '<div class=muted style="margin:10px 0">Gefundene Contract-Ordner: <b>' . count($filtered) . '</b> (gesamt: ' . count($rows) . ')</div>';

    if (count($filtered) === 0) {
        $body .= '<div class=muted>Keine Treffer.</div>';
        page('Contracts UI', $body, $flash, $root);
        exit;
    }

    $body .= '<div style="overflow:auto"><table><thead><tr><th>Pfad</th><th>MD</th><th>YAML</th><th>Status</th><th>Actions</th></tr></thead><tbody>';
    foreach ($filtered as $r) {
        $dir = (string)$r['dir'];
        $md = $r['md']; $y = $r['yaml'];
        $status = '<span class="badge warn">partial</span>';
        if ($md && $y) {
            if ($r['match'] === true) $status = '<span class="badge ok">ok</span>';
            elseif ($r['match'] === false) $status = '<span class="badge bad">drift</span>';
            else $status = '<span class="badge warn">unknown</span>';
        }

        $a = '';
        $a .= $md
            ? '<a href="?action=edit&file=' . rawurlencode((string)$md) . '">Edit MD</a>'
            : '<form style="display:inline" method=post action="?action=create_md">'
                . '<input type=hidden name=csrf value="' . h($csrf) . '">' 
                . '<input type=hidden name=dir value="' . h($dir) . '">'
                . '<button type=submit>Create MD</button></form>';
        $a .= ' &nbsp; ';
        $a .= $y
            ? '<a href="?action=edit&file=' . rawurlencode((string)$y) . '">Edit YAML</a>'
            : '<form style="display:inline" method=post action="?action=create_yaml">'
                . '<input type=hidden name=csrf value="' . h($csrf) . '">'
                . '<input type=hidden name=dir value="' . h($dir) . '">'
                . '<button type=submit>Create YAML</button></form>';

        $sync = '';
        if ($md && $y) {
            $sync = '<form style="display:inline" method=post action="?action=sync_yaml">'
                . '<input type=hidden name=csrf value="' . h($csrf) . '">'
                . '<input type=hidden name=dir value="' . h($dir) . '">'
                . '<button type=submit>Sync YAML meta</button></form>';
        }

        $body .= '<tr>'
            . '<td><code>' . h($dir) . '</code></td>'
            . '<td>' . ($md ? 'yes' : '<span class=muted>no</span>') . '</td>'
            . '<td>' . ($y ? 'yes' : '<span class=muted>no</span>') . '</td>'
            . '<td>' . $status . '</td>'
            . '<td>' . $a . ($sync ? '<br>' . $sync : '') . '</td>'
            . '</tr>';
    }
    $body .= '</tbody></table></div>';
    page('Contracts UI', $body, $flash, $root);
} catch (Throwable $e) {
    page('Error', '<div class="flash err">' . h($e->getMessage()) . '</div><p><a class=btn href="?">Zurück</a></p>', null, $root ?? root_dir());
}
