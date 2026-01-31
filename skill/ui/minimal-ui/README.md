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

Hinweis (Windows/PowerShell): Wenn der gewünschte Port belegt ist, wählt `start.ps1` automatisch den nächsten freien Port und gibt eine Warnung aus. Für ein hartes Fail-Fast-Verhalten nutze `-StrictPort`.

`start.ps1` macht im Background-Modus außerdem standardmäßig einen kurzen Health-Check auf `/api/contracts`. Falls der Server nicht hochkommt, endet das Script mit Exit-Code 1 und schreibt Logs nach `contracts-ui/.logs/`.

Beispiel:

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
