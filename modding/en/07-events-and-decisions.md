# 07 · Events and decisions without code

An event is a card that appears on its own when its conditions are met: a drought, a delegation, a strike, an archaeological find. An event has options, each option has effects.
A decision is a button in the **Decisions** window on the bottom bar: the player enacts it, pays the cost and gets the effect.

Everything goes into one mod file, `data/mod_events.patch.json`. No code at all. A working example is the `example_events` mod (in the game folder: `docs/modding/examples/example_events`).

Keys are Russian, like everywhere in the game's data; English aliases work too (shown in brackets below).

## The file

```json
{
  "events": {"$append": [ { …event… } ]},
  "decisions": {"$append": [ { …decision… } ]}
}
```

`$append` adds your records to other mods' records, so mods don't clash. Every record needs a unique `id`: start it with your mod id.

## Event

```json
{
  "id": "my_mod_drought",
  "title": {"ru": "Засуха", "en": "Drought"},
  "text": {"ru": "Третью неделю ни капли.", "en": "Not a drop for three weeks."},
  "picture": "res://mods/my_mod/drought.png",
  "conditions": {"resource": {"food": {"меньше": 500}}},
  "шанс_v_year": 0.8,
  "times": 3,
  "options": [
    {"text": {"ru": "Открыть резерв", "en": "Open the reserve"},
     "conditions": {"money": {"не_меньше": 200}},
     "effects": {"money": -200, "resources": {"food": 300}}},
    {"text": {"ru": "Пусть справляются", "en": "Let them manage"},
     "effects": {"flag": "my_mod_ignored"}}
  ]
}
```

| Field | Meaning |
|---|---|
| `id` | unique name |
| `заголовок` (title), `текст` (text) | a string, a per-language dictionary `{"ru": …, "en": …}` or `"@key"` from your `data/lang/*.json` |
| `картинка` (image) | optional png/jpg from the mod |
| `условия` (conditions) | when the event may happen (below) |
| `шанс_в_год` (yearly_chance) | chance per game year, 0…1; default 1 — as soon as conditions hold |
| `раз` (times) | how many times per campaign; `0` — unlimited; default 1 |
| `эффекты` (effects) | applied immediately, before the choice |
| `варианты` (options) | buttons; an option whose `условия` fail is hidden. No options — the event just goes to the chronicle |
| `только_цепочкой` (chain_only) | `true` — never fires on its own, only through the `"event"` effect |

## Decision

```json
{
  "id": "my_mod_public_works",
  "title": {"ru": "Народная стройка", "en": "Public works"},
  "text": {"ru": "Нанять безработных на дороги.", "en": "Hire the unemployed to build roads."},
  "price": 300,
  "seen": {"at_war": false},
  "conditions": {"money": {"не_меньше": 300}},
  "rollback_days": 180,
  "times": 0,
  "effects": {"resources": {"materials": 250}}
}
```

`видно` (visible) — when the decision is listed at all; `условия` (conditions) — when the button is active; `цена` (cost) — money; `откат_дней` (cooldown_days); `раз` (times) — per campaign, `0` — unlimited.

## Conditions

All conditions in a dictionary must hold. Numbers are compared with `{"больше": 1, "меньше": 5, "не_меньше": 1, "не_больше": 5, "равно": 3}` (or `more`, `less`, `at_least`, `at_most`, `equals`) or a plain number, meaning "at least".

| Condition | Example |
|---|---|
| `после` (after), `до` (before) | `"after": "1941-06-22"` |
| `страна` (country) | `"country": "Россия"` or a list |
| `деньги` (money) | `"money": {"больше": 1000}` |
| `ресурс` (resource) | `"resource": {"food": {"меньше": 500}, "fuel": 100}` |
| `война` (war) | `true` — any war, `false` — peace, `"Франция"` — with that country |
| `отношение` (relation) | `"relations": {"Франция": {"меньше": 0.3}}` (0 hostile … 1 ally) |
| `закон` (law) | a law in force whose title contains the word |
| `форма` (government) | form of government key from `data/politics/forms.json` |
| `флаг` (flag), `нет_флага` (no_flag) | flags set by effects |
| `мод` (mod) | another mod is enabled |
| `шанс` (chance) | random roll at check time: `0.3` |
| `любое` (any) | a list of condition sets, one is enough |
| `не` (not) | a condition set that must NOT hold |

## Effects

| Effect | Example |
|---|---|
| `деньги` (money) | `"money": -200` |
| `ресурсы` (resources) | `"resources": {"food": 300, "materials": -50}` |
| `отношение` (relation) | `"relations": {"Франция": 0.1}` |
| `флаг` (flag), `снять_флаг` (clear_flag) | `"flag": "my_mod_x"` |
| `хроника` (chronicle) | `"chronicle": {"text": {"en": "…"}, "tone": "good", "weight": 3}` |
| `сообщение` (message) | a short line in the feed |
| `объявить_войну` (declare_war) | `"declare_war": "Франция"` |
| `провинция` (province) | `"province": {"id": 1368, "owner": "Франция"}` — instead of an id `"случайная"` (random) or a country; owner `""` — nobody |
| `кратер` (crater) | `"кратер": {"province": "случайная", "radius": 300}` — a strike on voxel copies of the planet, see [09 Voxels](09-voxels.md) |
| `событие` (event) | show another event by `id` — this is how chains are built |

## Your own conditions and effects

A mod with code can add keywords, and every JSON mod can then use them:

```gdscript
func _mod_loaded() -> void:
    Pax.register_condition("my_mod_winter", func(v, game): return bool(v) == (game.date().month in [12, 1, 2]))
    Pax.register_effect("my_mod_ark", func(v, game): game.launch_ship(game.home_body(), str(v), 0.05, 500))
```

Test an event without waiting: console **F8** → `eval Pax.fire_event("my_mod_drought")`.

Flags, event counters and decision cooldowns are saved automatically.
