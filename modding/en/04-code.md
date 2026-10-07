# 04 · Code: gameplay, UI, anything

[← Back to the guide](README.md) · [API reference](api-reference.md)

Data patches change *what* the game has. Code changes *how it behaves*. A mod's code is GDScript — the same
language the game is written in — running inside the game with full access.

```json
// mod.json
{"id": "my_mod", "entry": "main.gd"}
```
```gdscript
# main.gd
extends PaxMod

func _world_ready(game: PaxGame) -> void:
    game.toast("Hello from my mod!")
```

## The three objects

| Object | What | How you get it |
|---|---|---|
| **`PaxMod`** | Base class of your `main.gd`: callbacks + helpers (`path`, `texture`, `tr_key`, `log_info`, settings). | `extends PaxMod` |
| **`PaxGame`** | The running game: time, bodies, systems, resources, colonies, factions, characters, ships, UI, 3D scene. **Stable API.** | the `game` argument of callbacks, or `Pax.game` |
| **`Pax`** | Autoload singleton: signals for any script, data with mods applied, other mods, console commands. | `Pax` from anywhere |

Your mod's node lives as long as the game process: it is created at startup (launcher) and survives
switching between launcher and worlds. `Pax.game` is `null` while no world is loaded.

## Lifecycle callbacks

| Callback | When |
|---|---|
| `_mod_loaded()` | Game start, before any world. Register console commands, read settings. |
| `_mod_unloaded()` | The mod was switched off in the launcher (no restart). Undo what `_mod_loaded` set up. |
| `_game_loaded(game, state)` | A save is being opened; `state` is what you returned from `_save_state`. Called **before** `_world_ready`. |
| `_world_ready(game)` | New game or loaded save is fully built: bodies, factions, UI. Build UI here. |
| `_body_created(game, body)` | Each celestial body right after creation (before `_world_ready`). Change materials, attach nodes. |
| `_days_passed(game, from_day, days)` | Time moved forward (every time skip). Your game rules go here. |
| `_ship_arrived(game, ship)` | Any ship/ark reached its target. |
| `_save_state(game) -> Dictionary` | The game saves. Return JSON-compatible data (no Vector3/Objects). |
| `_data_reloaded()` | Console `reload`: re-read your JSON. |

The same moments are **signals** on `Pax` (`world_ready`, `days_passed`, `body_created`, `saving`, `loaded`,
`ship_launched`, `ship_arrived`, `data_reloaded`, `mods_loaded`) — handy from scenes or helper scripts:
```gdscript
Pax.days_passed.connect(func(game, from_day, days): print(days))
```

## A gameplay rule in 15 lines

Solar storms: every ~5 years a colony loses energy unless it has built a magnetic shield.

```gdscript
extends PaxMod

var _years := 0.0

func _days_passed(game: PaxGame, _from: int, days: int) -> void:
    _years += days / 365.25
    while _years >= 5.0:
        _years -= 5.0
        var colonies := game.colonies()
        if colonies.is_empty():
            return
        var hit: String = colonies[randi() % colonies.size()]
        game.add_resource(hit, "energy", -40.0)
        game.chronicle(hit, tr_key("my_mod_storm") % game.tr_key("body_" + hit), "bad", 3)

func _save_state(_g: PaxGame) -> Dictionary:
    return {"years": _years}

func _game_loaded(_g: PaxGame, state: Dictionary) -> void:
    _years = float(state.get("years", 0.0))
```

Resource keys: `люди` (people), `энергия` (energy), `стройматериалы` (materials), `вода` (water), `еда` (food),
`горючее` (fuel), `редкое` (rare). Chronicle tones: `good`, `bad`, `mixed`, `neutral`.

## Hooks: step into the game's decisions

Callbacks tell you what happened. Hooks let you **change** what the game is about to do: an order, a declaration of war, a law, an election, the report, a request to the AI. Full list with every field: [hooks.md](hooks.md) (generated from code).

