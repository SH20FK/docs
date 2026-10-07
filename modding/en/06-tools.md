# 06 · Tools: console, checker, packaging, AI assistants

[← Back to the guide](README.md)

## Dev console — F8

Works in the launcher and in the game.

| Command | Does |
|---|---|
| `help` | All commands (including ones added by mods) |
| `mods` | Installed mods, enabled state, load order, which have code |
| `problems` | Everything that went wrong while loading mods |
| `check [id]` | Validate one mod or all (see below) |
| `json <path>` | Final data after all patches, e.g. `json res://data/crises.json` |
| `reload` | Clear data caches: JSON, text, images are re-read on next use |
| `eval <expr>` | Evaluate an expression with `game` and `Pax`: `eval game.distance_ly("Земля", "Проксима b")` |
| `new <id> [Name]` | Create a mod from the template and open its folder |
| `pack <id>` | Zip a folder mod into `user://mods_dist/` |
| `folders` | Where mods are searched |
| `events` | Mod events and decisions: ● — conditions met now; flags |
| `fire <id>` | Show a mod event right now without waiting for its conditions |

Your own: `Pax.register_command("name", func(args): return "…", "help text")`. ↑/↓ — history.

## Checker

```
godot --headless --path <game folder> -- --check-mods            # all mods
godot --headless --path <game folder> -- --check-mods my_mod     # one
```
In the released game use `PaxUniverse.exe` instead of `godot --path …`. Exit code `0` — no errors, `1` — errors
(use it in CI). It checks:

- `mod.json`: valid JSON, id format, dependencies present and new enough, API/game version.
- Every `.json` in the mod parses (with line numbers).
- Every `data/*.patch.json` targets an existing game file; the patch applies; `$match` finds something.
- Replacing whole game files (warning — prefer patches).
- Bodies after patching: names, `род`, parents listed before moons, known systems, texture sets, shader/model files.
- Translations: all `data/lang/*.json` of the mod have the same keys; English exists.
- Code: `entry` exists, starts with `extends PaxMod`, compiles.
- A thumbnail and a description.

Every message says what is wrong, where, and how to fix it — written for people and for AI assistants.

## Creating and packaging

```
godot --headless --path <game> -- --new-mod my_mod My Mod Name
godot --headless --path <game> -- --pack-mod my_mod [output folder]
```
`--pack-mod` refuses to pack a mod with errors. The zip excludes `.import`, `.uid` and OS junk files.

## Editor setup

- **VS Code**: the template's `.vscode/settings.json` connects JSON schemas: autocompletion and hover docs for
  `mod.json`, `bodies.patch.json` and translations. For GDScript install the *godot-tools* extension.
- **Godot editor**: open the game project; the `mods/` folder is ignored by the importer (`.gdignore`), edit files
  with any text editor and run the game from the editor — mods in `<project>/mods/` load directly, no packing.
- **API reference** is generated from the code: `python tools/modding/api_reference.py` (game source).

## Mod studio in the launcher

Launcher → **Mods** → **Create your own mod**. Files on the left, code in the middle, a real terminal below.

- **The wizard** starts from an empty mod, a planet, a star system or **events and decisions** — a copy of a working example under your id.
- **＋ Event** — a builder: title and text in two languages, conditions, chance, options with effects, or a paid decision with a cooldown. The record is appended to `data/mod_events.patch.json`, which opens next to it for hand edits.
- **✨ Describe it** — write what you want and pick an agent (Makura, Claude Code, Codex). The studio puts `ЗАДАНИЕ_ИИ.md` with your text and the rules into the mod folder and starts the agent in the terminal, told to read it.
- **✔ Check** — the checker report where file names are links: a click opens the file at the line with the error.
- **▶ Play with the mod** — the game with your mod on; F8 → `events`, `fire <id>` test events without waiting.

## AI assistants

The template has **`AGENTS.md`** — instructions read by Claude Code, Cursor, Copilot, Codex and others — and
`CLAUDE.md` that points to it. It explains where things are, the rules (patch don't copy, Russian data keys, texts
in `data/lang`, strict typing) and requires running the checker. A good workflow:

1. `new my_mod` → open the game folder in the editor/assistant (so it can read `data/` and `docs/`).
2. Describe the mod in plain words. Ask for a plan first for big mods.
3. Let it run `--check-mods my_mod` and fix what it reports.
4. Run the game, press F8, `problems`; look at the result in the game.

## The author page and "Support the author"

The author's name on an item page is a link: it shows all your mods and presets and a summary — installs, average
rating, this month's votes, how many works are verified on the current version.

The author account on the site (editing an item) has two optional fields: a link to your **Boosty** and to your
**Patreon**. Fill them in and "Support the author" buttons appear on the item page and on your author page. Only
`https://boosty.to/…` and `https://www.patreon.com/…` addresses are accepted. These are your own donations: the game
takes no part in them and no commission. Updating a version from the studio does not touch these links.

## The Modder's Herald: mod of the month and the one-headline jam

Every month the store opens with a newspaper sheet carrying one **headline from the future** — for example "The Moon
declares independence". That headline is the jam theme.

- **Jam.** By day 10, publish a mod or preset in which that headline can happen and tag it `jam-YYYY-MM`
  (e.g. `jam-2026-10`). The "Take part" button opens the studio and copies the tag to the clipboard.
  The easiest entry is an event or decision from [chapter 7](07-events-and-decisions.md) — no code needed.
- **Mod of the month.** The whole catalogue takes part, no tag needed.
- **Votes.** Players vote in the launcher, on the item page, and only for what they have installed: one vote for mod of
  the month and one for a headline entry. A vote can be moved until the month ends. You cannot vote for your own work.
- **Winning.** Most votes, but at least three; ties are broken by installs. Winners spend the next month at the top of
  the catalogue with a 🏆 or 📰 badge; the author gets the "Modder of the month" Discord role and three game keys to
  give away. Results come on the 1st, Moscow time.

The **✔ "Verified on this version"** mark is not a prize: we set it when a mod has passed the check on the current game version.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Mod not in the launcher | `mod.json` missing or invalid; folder name starts with `_`/`.`; zip without `mod.json`. `problems` shows why. |
| Changes don't apply | After editing JSON use `reload` or restart; check load order (later wins). |
| `$edit found nothing matching …` | The key or value in `$match` differs (exact Russian name, e.g. `"Марс"`). Look with `json <path>`. |
| Script "does not compile" | The Godot output has the line. Usually `var x :=` from an untyped value → add a type. |
| Texture not shown | `"map"` must be the path **without** `_albedo.png`; files named `<name>_albedo.png`. |
| Planet in the wrong place | `a` is in km; moons need `"period"`; the parent must be listed before the moon. |
| Text shows a raw key | Key missing in `data/lang/<code>.json` of the player's language and in `en.json`. |
