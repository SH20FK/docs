# 01 · Mod structure, loading, sharing

[← Back to the guide](README.md)

## A mod is a folder

```
mods/
  my_mod/
    mod.json                 required — manifest
    thumbnail.png            256×256 picture for the launcher (optional)
    main.gd                  code entry, `extends PaxMod` (optional)
    data/
      bodies.patch.json      changes to the game's data/bodies.json
      crises.patch.json      … any data file
      prompt_talk.append.txt text appended to the game's prompt
      lang/en.json           translations (merged into the game dictionary)
      lang/ru.json
    planets/xeno_albedo.png  your assets: anywhere, any names
    shaders/aurora.gdshader
    models/station.glb
    music/надежда_mymod.ogg
    presets/My World/meta.json  a ready world preset
```

Everything inside the mod is reachable as **`res://mods/<id>/…`** — in JSON (`"map": "res://mods/my_mod/planets/xeno"`),
in code (`path("planets/xeno_albedo.png")` or `load("res://mods/my_mod/scene.tscn")`) and in `preload`.

## Where mods live

| Where | When |
|---|---|
| `<game folder>/mods/` | released game (next to `PaxUniverse.exe`) |
| `<project>/mods/` | running from the Godot editor (the folder has `.gdignore`, Godot does not import it) |
| `%APPDATA%/Godot/app_userdata/Terraform Prototype/mods/` (`user://mods/`) | per-user mods |

A mod is either a **folder** or a **.zip** (with `mod.json` in the root, or in a single top folder).
Folders starting with `_` or `.` are ignored (`_template` is the template for `new`).
Console command `folders` prints the exact paths.

## mod.json

```json
{
  "id": "my_star_cluster",
  "name": {"en": "Pleiades Cluster", "ru": "Скопление Плеяды"},
  "version": "1.2.0",
  "api": 1,
  "game_version": ">=0.9.0",
  "authors": ["Your Name"],
  "description": {"en": "Seven young stars 444 light years away.", "ru": "Семь молодых звёзд в 444 св. годах."},
  "tags": ["star system", "arks"],
  "depends": ["base_arks_overhaul>=2.0"],
  "load_after": ["some_optional_mod"],
  "load_before": [],
  "entry": "main.gd"
}
```

| Field | Meaning |
|---|---|
| `id` | **Required.** `a-z 0-9 _ - .`, 2–64 chars. Never change after release: saves and other mods refer to it. |
| `name`, `description` | A string or `{"en": …, "ru": …, "de": …}` — the launcher picks the player's language, then English. |
| `version` | Your version (`1`, `1.2`, `1.2.3`). |
| `api` | Pax API version the mod targets. Current: **1**. A newer value shows a warning. |
| `game_version` | Minimum game version, e.g. `">=0.9.0"`. |
| `depends` | Mods that must be enabled (`"id"` or `"id>=1.2"`). They load first. Enabling your mod in the launcher enables them. |
| `load_after` / `load_before` | Soft ordering against mods that may or may not be installed. |
| `entry` | GDScript file with `extends PaxMod`. Omit for data-only mods. |
| `client_only` | `true` — the mod only changes looks (textures, music, fonts) and does not affect gameplay. It is not compared in multiplayer: a player may use it even if the host doesn't have it. Every other mod must match the host's set and versions in multiplayer. |
| `tags` | Chips in the launcher; `planet`, `star`, `ark`, `character`, `shader`, `music`, `language`, `ui` pick the placeholder icon. |

Schema with autocompletion: [`../schemas/mod.schema.json`](../schemas/mod.schema.json)
(add `"$schema": "../../docs/modding/schemas/mod.schema.json"` or use the template's `.vscode/settings.json`).

## Load order

1. Dependencies and `load_after`/`load_before` — always respected.
2. Then the order the player set in the launcher (▲▼).
3. Then alphabetically by id.

**Later mods win**: their replacements replace earlier ones, their patches apply on top.
The launcher shows the position `#1, #2…`; the console command `mods` prints the order.

## Enabling, disabling, order

Launcher → **Mods**: checkboxes, ▲▼ order, *Enable all / Disable all*, *Mods folder*, *How to make mods*.
A checkbox takes effect **immediately, no restart**: the launcher re-reads mods, mounts new ones and unloads the
code of disabled ones (`_mod_unloaded()` is called). Before *Play* it re-reads the mods folder once more, so edits
made by hand while it was open are picked up too.
The choice is stored in `user://mods.json` (`disabled`, `order`).

## What players see

Each mod card shows the picture, name, version, authors, description, tags, a **⚙ runs code** chip for mods
with scripts (with a warning to install only trusted mods), dependencies, and every problem found while loading
(translated). Mods that could not be read at all are listed separately.

## Sharing

- `pack <id>` in the F8 console, or `godot --headless --path <game> -- --pack-mod <id> [output folder]` —
  checks the mod first, then writes `<id>-<version>.zip` without Godot's `.import`/`.uid` files.
- Players unzip nothing: the zip goes into `mods/` as is.
