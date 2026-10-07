# 02 · Changing game data

[← Back to the guide](README.md)

Almost everything in Pax Universe is data: `data/*.json` and `data/*.txt` inside the game. A mod changes them
**without copying** — by putting a file with the same path into the mod.

| File in the mod | Effect |
|---|---|
| `data/X.patch.json` | **Patch** `data/X.json`: merge objects, operate on arrays. ✅ Use this. |
| `data/X.json` | **Replace** the whole file. ⚠ Conflicts with other mods; breaks on game updates. The checker warns. |
| `data/lang/X.json` | Translations are **merged** into the game dictionary (never replaced). |
| `data/X.append.txt` / `.append.md` | **Append** text to `data/X.txt` / `.md` (AI prompts, news). |
| `data/X.txt` | Replace a text file. |
| any new path | A new file the game (or your code) reads, e.g. `data/regions/xeno.json`. |

Patches of all enabled mods are applied in load order. See the final result any time with the console
command `json res://data/bodies.json`.

## Patch format

A patch is **JSON Merge Patch** (RFC 7396) with array operations added.

### Objects merge

```json
{"formulas": {"chance_project": "0.5 * покрытие"}, "устаревшее_поле": null}
```
Keys are merged recursively; `null` deletes a key. Arrays are **not** merged by index — use operations:

### Array operations

```json
{
  "bodies": {
    "$remove":       [{"name": "Плутон"}],
    "$edit":         [{"$match": {"name": "Марс"}, "r": 3500, "parameters": {"water": 0.3}}],
    "$insert_after": {"$match": {"name": "Земля"}, "items": [{"name": "Counter-Earth", "genus": "rock"}]},
    "$prepend":      [ … ],
    "$append":       [ … ]
  }
}
```

| Operation | Does |
|---|---|
| `$append` / `$prepend` | Add items to the end / beginning. |
| `$edit` | For every item matching `$match`, merge the rest of the object into it (nested merge works). |
| `$remove` | Remove matching items. Items can be objects (partial match) or plain values: `"$remove": ["a", 3]`. |
| `$insert_after` | Insert `items` right after the first match (one object or a list of them). |
| `$replace` | Replace the array (or any object) completely: `{"$replace": [...]}`. |

Order inside one object: `$remove → $edit → $insert_after → $prepend → $append`.

`$match` compares only the listed keys; a list value means *any of*: `{"$match": {"genus": ["gas", "star"]}}`.
If nothing matches, the patch continues and the mod gets a **warning** (launcher card, `check`, console).
An operation on an array that does not exist yet treats it as empty — so you can add sections the game file
does not have (like `"systems"`).

## Game data files

Keys are Russian — copy them exactly. Open the game's file to see the full structure; most files start with a
`"_комментарий"` / `"_как_это_работает"` explaining the rules (in Russian — an AI assistant translates it well).

| File | What it is | Main keys |
|---|---|---|
| `bodies.json` | Planets, moons, stars, belts, **star systems** | `тела`, `пояса`, `системы` — see [03](03-planets-and-stars.md) |
| `bodies_lang.json` | Body names per language (old format; prefer `тело_<name>` keys in `lang/`) | `языки` |
| `resources.json` | Resources, formulas, richness of each body | `ресурсы`, `формулы`, `тела.<body>.богатство`, `колония` |
| `projects.json` | Megaprojects (orbital mirror, …) | `проекты[]`: `имя`, `слова` (trigger words), `цена`, `зачем`, `что_даёт` |
| `crises.json` | Crises growing through 5 stages | `кризисы[]`: `id`, `имя`, `эпоха`, `объяснение`, `шанс_века`, `скорость`, `сопротивление`, `стадии[]` |
| `world_events.json` | Random events while time runs | `плохо[]`, `хорошо[]`, `смешанно[]`: `шкала`, `текст` with `{место}`, `эффект` |
| `events_bodies.json` | Events and dossiers of specific bodies | `тела.<body>.досье`, `события[]` |
| `development.json` | Development scale levels of colonies | `сеть`, `жильё`, `инфраструктура`, `работа`, `добыча`, `наука` — lists of `{имя, что}` |
| `factions.json` | The player's faction and random neighbours | `наша`, `чужие[]` (type, colour, strength, names, character, intents) |
| `leaders.json` | Leaders who replace the player when overthrown | `главы[]`: `имя`, `откуда`, `характер`, `первое_слово` |
| `names.json` | Name pools per language | `языки.<code>.мужские/женские/фамилии` |
| `markers.json` | Starting map markers | `метки[]`: `широта`, `долгота`, `тип`, `имя`, `описание` |
| `models.json` | 3D models picked by words of orders | `модели[]`: `файл` (name or `res://mods/…` path), `слова`, `размер`, `орбита` |
| `satellites.json` | Artificial satellites by date | `спутники[]` |
| `epochs.json` | Time-machine epochs | `эпохи[]` |
| `anomalies.json`, `prophecies.json` | Time-travel oddities and self-fulfilling prophecies | `аномалии[]`, `пророчества[]` |
| `start.json` | Starting climate and resources | `параметры`, `ресурсы`, `склад` |
| `problems.json` | Starting problems and state-based complaints | `стартовые[]`, `по_состоянию` |
| `terrain.json` | Terrain types | |
| `preset_default.json` | The default world: lore, factions, territories | `лор_системы`, `лор_тел`, `фракции`, `сюжет` |
| `prompt_*.txt` | Instructions for the AI channels (interpreter, events, talk, person, report…) | text — append with `.append.txt` |
| `news/<code>.md` | "What's new" in the launcher | markdown |
| `lang/<code>.json` | UI texts | flat `key: text` |
| `regions/*.json/.bin` | Province maps of bodies | generated by `tools/провинции` |

## Example: a harsher world

`mods/hardcore/data/crises.patch.json`
```json
{"crises": {"$edit": [
  {"$match": {"id": "чума"}, "шанс_centuries": 60, "speed": 1.2}
]}}
```

`mods/hardcore/data/start.patch.json`
```json
{"resources": {"humans": 60}, "parameters": {"radiation": 0.7}}
```

## Tips

- **Reload without restart:** after editing JSON, type `reload` in the F8 console. Data read later uses the new
  values; things already built (e.g. bodies in the scene) need a new game or a restart.
- **See what the game really gets:** `json <path>` prints the final data after all patches.
- **A patch refers to a game file that does not exist?** The checker warns: most likely a typo in the file name.
- **Numbers**: JSON numbers are floats in Godot; `3` and `3.0` match equally in `$match`.
