#!/bin/sh
set -e

# Regenerates contracts-bundle.js for the minimal UI.
# Best-effort: requires python3 or python.

UI_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Default: assume installed at <project>/contracts-ui; project root is the parent folder.
PROJECT_ROOT=$(CDPATH= cd -- "$UI_DIR/.." && pwd)

# If inside a git repo, prefer the nearest git root.
probe="$UI_DIR"
i=0
while [ $i -lt 15 ]; do
  if [ -d "$probe/.git" ]; then
    PROJECT_ROOT="$probe"
    break
  fi
  parent=$(dirname "$probe")
  [ "$parent" = "$probe" ] && break
  probe="$parent"
  i=$((i+1))
done

export CONTRACTS_PROJECT_ROOT="$PROJECT_ROOT"

PY=
command -v python3 >/dev/null 2>&1 && PY=python3
[ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY=python

if [ -z "$PY" ]; then
  echo "python3/python not found; cannot generate contracts-bundle.js automatically." >&2
  echo "Install python or use the php-ui variant for automatic project scanning." >&2
  exit 1
fi

"$PY" - <<'PY'
import hashlib, json, os, re, sys
ui_dir = os.path.abspath(os.path.dirname(__file__))
project_root = os.path.abspath(os.environ.get('CONTRACTS_PROJECT_ROOT') or os.path.join(ui_dir, '..'))
ignore = {'.git','node_modules','vendor','.idea','.vscode','.agent','dist','build','out','.next','coverage','contracts-ui'}

rx = re.compile(r'^\s*source_hash\s*:\s*("?)([^"\r\n#]+)\1\s*(?:#.*)?$', re.I|re.M)

def rel(p):
  return os.path.relpath(p, project_root).replace('\\','/')

def sha256_text(s: str) -> str:
  return hashlib.sha256(s.encode('utf-8')).hexdigest()

contracts = {}
for root, dirs, files in os.walk(project_root):
  dirs[:] = [d for d in dirs if d not in ignore]
  if 'CONTRACT.md' in files or 'CONTRACT.yaml' in files:
    drel = rel(root)
    if drel == '.': drel = '.'
    obj = contracts.get(drel, {'dir': drel})
    if 'CONTRACT.md' in files:
      p = os.path.join(root,'CONTRACT.md')
      txt = open(p,'r',encoding='utf-8',errors='replace').read()
      obj['md_path']=rel(p); obj['md_text']=txt; obj['md_hash']=sha256_text(txt)
    if 'CONTRACT.yaml' in files:
      p = os.path.join(root,'CONTRACT.yaml')
      txt = open(p,'r',encoding='utf-8',errors='replace').read()
      obj['yaml_path']=rel(p); obj['yaml_text']=txt
      m = rx.search(txt)
      obj['yaml_source_hash']=m.group(2).strip() if m else None
    contracts[drel]=obj

bundle = {
  'generated_at': __import__('datetime').datetime.utcnow().replace(microsecond=0).isoformat()+'Z',
  'project_root': '.',
  'contracts': [contracts[k] for k in sorted(contracts.keys())]
}

js = 'window.__CONTRACTS_BUNDLE__ = ' + json.dumps(bundle, ensure_ascii=False) + ';\n'
out_path = os.path.join(ui_dir,'contracts-bundle.js')
open(out_path,'w',encoding='utf-8').write(js)
print('Wrote:', out_path)
PY
