# Contracts UI (php-ui)

Mini Web-UI (PHP) um `CONTRACT.md` / `CONTRACT.yaml` im Projekt zu finden und zu bearbeiten.

## Start

Im Projekt-Root:

```bash
php -S localhost:8080 -t contracts-ui
```

Dann öffnen: http://localhost:8080

## Features

- Übersicht aller `CONTRACT.md` / `CONTRACT.yaml`
- Filter nach Pfad (Suchfeld)
- Toggle: "nur Drift" (zeigt Drift/Partial)
- Direkt editieren + speichern
- Fehlende Dateien anlegen (Create MD / Create YAML)
- Button: "Sync YAML meta" (setzt `meta.source_hash` + `meta.last_sync`)

## Hinweis

- Dieses Tool ist für lokale Entwicklung gedacht.
- Nicht öffentlich ins Internet hängen (kann Dateien schreiben).

## Root anpassen (optional)

Standardmäßig nimmt die UI als Projekt-Root den Parent-Ordner von `contracts-ui/`.

Alternative:
- `CONTRACTS_UI_ROOT` Environment-Variable setzen, oder
- `contracts-ui/config.local.php` erstellen:

```php
<?php
return ['root' => __DIR__ . '/..'];
```