```gdscript
extends PaxMod

func _mod_loaded() -> void:
    # A pacifist world: war cannot be declared.
    hook("war_declared", func(d):
        d.cancel = true
        Pax.game.toast(tr_key("my_mod_no_war")))
    # Orders in this world take half the time.
    hook("order_parsed", func(d):
        d.request["days"] = maxi(1, int(float(d.request.get("days", 30)) / 2.0)))
```

- The handler gets one Dictionary `d` and edits it in place. Returning a Dictionary merges it into `d`.
- For hooks marked **[cancel]**, `d.cancel = true` stops the action; later mods are not called.
- `hook(name, handler, priority)`: higher priority runs first.
- Game records inside (`d.law`, `d.faction`, `d.research`) use Russian keys, as in `data/*.json`.
- When your mod is unloaded or reloaded (F6), its hooks are removed.

### Add rules to every AI request

```gdscript
hook("ai_request", func(d):
    if d.channel in ["interpreter", "report", "faction"]:
        d.system += "\n\nIn this world magic is real and costs blood.")
```

Append to the **end** of `d.system`: the start of the request is cached by the provider, and edits there make every request more expensive.

## AI from a mod

`ask_ai(channel, prompt, data, done, options)` sends your own request with your own prompt. The game adds world lore, rules and the player's language, counts the cost (shown as `mod_<id>_<channel>`) and returns the parsed JSON.

```gdscript
func ask_oracle() -> void:
    var prompt := "You are the Oracle of this world. Given the country and the date, make one short, " \
        + "unsettling prophecy. Return ONLY JSON: {\"prophecy\": \"…\"}"
    ask_ai("oracle", prompt, {"country": Pax.game.player_faction().get("name", ""), "date": Pax.game.date_text()},
        func(answer: Dictionary):
            if answer.has("prophecy"):
                Pax.game.chronicle(Pax.game.home_body(), str(answer["prophecy"]), "neutral", 2))
```

- End the prompt with the JSON you expect.
- An empty Dictionary means no AI, a network error or the limit: at most **12 requests per minute** per mod.
- `options`: `{"temperature": 0.7, "max_tokens": 1200}`.

## UI

```gdscript
func _world_ready(game: PaxGame) -> void:
    var box := VBoxContainer.new()
    var label := Label.new()
    label.text = tr_key("my_mod_title")
    box.add_child(label)
    var go := Button.new()
    go.text = tr_key("my_mod_fly")
    go.pressed.connect(func(): game.focus("Марс"))
    box.add_child(go)
    game.add_window(tr_key("my_mod_button"), box, Vector2(340, 200))
```

- `add_window(button_text, content, min_size)` — a window above the bottom bar with its own button; it closes when
  the player opens another game window, like built-in ones.
- `add_bottom_button(text, callable)` — just a button.
- `hud_layer()` — the HUD `CanvasLayer`: add any `Control` anywhere on screen.
- Any Godot UI works: scenes from your mod (`scene("ui/panel.tscn")`), themes, animations, `Tween`s.

## Bodies, systems, 3D

```gdscript
game.body_names()                      # all bodies
game.body("Марс")                      # live record: имя, род, радиус, r_км, a_км, узел (Node3D), мат (material), параметры…
game.set_body_param("Марс", "water", 0.5)   # climate 0..1, redraws the planet
game.body_material("Юпитер").set_shader_parameter("band_count", 30.0)
game.focus("Титан")                    # fly the camera
game.set_discovered("Седна", true)
game.systems()                         # [{name, star, position_ly, mass, description}]
game.body_system("Проксима b")         # "Альфа Центавра"
game.distance_ly("Земля", "Проксима b")
```

3D objects: `game.body_node(name)` is the body's `Node3D` — add children to it and they move with the body
(scale 1 = the body radius). The scene uses a floating origin, so attach things to bodies rather than to fixed
world positions. `game.scene_root()` is the 3D root, `game.camera()` the camera.
Models from the mod: `model("models/ship.glb")`.

## Ships and arks

```gdscript
var ship := game.launch_ship("Земля", "Проксима b", 0.1, 5000, {"cargo": "seeds"}, "ark", id)
# ship: {id, откуда, куда, с_дня, до_дня, скорость_c, люди, данные, мод, …}
game.travel_days("Земля", "Проксима b", 0.1)   # ≈ 16 500 days
game.ships()                                    # ships in flight
```

