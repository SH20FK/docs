# 05 · Recipes

[← Back to the guide](README.md)

Short, copy-paste solutions. Keys are Russian — copy them exactly. When in doubt, open the game's own file in
`data/` and look at an existing entry: every new entry follows the same shape.

- [Characters](#characters) · [Leaders](#leaders) · [Factions](#factions)
- [Events](#events) · [Crises](#crises) · [Megaprojects](#megaprojects) · [Resources of a body](#resources-of-a-body)
- [Music and sound](#music-and-sound) · [3D models for orders](#3d-models-for-orders)
- [A new language](#a-new-language) · [Teaching the AI](#teaching-the-ai) · [A world preset](#a-world-preset)
- [Terraforming Venus in one file](#terraforming-venus-in-one-file)

---

## Characters

People the player meets and talks to (the AI voices them). Add from code when it makes sense in your story:

```gdscript
func _world_ready(game: PaxGame) -> void:
    if not game.has_character("Ада Рейн") and game.colonies().has("Марс"):
        game.add_character("Марс", {
            "name": "Ада Рейн",
            "who": tr_key("my_mod_ada_who"),
            "lore": tr_key("my_mod_ada_lore"),
            "character": tr_key("my_mod_ada_character"),
            "age": 41
        }, path("portraits/ada.png"))
```
The text fields are what the AI reads to play the person — write them in the player's language via `tr_key`.

## Leaders

Who replaces the player when trust collapses — `data/leaders.patch.json`:
```json
{"heads": {"$append": [{
  "name": "Ilse Varga",
  "origin": "hydroponics engineer who fed the colony through the first winter",
  "character": "quiet, stubborn, remembers every promise",
  "first_word": "Show me the water reports. Then we talk."
}]}}
```

## Factions

Random neighbours on Earth — `data/factions.patch.json`. Copy an entry of `"strangers"` from the game file and change it.
`тип` drives behaviour: `банда`, `мародёры` (predators), `секта` (predatory to peaceful neighbours), `община`, `анклав`, `торговцы` (peaceful).
Intents (`умыслы`, weights): `выжить`, `грабить`, `захватить_нас`, `культ`, `найти_родных`, `обложить_данью`,
`отомстить_олигархам`, `поработить`, `построить_дом`, `сохранить_знания`, `торговать`, `уйти_на_орбиту`.
```json
{"strangers": {"$append": [{
  "type": "sect",
  "colour": [0.55, 0.3, 0.8],
  "strength": [0.1, 0.2],
  "names": ["Children of the Last Light", "The Quiet Choir"],
  "description": "Believe the war was a cleansing. Kind to strangers, merciless to doubters.",
  "humans": [60, 200], "level": [0.2, 0.8], "relations": 0.4, "growth": 0.01, "roam": false,
  "temper": {"wits": [0.3, 0.6], "cunning": [0.4, 0.8], "cruelty": [0.2, 0.7], "honesty": [0.3, 0.7], "cohesion": [0.8, 1.0]},
  "contingent": {"scientists": 0.05, "masters": 0.2, "fighters": 0.2, "laborers": 0.4, "children_elders": 0.15},
  "intents": {"cult": 5, "to_trade": 2}
}]}}
```

## Events

Random things while time runs — `data/world_events.patch.json`. Lists `плохо` (bad), `хорошо` (good), `смешанно` (mixed).
```json
{"good": {"$append": [{
  "scale": "science",
  "text": "students at «{место}» rebuilt a pre-war spectrometer",
  "effect": {"scales": {"science": [0.3, 0.9]}, "trust": [0.01, 0.03]}
}]}}
```
- `шкала` — development scale the event belongs to: `сеть`, `жильё`, `инфраструктура`, `работа`, `добыча`, `наука`
  (empty — any). `{место}` becomes a place of that scale (from `"places"`).
- `нужно` (optional) — minimum scale levels, e.g. `{"jobs": 10}`.
- `эффект` ranges `[min, max]`: `шкалы` (levels), `ресурсы` (negative — fraction of stock, positive — units per person),
  `доверие` (trust shift), `люди` (fraction of population), `климат` (shift of a climate parameter).

Events tied to one body (with a dossier for the AI) live in `data/events_bodies.json` → `"bodies"."<body>"`.

## Crises

Five-stage threats — `data/crises.patch.json`:
```json
{"crises": {"$append": [{
  "id": "my_mod_flare",
  "name": "The Star Wakes",
  "era": "technologies",
  "explanation": "a magnetic cycle of the star, predictable but brutal",
  "needs": {},
  "шанс_centuries": 15,
  "speed": 0.8,
  "resistance": ["science", "infrastructure"],
  "spread": 0.2,
  "how_to_fight_it": "shielded shelters, spare transformers, a warning network",
  "stages": [
    {"name": "Sunspots", "what": "radio crackles at noon"},
    {"name": "Flares", "what": "satellites go blind for hours"},
    {"name": "Blackouts", "what": "the grid burns on the day side"},
    {"name": "Storm season", "what": "nobody goes outside without a dosimeter"},
    {"name": "Scorched sky", "what": "the day side is abandoned"}
  ]
}]}}
```
`эпоха` — when it can start: `руины`, `индустрия`, `технологии`, `любая`. `нужно` — minimum development levels, e.g. `{"comms": 8}`.

## Megaprojects

`data/projects.patch.json` — the AI recognises a project by `слова` (words) in the player's order:
```json
{"projects": {"$append": [{
  "name": "Stellar lance",
  "words": ["lance", "star lance", "звёздное копьё"],
  "price": {"humans": 80, "energy": 900, "materials": 600, "rare": 120},
  "what_for": "Pushes an asteroid onto a new orbit to bring water.",
  "what_it_gives": "water"
}]}}
```

## Resources of a body

How rich a body is and what its colony is called — `data/resources.patch.json`:
```json
{"bodies": {"Тея": {"wealth": {"energy": 1, "materials": 3, "water": 2, "rare": 2, "food": 0, "fuel": 1},
                  "colony": "Theia outpost"}}}
```

## Music and sound

- **Music**: put `.ogg`/`.mp3` into `mods/<id>/music/` with the game's prefixes — `надежда_` (calm/hope), `тревога_` (tension),
  `начало_` (new game), `контакт_` (first contact), `этап_` (milestone), `кризис_` (crisis), `перемотка_` (time skip),
  `автоигра_` (auto-play). Example: `music/надежда_my_mod_1.ogg`. They join the game's playlists.
- **Ambient layers** (replace): `mods/<id>/ambient/<layer>.ogg`, layers: `космос`, `радиация`, `пустота`, `холод`,
  `жара`, `вода`, `океан`, `пустыня`, `живность`, `воздух`, `джунгли`, `город`.
- **Any sound from code**: `var p := AudioStreamPlayer.new(); p.stream = sound("sfx/alarm.ogg"); add_child(p); p.play()`.

## 3D models for orders

When the player orders "build a dome", the game picks a model by words — `data/models.patch.json`:
```json
{"models": {"$prepend": [{
  "file": "res://mods/my_mod/models/arcology.glb", "orbit": false, "size": 0.05,
  "words": ["arcology", "аркология"]
}]}}
```
`$prepend` — the first match wins, so specific words go first. `орбита: true` puts the model on orbit.

## A new language

1. Copy the game's `data/lang/en.json` into `mods/<id>/data/lang/<code>.json` (e.g. `pl.json`) and translate the values.
2. Optional: names for people — `data/names.patch.json` → `{"languages": {"pl": {"name_language": "Polish", "male": […], "female": […], "surnames": […]}}}`.
3. Body names come from `тело_<name>` keys — they are in the same dictionary.
The language appears in the launcher settings. Missing keys fall back to English.

## Teaching the AI

The AI narrator works from instructions in `data/prompt_<channel>.txt`. Append your world's rules with
`data/prompt_<channel>.append.txt` (don't replace — other mods append too):

| Channel | Role |
|---|---|
| `interpreter` | Turns the player's orders into actions |
| `event` | Writes events |
| `talk`, `person` | Conversations and new people |
| `report`, `chapter`, `consequences` | Time-skip reports and chronicle chapters |
| `faction`, `faction_order`, `council` | Factions and the council |
| `province`, `unit`, `surroundings` | Provinces, military units, surroundings |
| `epoch`, `god`, `successor`, `assistant` | Time travel, the end of time, successors, the assistant |

`mods/xeno_life/data/prompt_event.append.txt`:
```
In this world microbial life exists under the ice of Europa and Enceladus. Events about these moons may mention
biosignatures, but never intelligent life.
```

## A world preset

Build a world in the game's **preset editor** (factions, territories, lore, start date), then copy its folder from
`user://presets/<Name>/` into `mods/<id>/presets/<Name>/`. It is installed for players on start; raise `"version"`
in `meta.json` to update it for people who already have it.

## Terraforming Venus in one file

`mods/blue_venus/data/bodies.patch.json`:
```json
{"bodies": {"$edit": [{
  "$match": {"name": "Венера"},
  "parameters": {"temperature": 0.38, "water": 0.55, "atmosphere": 0.45, "biomass": 0.25, "radiation": 0.1, "magnetic": 0.2},
  "map": "res://mods/blue_venus/venus",
  "map_sea": 0.45
}]}}
```
Plus `venus_albedo.png`, `venus_height.png`, `venus_ocean.png` next to it — and Venus is an ocean world.

## Interface theme

`data/ui_theme.patch.json` in your mod — the game's colours and font. Colours are set by **roles**: change a role and
every place that uses it changes.

```json
{
  "window": "#2a0f14",
  "panel": "#1a0a10",
  "text": "#ffe2a8",
  "muted": "#c08a6a",
  "accent": "#5fe08a",
  "good": "#7ad1ff",
  "bad": "#ff5a8a",
  "warning": "#ffb04a",
  "info": "#ffd24a",
  "special": "#d9a6ff",
  "font_size": 18,
  "font": "res://mods/my_mod/fonts/MyFont.ttf"
}
```

| Role | What it paints |
|---|---|
| `window`, `panel` (`окно`, `панель`) | backgrounds of windows, bars, cards and buttons |
| `text`, `muted` (`текст`, `тихий`) | main and secondary text |
| `accent` (`акцент`) | headings, highlights, the pressed button, the thread on panels (gold in the game) |
| `good`, `bad`, `warning` (`хорошо`, `плохо`, `тревога`) | green, red and orange: "in force", "cancel", warnings |
| `info`, `special` (`инфо`, `особое`) | information (teal) and the unusual (purple) |

The roles are used by the game windows (laws, research, mining, inbox, contacts, government, course and others), the
top and bottom bars, buttons and the coloured text of the event feed. Each place keeps its own transparency. A colour
is `"#rrggbb"` or `[r, g, b]` as fractions. Any key may be missing — the game's look stays there.

The theme does not touch what draws the world rather than the interface: the map and country colours, charts,
resource icons, 3D figures. The newspaper is printed on its own paper. The theme is read when the game starts —
restart the session after editing it.

## Your own calendar

Month names, the era and the year count of your world — no code. Mod file `data/calendar.patch.json`:

```json
{
  "months": ["Frostmonth", "Stormmonth", "Thaw", "Brooks", "Bloom", "Bright", "Heat", "Harvest", "Rust", "Leaffall", "Mist", "Dark"],
  "era": "FE",
  "year_offset": 0
}
```

- `months` (`месяцы`) — exactly 12 names; a plain list, or per language: `{"ru": […], "en": […]}`.
- `era` (`эра`) — the label after the year: "958 FE"; a string or per language.
- `year_offset` (`сдвиг_года`) — added to the displayed year when your count starts from your own event.

The date looks like this everywhere: the top bar, the newspaper, the requests to the AI. Day counting, seasons and
orbits do not change — a year still has 12 months. The same block can live in a preset as `"calendar"` in `meta.json`;
the preset wins. The starting year of the world is the preset's `"start"` field. A world imported from Azgaar gets its
era automatically.
