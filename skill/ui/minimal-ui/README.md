# Contracts UI (minimal)

Minimal UI that can run:

- as a **snapshot** (file-only) via `index.html` + `contracts-bundle.js`
- as a **live localhost app** (recommended) via `server.js` for true read/write

## Start (recommended: live localhost)

When installed into a project at `./contracts-ui/`, use the bundled start scripts:

PowerShell:

```powershell
./contracts-ui/start.ps1
```

Bash:

```bash
./contracts-ui/start.sh
```

This starts a local server and opens `http://127.0.0.1:<port>/`.

Note (Windows/PowerShell): If the desired port is occupied, `start.ps1` automatically selects the next free port and displays a warning. For strict fail-fast behavior, use `-StrictPort`.

In background mode, `start.ps1` performs a health check on `/api/contracts`. If the server fails to start, the script exits with code 1 and writes logs to `contracts-ui/.logs/`.

Example:

```powershell
./contracts-ui/start.ps1 -Port 8787 -StrictPort
```

In live mode you can:

- list all contracts from the project root
- open/edit contracts and **apply changes** back to disk
- run drift sync (updates YAML meta)

## Start (snapshot only)

After installation to `./contracts-ui/`:

- Open `contracts-ui/index.html` in the browser.

Empfehlung: Chrome/Edge (bestes Feature-Set).

## Modus

- **Read-only (file picker):** works everywhere; changes are downloaded.
- **Read/Write (directory picker):** works in supporting browsers (usually Chrome/Edge) and typically requires `http://localhost`.

If you want full read/write + live scanning, prefer `./contracts-ui/start.ps1` / `./contracts-ui/start.sh`.