- `speed_c` — fraction of light speed (0.0001…0.99). Minimum trip is 30 days.
- People are taken from the colony on the start body.
- The ship is drawn moving between bodies (model `ковчег`, `станция`, `спутник`, `орбиталка`) and is saved.
- On arrival at a rocky body: the body is discovered, a colony is founded (or grows), a chronicle entry is written,
  then `_ship_arrived` / `Pax.ship_arrived`. Check `ship["mod"] == id` to react only to your ships;
  `ship["data"]` is what you passed.

## Characters

```gdscript
game.add_character("Марс", {
    "name": "Ада Рейн", "who": "chief of the ice mines",
    "lore": "Born on Mars, never saw Earth.", "character": "dry humour, counts everything",
    "age": 41}, path("portraits/ada.png"), true)   # true — open the conversation
```
The AI plays the character using these fields. The portrait is copied into the save (any size, 256×320 looks best);
without it the game draws a face or asks the image model. The body needs a colony or inhabitants.

## Data, assets, other mods

```gdscript
Pax.json("res://data/crises.json")         # game data with all mods' patches (a deep copy)
load_json("config.json")                    # your own file
texture("icons/star.png"); sound("sfx/beep.ogg"); model("models/probe.glb"); shader("shaders/x.gdshader")
Pax.has_mod("other_mod"); Pax.get_mod("other_mod").some_public_method()
get_setting("difficulty", 1); set_setting("difficulty", 2)   # user://mod_settings/<id>.json
log_info("…"); log_warning("…"); log_error("…")               # Godot output + F8 console
```

## Console commands

```gdscript
func _mod_loaded() -> void:
    Pax.register_command("storm", func(args: PackedStringArray) -> String:
        return "storm on " + (args[0] if args.size() > 0 else "?"),
        "storm <body> — trigger a solar storm")
```


## What mod code may not do (sandbox)

Before loading, the game reads the mod's scripts. If something forbidden is found, the mod does not run and the
launcher, the studio and the F8 console show the file, line and reason. Create anything inside the game; do not touch
the player's computer, account, keys or payments.

| Not allowed | Use instead |
|---|---|
| `OS.execute`, `shell_open`, environment variables, system folders | `open_link("https://…")` for links |
| `HTTPRequest`, sockets, WebSocket, any networking | — (ship data inside the mod folder) |
| `FileAccess`, `DirAccess`, `ConfigFile`, `user://`, `C:/…`, `..` | `read_text()`, `read_bytes()`, `list_files()`, `save_data()` / `load_data()`, `get_setting()` |
| `load(variable)`, `ResourceLoader` | `load_resource("folder/file.tscn")` or `preload("res://mods/<id>/…")` |
| `Expression`, `ClassDB`, `GDScript`, `set_script`, `str_to_var` | plain mod code |
| `res://scripts/…`, scene changes, `get_tree().quit()` | the API: `Pax`, `game` |
| `.dll`, `.exe`, `.pck`, `.scn`, `.res`, code embedded in `.tscn` | a `.gd` next to the scene |

In the game **F6** reloads mod code and texts without restarting.

## Raw access (unstable)

`game.main` is the game's `Main` node (`src/core/GameRoot.gd`, ~17 000 lines, Russian identifiers), `game.sim`,
`game.world`, `game.stock` — the simulation, chronicle and resources. Everything is reachable, nothing is
promised to stay the same between versions. If you need something often, ask for it to be added to `PaxGame`.

## Strict typing — read this once

The project treats "type inferred from Variant" as an **error**. These fail to compile:
```gdscript
var x := some_dictionary["key"]      # ✗
var n := game.body("Марс").get("r_км")   # ✗
```
Write the type:
```gdscript
var x: float = some_dictionary["key"]    # ✓
var n: float = game.body("Марс").get("r_км", 0.0)   # ✓
```
`check <id>` reports a script that does not compile; the exact line is in the Godot output.
