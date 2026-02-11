# Contracts UI (php-ui)

Mini Web-UI (PHP) to find and edit `CONTRACT.md` / `CONTRACT.yaml` files in the project.

## Start

In the project root:

```bash
php -S localhost:8080 -t contracts-ui
```

Then open: http://localhost:8080

## Features

- Overview of all `CONTRACT.md` / `CONTRACT.yaml` files
- Filter by path (search field)
- Toggle: "drift only" (shows Drift/Partial)
- Direct editing + save
- Create missing files (Create MD / Create YAML)
- Button: "Sync YAML meta" (sets `meta.source_hash` + `meta.last_sync`)

## Note

- This tool is intended for local development.
- Do not expose publicly (can write files).

## Adjust Root (optional)

By default, the UI uses the parent directory of `contracts-ui/` as the project root.

Alternative:
- Set `CONTRACTS_UI_ROOT` environment variable, or
- Create `contracts-ui/config.local.php`:

```php
<?php
return ['root' => __DIR__ . '/..'];
```
