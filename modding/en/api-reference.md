# Pax API reference

_Generated from doc comments by `tools/modding/api_reference.py` — do not edit by hand._

Guides: [README](README.md) · [Code](04-code.md) · [Recipes](05-recipes.md)

## PaxMod

Base class of your mod's code (`extends PaxMod`). Override the callbacks you need.

### PaxMod — Callbacks

#### `_mod_loaded`

```gdscript
func _mod_loaded()
```

Mod code is loaded (launcher start, before any world). Register commands here.

#### `_world_ready`

```gdscript
func _world_ready(_game: PaxGame)
```

A world (new or loaded game) is fully built: bodies, factions, UI exist.

#### `_days_passed`

```gdscript
func _days_passed(_game: PaxGame, _from_day: int, _days: int)
```

Time moved forward: the world lived `days` days starting at `from_day`.

#### `_save_state`

```gdscript
func _save_state(_game: PaxGame) -> Dictionary
```

The game is being saved. Return a Dictionary (JSON types only) — it is stored in the save and handed back to `_game_loaded`. Return {} to store nothing.

#### `_game_loaded`

```gdscript
func _game_loaded(_game: PaxGame, _state: Dictionary)
```

A save was loaded. `state` is what `_save_state` returned last time ({} if none).

#### `_body_created`

```gdscript
func _body_created(_game: PaxGame, _body: Dictionary)
```

A celestial body was created in the 3D scene. `body` — the game's body record (name, kind, radius, node, material…). Change its material/node freely.

#### `_ship_arrived`

```gdscript
func _ship_arrived(_game: PaxGame, _ship: Dictionary)
```

A ship launched by anyone (see PaxGame.launch_ship) reached its target. ship["mod"] — id of the mod that launched it, ship["data"] — the data you passed.

#### `_data_reloaded`

```gdscript
func _data_reloaded()
```

Data caches were cleared by the console command `reload`. Re-read your JSON here.

### PaxMod — Constants

#### `KeyMigration`

```gdscript
const KeyMigration = preload("res://src/save/KeyMigration.gd")
```

### PaxMod — Properties

#### `id`

```gdscript
var id: String
```

Base class for a Pax Universe mod's code. In mod.json:  "entry": "main.gd"   →   main.gd:  extends PaxMod Everything is optional: override only the callbacks you need. Your files live at res://mods/<id>/ — use `path` to build paths. Full guide: docs/modding/en/README.md  (RU: docs/modding/ru/README.md) Mod id from mod.json. / id мода из mod.json.

#### `manifest`

```gdscript
var manifest: Dictionary
```

Parsed mod.json (plus "root", "source", "enabled"). / Разобранный mod.json.

#### `root`

```gdscript
var root: String
```

"res://mods/<id>/"

### PaxMod — Methods

#### `path`

```gdscript
func path(relative: String) -> String
```

Path inside this mod: path("textures/sky.png") → "res://mods/<id>/textures/sky.png".

#### `load_json`

```gdscript
func load_json(relative: String, default_value = null)
```

JSON file of this mod (parsed). / JSON-файл мода.

#### `texture`

```gdscript
func texture(relative: String) -> Texture2D
```

Image from this mod (png/jpg/webp/svg/tga/bmp) — no Godot import needed.

#### `sound`

```gdscript
func sound(relative: String) -> AudioStream
```

Sound from this mod (ogg/mp3/wav).

#### `model`

```gdscript
func model(relative: String) -> Node3D
```

3D model from this mod (glb/gltf) → ready Node3D.

#### `shader`

```gdscript
func shader(relative: String) -> Shader
```

Shader from this mod (.gdshader).

#### `scene`

```gdscript
func scene(relative: String) -> Node
```

Scene from this mod (.tscn) → instance.

#### `load_resource`

```gdscript
func load_resource(relative: String) -> Resource
```

Any resource of this mod (scene, script, material…) — instead of load(path(...)).

#### `read_text`

```gdscript
func read_text(relative: String) -> String
```

Text file of this mod. / Текстовый файл мода.

#### `read_bytes`

```gdscript
func read_bytes(relative: String) -> PackedByteArray
```

Bytes of a file of this mod. / Байты файла мода.

#### `list_files`

```gdscript
func list_files(relative_folder := "") -> PackedStringArray
```

Files in a folder of this mod (relative names). / Файлы в папке мода.

#### `save_data`

```gdscript
func save_data(name: String, value)
```

Save any data of your mod (JSON-compatible) under a name; survives restarts.

#### `load_data`

```gdscript
func load_data(name: String, default_value = null)
```

#### `open_link`

```gdscript
func open_link(url: String) -> bool
```

Open a web link (https only) in the browser. / Открыть ссылку https в браузере.

#### `tr_key`

```gdscript
func tr_key(key: String, args: Array = []) -> String
```

Translated text: your mod's data/lang/<code>.json keys merge into the game dictionary.

#### `get_setting`

```gdscript
func get_setting(key: String, default_value = null)
```

Persistent per-mod settings (user://mod_settings/<id>.json) — survive across saves.

#### `set_setting`

```gdscript
func set_setting(key: String, value)
```

#### `hook`

```gdscript
func hook(name: String, handler: Callable, priority: int = 0) -> bool
```

Subscribe to a game hook — the game asks your mod at a key moment and you may change the data (see Pax.HOOKS and docs/modding/en/api-reference.md). hook("law_passed", func(d): log_info("law: " + str(d.law.get("title", ""))))

#### `ask_ai`

```gdscript
func ask_ai(channel: String, prompt: String, data: Dictionary, done: Callable, options: Dictionary = {}) -> bool
```

Ask the AI with your own prompt (see Pax.ask_ai). `done` gets a Dictionary.

#### `log_info`

```gdscript
func log_info(message: String)
```

Print to the Godot output and the in-game dev console (F8), tagged with the mod id.

#### `log_warning`

```gdscript
func log_warning(message)
```

#### `log_error`

```gdscript
func log_error(message)
```

## PaxGame

The running game. You get it in callbacks or as `Pax.game` (null in the launcher).

### PaxGame — Constants

#### `ProvincesScript`

```gdscript
const ProvincesScript = preload("res://src/sim/Provinces.gd")
```

The running game as seen by mods: a stable, documented facade over Main. Get it from callbacks (_world_ready(game) …) or anywhere via `Pax.game` (null while no world is loaded — e.g. in the launcher). STABLE: every method below keeps its name and meaning across game updates. UNSTABLE: `main`, `sim`, `world`, `stock` give raw access to the game's internals (Russian identifiers). Anything is possible there, nothing is promised.

#### `KM_PER_UNIT`

```gdscript
const KM_PER_UNIT := 1000.0
```

1 scene unit = this many kilometres. / Сколько км в единице сцены.

#### `CalendarScript`

```gdscript
const CalendarScript = preload("res://src/core/Calendar.gd")
```

### PaxGame — Properties

#### `main`

```gdscript
var main: Node
```

Raw Main node (src/core/GameRoot.gd). DEPRECATED: goes away in two updates — use the methods of this class (ask in #моддинг if one is missing). The first access writes a warning to the Pax log with the replacement table: docs/modding/MAIN_TO_API.md.

#### `sim`

```gdscript
var sim
```

Simulation (src/sim/PlanetSim.gd): params of home planet, day, leader… UNSTABLE.

#### `world`

```gdscript
var world
```

World chronicle and colonies (src/sim/World.gd). UNSTABLE.

#### `stock`

```gdscript
var stock
```

Resources (src/economy/Resources.gd): stock {body: {resource: amount}}. UNSTABLE.

### PaxGame — Methods

#### `day`

```gdscript
func day() -> int
```

Days since the campaign start. / Дней от старта партии.

#### `date`

```gdscript
func date() -> Dictionary
```

{"year", "month", "day"} of the current in-game date.

#### `date_text`

```gdscript
func date_text() -> String
```

Human-readable date in the player's language style ("03.07.2030", "66 млн лет назад"…).

#### `set_speed`

```gdscript
func set_speed(speed: int)
```

Observation speed: 0 — pause, 1..5 — faster.

#### `body_names`

```gdscript
func body_names() -> PackedStringArray
```

Names of all celestial bodies in the scene (stars, planets, moons, mod bodies).

#### `body`

```gdscript
func body(name: String) -> Dictionary
```

Live body record (edit carefully). Keys: name, genus (star|rock|gas), radius (scene units), r_km, a_km (orbit), node (Node3D), material (ShaderMaterial), parameters (climate 0..1), map, open (discovered), description. {} if not found. (Before 0.24 the keys were Russian.)

#### `body_node`

```gdscript
func body_node(name: String) -> Node3D
```

The body's 3D node (MeshInstance3D) or null.

#### `body_material`

```gdscript
func body_material(name: String) -> Material
```

The body's material (ShaderMaterial for planets/stars) or null. set_shader_parameter freely.

#### `body_params`

```gdscript
func body_params(name: String) -> Dictionary
```

Climate parameters of a body, 0..1: temperature, water, biomass, radiation, atmosphere, urban, magnetic.

#### `set_body_param`

```gdscript
func set_body_param(name: String, param: String, value: float)
```

Change one climate parameter (0..1) and redraw the planet.

#### `province_count`

```gdscript
func province_count(body: String) -> int
```

Number of provinces on a body (0 if it has none). Province ids run from 1.

#### `province_at`

```gdscript
func province_at(body: String, direction: Vector3) -> int
```

Province id at a direction from the body's centre (unit vector; +Y is the north pole). 0 — water or none.

#### `province_direction`

```gdscript
func province_direction(body: String, id: int) -> Vector3
```

Direction from the body's centre to the middle of a province.

#### `province`

```gdscript
func province(body: String, id: int) -> Dictionary
```

Province record: name (player's language), owner ("" — nobody), area_km2, coastal, neighbours (ids), direction.

#### `province_owner`

```gdscript
func province_owner(body: String, id: int) -> String
```

Who owns the province ("" — nobody).

#### `set_province_owner`

```gdscript
func set_province_owner(body: String, id: int, owner: String)
```

Hand a province to a country (its exact name, see `countries`) or to nobody ("").

#### `provinces_of`

```gdscript
func provinces_of(body: String, owner: String) -> Array
```

Ids of all provinces a country owns on a body.

#### `home_body`

```gdscript
func home_body() -> String
```

The player's home body (usually Earth).

#### `focused_body`

```gdscript
func focused_body() -> String
```

Body the camera looks at.

#### `focus`

```gdscript
func focus(name: String, instant: bool = false)
```

Fly the camera to a body.

#### `set_discovered`

```gdscript
func set_discovered(name: String, discovered: bool = true)
```

Mark a body discovered/undiscovered (visible in the scene and lists).

#### `systems`

```gdscript
func systems() -> Array
```

Star systems: [{name, star, position_ly: Vector3, mass (suns), description}]. Index 0 — the Solar System.

#### `body_system`

```gdscript
func body_system(name: String) -> String
```

Name of the star system a body belongs to.

#### `system_bodies`

```gdscript
func system_bodies(system_name: String) -> PackedStringArray
```

Bodies of one star system.

#### `distance_km`

```gdscript
func distance_km(from_body: String, to_body: String) -> float
```

Current distance between two bodies, km (-1 if a body is missing).

#### `distance_ly`

```gdscript
func distance_ly(from_body: String, to_body: String) -> float
```

Same in light years.

#### `galaxies`

```gdscript
func galaxies() -> Array
```

Galaxies you can enter: "млечный" (Milky Way) and neighbours with "key" and "stars_of" in data/galaxy.json.

#### `galaxy`

```gdscript
func galaxy(key: String = "млечный") -> Dictionary
```

A galaxy by key: {"stars": [star…], "radius", "sun", "offset", …}. Star: {id, галактика, name: {ru, en}, class, x, z, famous, system, sv_years}. Deterministic: same for every player.

#### `chart_star`

```gdscript
func chart_star(star_key: String) -> String
```

Build a star's system now (as if the player entered it). `star_key` — "млечный:17". Returns the system name ("" if no such star). Bodies appear as usual (body_created fires).

#### `enter_star`

```gdscript
func enter_star(star_key: String)
```

Fly the camera into a star's system (builds it first if needed; opens its secret if it has one).

#### `charted_stars`

```gdscript
func charted_stars() -> Array
```

Keys of stars whose systems are built in this game ("млечный:17", …).

#### `secrets_found`

```gdscript
func secrets_found() -> Array
```

Ids of galaxy secrets found in this game.

#### `travel_days`

```gdscript
func travel_days(from_body: String, to_body: String, speed_c: float) -> int
```

Days a ship needs at `speed_c` (fraction of light speed, 0.0001..0.99). Minimum 30.

#### `launch_ship`

```gdscript
func launch_ship(from_body: String, to_body: String, speed_c: float, people: float,
```

Launch an ark/ship. `people` are taken from the colony on `from_body` (if any). On arrival at a rocky body: a colony is founded (or grows), the body becomes discovered, a chronicle entry is written, then Pax.ship_arrived / PaxMod._ship_arrived fire. `model`: ковчег | станция | спутник | орбиталка. `data` — anything JSON, returned on arrival. Returns the ship record ({} if a body is missing). Saved in the save file automatically.

#### `ships`

```gdscript
func ships() -> Array
```

Ships in flight (live records).

#### `resources`

```gdscript
func resources(body_name: String) -> Dictionary
```

Resource stock of a colony body: {"humans": 120, "energy": …}. Live dictionary. {} if no colony.

#### `add_resource`

```gdscript
func add_resource(body_name: String, resource: String, amount: float) -> float
```

Add (or subtract with a negative amount) a resource on a colony. Creates the key if missing. Returns the new amount.

#### `colonies`

```gdscript
func colonies() -> PackedStringArray
```

Bodies where the player has colonies.

#### `people`

```gdscript
func people(body_name: String) -> float
```

People living on a body.

#### `add_character`

```gdscript
func add_character(body_name: String, info: Dictionary, portrait: String = "", open_talk: bool = false) -> bool
```

Add a person the player can meet and talk to (the AI plays them using these fields). `info` keys (all text in the player's language): name (required), who (role), lore (backstory), character (personality), age (number), чем_занят (what they do), wants (what they want). `portrait` — optional image path from your mod (png/jpg, any size; 256×320 looks best). The body must have a colony or inhabitants. Returns false if not added.

#### `has_character`

```gdscript
func has_character(name: String) -> bool
```

Is there already a person with this name (met or added)?

#### `factions`

```gdscript
func factions() -> Array
```

All factions (live array of dictionaries: name, type, colour, ours, capital, description…).

#### `player_faction`

```gdscript
func player_faction() -> Dictionary
```

The faction the player leads.

#### `country`

```gdscript
func country() -> String
```

The player's country (or side) name.

#### `countries`

```gdscript
func countries() -> PackedStringArray
```

Names of all other countries and factions.

#### `money`

```gdscript
func money() -> float
```

Money in the treasury (the home body's «деньги»).

#### `add_money`

```gdscript
func add_money(amount: float) -> float
```

Add (or take with a negative amount) money. Returns the new amount.

#### `relation`

```gdscript
func relation(country_name: String) -> float
```

Relations with a country, 0 (hostile) … 1 (ally). -1 if there is no such country.

#### `change_relation`

```gdscript
func change_relation(country_name: String, delta: float) -> float
```

Shift relations with a country by `delta` (clamped to 0..1). Returns the new value or -1.

#### `at_war`

```gdscript
func at_war(country_name: String = "") -> bool
```

Is the player at war — with `country_name`, or with anyone if empty.

#### `declare_war`

```gdscript
func declare_war(country_name: String)
```

Declare war on a country (the war_declared hook runs; a mod may cancel it).

#### `laws`

```gdscript
func laws() -> PackedStringArray
```

Titles of the laws in force.

#### `government_form`

```gdscript
func government_form() -> String
```

Form of government key (see data/politics/forms.json), "" if none.

#### `show_choice`

```gdscript
func show_choice(title: String, text: String, options: PackedStringArray, done: Callable, image: String = "")
```

Show a choice card: title, text, optional picture from your mod, and buttons. `done` gets the index of the chosen option. The card waits for the player.

#### `toast`

```gdscript
func toast(text: String)
```

Short message in the on-screen feed (BBCode allowed).

#### `chronicle`

```gdscript
func chronicle(body_name: String, text: String, tone: String = "neutral", weight: int = 2)
```

Permanent chronicle entry. tone: good | bad | mixed | neutral. weight 1..5 — how important.

#### `tr_key`

```gdscript
func tr_key(key: String) -> String
```

Game translation by key (includes keys added by mods' data/lang/<code>.json).

#### `language`

```gdscript
func language() -> String
```

Current language code: ru, en, de…

#### `add_bottom_button`

```gdscript
func add_bottom_button(text: String, on_pressed: Callable, width: float = 110.0) -> Button
```

Add a button to the bottom bar. Returns it (change icon, tooltip, disable…).

#### `add_window`

```gdscript
func add_window(button_text: String, content: Control, min_size: Vector2 = Vector2(380, 300)) -> PanelContainer
```

Add a window above the bottom bar, opened/closed by its own bottom button, hidden when another game window opens. `content` — any Control you built. Returns the window panel.

#### `hud_layer`

```gdscript
func hud_layer() -> CanvasLayer
```

CanvasLayer of the game HUD — add any Control on top of the game.

#### `scene_root`

```gdscript
func scene_root() -> Node
```

Node to add your own 3D objects to (the 3D world root) (ships, stations, effects). The scene uses a floating origin: to stay attached to a body, add your node as a child of `body_node`.

#### `camera`

```gdscript
func camera() -> Camera3D
```

The game camera.

## Pax

Autoload singleton, available everywhere as `Pax`: signals, data with mods applied, console.

### Pax — Signals

#### `mods_loaded`

```gdscript
signal mods_loaded
```

All mods' code is loaded (instances exist, _mod_loaded called).

#### `world_ready`

```gdscript
signal world_ready(game: PaxGame)
```

A world is fully built (new game or loaded save).

#### `days_passed`

```gdscript
signal days_passed(game: PaxGame, from_day: int, days: int)
```

The world lived `days` days from `from_day`.

#### `body_created`

```gdscript
signal body_created(game: PaxGame, body: Dictionary)
```

A body was created in the 3D scene (record — see PaxGame.body()).

#### `saving`

```gdscript
signal saving(game: PaxGame, mods_state: Dictionary)
```

The game is saving; write into `mods_state`[your_id] if you don't use PaxMod._save_state.

#### `loaded`

```gdscript
signal loaded(game: PaxGame, mods_state: Dictionary)
```

A save was loaded; `mods_state` — what was stored by mods.

#### `ship_launched`

```gdscript
signal ship_launched(game: PaxGame, ship: Dictionary)
```

A ship/ark was launched (record: id, origin, where_to, s_day, until_day, speed_c, humans, data, mod).

#### `ship_arrived`

```gdscript
signal ship_arrived(game: PaxGame, ship: Dictionary)
```

A ship/ark reached its target (a colony is founded or grows before this fires).

#### `data_reloaded`

```gdscript
signal data_reloaded
```

Console command `reload`: data caches cleared.

#### `system_charted`

```gdscript
signal system_charted(game: PaxGame, system_name: String, star: Dictionary)
```

A star's system was built in the galaxy (first entry). `star` — see PaxGame.galaxy().

#### `secret_found`

```gdscript
signal secret_found(game: PaxGame, secret_id: String, body_name: String)
```

A galaxy secret (data/galaxy_secrets.json) was found; `body_name` — where its guests appeared.

#### `log_added`

```gdscript
signal log_added(mod_id: String, text: String, level: String)
```

Any mod log line (for tools).

### Pax — Constants

#### `ProviderScript`

```gdscript
const ProviderScript = preload("res://src/ai/Provider.gd")
```

Pax — the modding API singleton (autoload). Available everywhere as `Pax`. • Signals — subscribe from any script:  Pax.days_passed.connect(func(game, from_day, days): …) • Data with mods applied — Pax.json("res://data/bodies.json"), Pax.texture(…), Pax.model(…) • The running game — Pax.game (PaxGame, null in the launcher) • Dev console — F8 in game or launcher; add commands with Pax.register_command(…) Guide: docs/modding/en/README.md

#### `TerminalScript`

```gdscript
const TerminalScript = preload("res://src/ui/Terminal.gd")
```

#### `ModsScript`

```gdscript
const ModsScript = preload("res://src/mods/Mods.gd")
```

#### `KeyMigrationScript`

```gdscript
const KeyMigrationScript = preload("res://src/save/KeyMigration.gd")
```

#### `DevConsoleScript`

```gdscript
const DevConsoleScript = preload("res://src/mods/DevConsole.gd")
```

#### `ModCheckScript`

```gdscript
const ModCheckScript = preload("res://src/mods/ModCheck.gd")
```

#### `CodeGuardScript`

```gdscript
const CodeGuardScript = preload("res://src/mods/CodeGuard.gd")
```

#### `ModTrustScript`

```gdscript
const ModTrustScript = preload("res://src/mods/ModTrust.gd")
```

#### `ModEventsScript`

```gdscript
const ModEventsScript = preload("res://src/mods/ModEvents.gd")
```

#### `API_VERSION`

```gdscript
const API_VERSION := ModsScript.API_VERSION
```

API version. Bumped only on breaking changes; mods declare "api" in mod.json.

#### `KEYS_MARK`

```gdscript
const KEYS_MARK := ".keys_en"
```

#### `HOOKS`

```gdscript
const HOOKS := {
```

Hooks: the game asks mods at key moments. A handler receives ONE Dictionary and may change it in place (or return a Dictionary to merge into it). Hooks marked [cancel] stop the action when a handler sets d["cancel"] = true. Game records inside (law, faction, research…) use the game's own Russian keys, the same as in data/*.json. Pax.hook("law_passed", func(d): Pax.game.toast("Passed: " + d.law.get("title", ""))) Pax.hook("order_parsed", func(d): if "nuke" in d.order: d.cancel = true)

#### `HOOKS_CANCEL`

```gdscript
const HOOKS_CANCEL := ["order_parsed", "war_declared", "ai_request", "secret_reveal"]
```

Hooks that can be cancelled with d["cancel"] = true.

#### `AI_PER_MINUTE`

```gdscript
const AI_PER_MINUTE := 12
```

How many AI requests one mod may send per real minute: a broken mod must not burn the player's money.

### Pax — Properties

#### `bus`

```gdscript
var bus: Script
```

World event bus (the game's own features subscribe the same way): `Pax.bus.on("step_rules", Callable(self, "_my_step"), 50, "<mod id>")`. Events: step_begin (game, days), step_rules (game, days), loaded (game), hud_built (game), map_layers (game, indicators), map_pushed (game), resource_rows (panel, body), lore (game, out), data_changed (). Lower order runs first. Subscriptions made with the mod id as owner are removed when the mod is unloaded.

#### `features`

```gdscript
var features: Script
```

Feature registry (the game's own features are listed there): a mod declares its feature with `Pax.features.register({"id": "<mod id>", "scripts": ["res://mods/<id>/my_feature.gd"], "optional": true})`; the scripts may define `static func declare_state(fs)` and `static func connect_bus(bus)` — both are called right away if the game is already running. The manifest may also carry "editor" (world editor blocks), "editor_tabs", "sections" (its sections of the world rules file) and "rule_points". See docs/modding, page 10.

#### `state`

```gdscript
var state: Script
```

Feature state registry: what features keep in the game (save, multiplayer, time machine). Read a declared value with `Pax.state.value(game.model.features, "<key>")`; declare it in your feature script's `static func declare_state(fs)` with `fs.declare(key, default, {"personal": false, "rollback": "keep", "epoch": "keep"})`.

#### `rule_points`

```gdscript
var rule_points: Script
```

Rule points — places where the game asks the world for its own formula (data/rule_points.json). A mod adds its points with rule_points.patch.json or with "rule_points" in its feature manifest; the world editor then offers them to the author. `Pax.rule_points.all()` lists the points and the names a formula sees there.

#### `game`

```gdscript
var game: PaxGame
```

The running game or null (launcher, main menu before a world exists).

#### `instances`

```gdscript
var instances
```

Loaded mod code instances by id.

#### `log_lines`

```gdscript
var log_lines: Array
```

Recent log lines [{mod, text, level}] — shown in the dev console.

#### `events`

```gdscript
var events
```

Events and decisions from data/mod_events.json (no-code modding). / События и решения модов.

#### `voxel`

```gdscript
var voxel
```

Voxels for mods: models from data, voxel planets and terrain, provinces on them (see PaxVoxel in the reference).

#### `terminals`

```gdscript
var terminals
```

### Pax — Methods

#### `enable_mods`

```gdscript
func enable_mods()
```

Called when the game starts (license checked). / Зовут при входе в игру.

#### `sleep_mods`

```gdscript
func sleep_mods()
```

#### `terminal_hide`

```gdscript
func terminal_hide(mod_folder: String, window: Control)
```

#### `terminal_return`

```gdscript
func terminal_return(mod_folder: String) -> Control
```

#### `pty_create`

```gdscript
func pty_create() -> Node
```

#### `pty_release`

```gdscript
func pty_release(p: Node)
```

#### `code_was_run`

```gdscript
func code_was_run() -> bool
```

#### `reload_mods`

```gdscript
func reload_mods(force_code := false)
```

Re-read mods and apply toggles/order right away: data caches are cleared, code of disabled mods is unloaded (_mod_unloaded, then freed), newly enabled mods are loaded. The launcher calls this when you tick a mod — no restart needed. force_code: reload code even if the version did not change (F6 in game — for modders).

#### `world_rule`

```gdscript
func world_rule(point: String, default_value: float, seen: Dictionary = {}) -> float
```

Ask the world for its own value at a rule point. Returns `default_value` unless the world's rules (data/world_formulas.json → "rules") define a formula for `point`; `seen` — the values that formula may read.

#### `json`

```gdscript
func json(path: String, default_value = null)
```

Game JSON with all enabled mods' replacements and patches. Returns a deep copy.

#### `text`

```gdscript
func text(path: String) -> String
```

Text file with mods' replacements/appends (prompts, news, markdown).

#### `exists`

```gdscript
func exists(path: String) -> bool
```

Does the file exist in the game or any enabled mod?

#### `resolve`

```gdscript
func resolve(path: String) -> String
```

Final path of a file after mod overrides (the last mod that has it wins).

#### `list_files`

```gdscript
func list_files(folder: String) -> PackedStringArray
```

File names in a game folder merged with the same folder of every enabled mod.

#### `texture`

```gdscript
func texture(path: String) -> Texture2D
```

#### `sound`

```gdscript
func sound(path: String) -> AudioStream
```

#### `model`

```gdscript
func model(path: String) -> Node3D
```

#### `shader`

```gdscript
func shader(path: String) -> Shader
```

#### `mods`

```gdscript
func mods() -> Array
```

Enabled mods' manifests in load order.

#### `has_mod`

```gdscript
func has_mod(mod_id: String) -> bool
```

Is a mod with this id enabled? Use for optional integration between mods.

#### `get_mod`

```gdscript
func get_mod(mod_id: String) -> PaxMod
```

Code instance of another mod (or null) — call its public methods for cross-mod APIs.

#### `tr_key`

```gdscript
func tr_key(key: String, args: Array = []) -> String
```

Translation by key with %s args. Works in launcher and game.

#### `log_line`

```gdscript
func log_line(mod_id: String, message: String, level: String = "info")
```

#### `hook`

```gdscript
func hook(name: String, handler: Callable, priority: int = 0) -> bool
```

Subscribe to a hook (names — see [constant HOOKS]). Higher `priority` runs first. Returns false for an unknown hook name.

#### `hooks`

```gdscript
func hooks() -> Dictionary
```

All hook names with their descriptions (for tools and the console).

#### `ask_ai`

```gdscript
func ask_ai(channel: String, prompt: String, data: Dictionary, done: Callable, options: Dictionary = {}) -> bool
```

Ask the AI with your own prompt. The game adds the world's lore, rules and the player's language, counts the cost under channel "mod_<id>_<channel>" and calls `done` with the parsed JSON answer (empty Dictionary — no AI, error or limit). Pax.ask_ai("oracle", "You are an oracle… Return ONLY JSON: {\"prophecy\": \"…\"}", {"country": Pax.game.player_faction().get("name", "")}, func(a): print(a.get("prophecy", ""))) Your prompt should end with the JSON you expect. Returns false if the request was not sent.

#### `register_condition`

```gdscript
func register_condition(name: String, check: Callable)
```

Add a condition keyword for data/mod_events.json. `check` gets (value, game) and returns bool. Pax.register_condition("my_mod_winter", func(v, game): return game.date().month in [12, 1, 2])

#### `register_effect`

```gdscript
func register_effect(name: String, apply: Callable)
```

Add an effect keyword for data/mod_events.json. `apply` gets (value, game). Pax.register_effect("my_mod_spawn_ark", func(v, game): game.launch_ship(…))

#### `fire_event`

```gdscript
func fire_event(id: String) -> bool
```

Fire an event from data/mod_events.json by id right now (ignores its conditions and chance).

#### `register_command`

```gdscript
func register_command(name: String, handler: Callable, help: String = "")
```

Add a dev-console command. `handler` receives PackedStringArray args and may return a String. Pax.register_command("spawn_ark", func(args): return "ok", "spawn_ark <star> — launch an ark")

#### `run_command`

```gdscript
func run_command(line: String) -> String
```

#### `pty_`

```gdscript
func pty_отпустить(p: Node)
```

#### `pty_`

```gdscript
func pty_создать() -> Node
```

## PaxVoxel

Voxels for mods, available as `Pax.voxel`: models from data, voxel planets and terrain, provinces on them.

### PaxVoxel — Constants

#### `ProvinceMapScript`

```gdscript
const ProvinceMapScript = preload("res://src/sim/Provinces.gd")
```

Voxels for mods: `Pax.voxel`. Voxel worlds, destructible planets and models built from data. The game itself does not use voxels; this is a toolbox for mods. Models (`model`, `model_mesh`) work everywhere. Terrain and planets need the "voxel" component (Voxel Tools by Zylann, MIT): put `"components": ["voxel"]` into mod.json — the launcher installs it and the game loads it before your code, so your scripts may use the Voxel* classes by name.

#### `ModsScript`

```gdscript
const ModsScript = preload("res://src/mods/Mods.gd")
```

#### `MODEL_LIMIT`

```gdscript
const MODEL_LIMIT := 96
```

#### `CLOSED_ONES`

```gdscript
const CLOSED_ONES := ["VoxelStream", "VoxelVoxLoader", "VoxelBlockSerializer", "VoxelSaveCompleteTracker", "VoxelEngineUpdater"]
```

#### `SHADER`

```gdscript
const SHADER := "res://shaders/voxel_planet.gdshader"
```

### PaxVoxel — Methods

#### `library_path`

```gdscript
static func library_path() -> String
```

#### `available`

```gdscript
func available() -> bool
```

True when the voxel component is installed (it may still be not loaded — see `enable`).

#### `ready`

```gdscript
func ready() -> bool
```

True when the Voxel* classes are loaded and usable.

#### `enable`

```gdscript
func enable() -> bool
```

Load the voxel component now. The game does it itself for mods with `"components": ["voxel"]` in mod.json. Returns false if the component is not installed.

#### `create`

```gdscript
func create(type: String) -> Object
```

Create an object of the voxel library by class name: "VoxelLodTerrain", "VoxelBuffer", "VoxelMesherTransvoxel", "VoxelGeneratorGraph", "ZN_FastNoiseLite"… null if the component is missing or the class is not part of it. File-stream classes are not available to mods.

#### `constant`

```gdscript
func constant(type: String, name: String) -> int
```

Integer constant of a voxel class, e.g. constant("VoxelTool", "MODE_REMOVE"). -1 if unknown.

#### `model_grid`

```gdscript
func model_grid(data: Dictionary) -> Dictionary
```

Fill a voxel grid from a model description (see `model`). Returns {"size": Vector3i, "cells": PackedByteArray (palette index per cell, 0 = empty), "palette": Array[Color]}.

#### `model_mesh`

```gdscript
func model_mesh(data: Dictionary) -> ArrayMesh
```

Build a mesh from a voxel model described by data — no modelling tools needed: [codeblock] {"size": [32, 12, 32], "palette": ["#d8dce4", "#f2b33d", "#5b7fc7"], "shapes": [{"type": "torus", "center": [16, 6, 16], "radius": 12, "tube": 1.6, "color": 1}, {"type": "cylinder", "center": [16, 6, 16], "radius": 2.2, "height": 10, "color": 2}, {"type": "line", "from": [4, 6, 16], "to": [28, 6, 16], "color": 3}], "voxels": [[16, 11, 16, 2]]} [/codeblock] Shapes: box (from, to), sphere, cylinder, torus (center, radius, tube, axis), line (from, to, width); "color" is a palette index starting at 1, 0 carves. Up to 96 cells per side. Works without the voxel component. Vertex colours carry the palette.

#### `model`

```gdscript
func model(data: Dictionary) -> MeshInstance3D
```

Same as `model_mesh`, but returns a ready MeshInstance3D. "scale" in data sets the size of one voxel (default 1.0).

#### `planet`

```gdscript
func planet(params: Dictionary = {}) -> Node3D
```

A voxel planet: a sphere with relief, levels of detail, optionally editable (`dig`, `fill`). Needs the voxel component; returns null without it. params: radius (voxels, default 300), relief (height of hills in voxels, default 24), noise {seed, frequency, octaves}, heightmap (Image, 2:1, laid out like the game's planet maps; replaces noise), lods (2..8, default 5), editable (bool), color, material (Material), collisions (bool), occlusion (bool, default true — the far side of the planet is not drawn, see `occlusion`). Add it to the scene and attach a viewer to your camera: `viewer`.

#### `viewer`

```gdscript
func viewer(target: Node3D, distance: float = 2048.0) -> Node
```

Attach a voxel viewer to a camera (or any Node3D): terrain loads and refines around it. Without a viewer a voxel world stays empty.

#### `occlusion`

```gdscript
func occlusion(node: Node, enabled: bool = true)
```

Turn on occlusion culling for the window the node is shown in, so voxel planets do not draw their far side (planet() puts an invisible sphere inside each planet). viewer() calls it for you. Godot performs it in the main game window; inside a SubViewport it has no effect.

#### `dig`

```gdscript
func dig(terrain: Node, position: Vector3, radius: float)
```

Carve a sphere out of voxel terrain (a crater, a tunnel). `position` is in the terrain's local space. The terrain must be editable (planet({"editable": true})).

#### `fill`

```gdscript
func fill(terrain: Node, position: Vector3, radius: float)
```

Add a sphere of matter to voxel terrain (a mountain, a plug). See `dig`.

#### `raycast`

```gdscript
func raycast(terrain: Node, from: Vector3, direction: Vector3, max_distance: float = 4096.0) -> Dictionary
```

Cast a ray against voxel terrain (terrain local space). Returns {} on miss or {"position": Vector3, "normal": Vector3, "distance": float}.

#### `body_heightmap`

```gdscript
func body_heightmap(body: String) -> Image
```

Heightmap of a game body for `planet`: built from the body's maps (mods included) — land above the sea, brighter ground higher. Returns null if the body has no colour map.

#### `body_material`

```gdscript
func body_material(body: String, params: Dictionary = {}) -> ShaderMaterial
```

Material for a voxel planet that shows a game body: its colour map and, on top, its provinces painted by their owners — the same data the game map uses, so presets and scenarios made in the preset editor look right on the voxel world. params: provinces (0..1, how strongly owners tint the land, default 0.55), borders (bool), color (fallback colour). Call `refresh_provinces` after ownership changes.

#### `refresh_provinces`

```gdscript
func refresh_provinces(material: ShaderMaterial)
```

Re-read province ownership into a material made by `body_material` (call it from the `province_captured` hook or after you change owners).

#### `body_planet`

```gdscript
func body_planet(body: String, params: Dictionary = {}) -> Node3D
```

A voxel copy of a game body (Earth, Mars, a mod planet): its continents as real relief, its colours and its provinces. params as in `planet` plus those of `body_material`; "relief" defaults to 6% of the radius.

#### `body_planets`

```gdscript
func body_planets(body: String) -> Array
```

Voxel copies of a body made by `body_planet` that are still alive.

#### `pick_province`

```gdscript
func pick_province(body: String, what) -> int
```

Pick a province for scripts and events: an id, "random" (any land province of the body), or a country name (a random province it owns). 0 if nothing fits.

#### `crater`

```gdscript
func crater(body: String, province, radius_km: float = 300.0) -> int
```

Blow a crater into every voxel copy of a body, right over a province (see `pick_province`). radius — in km of the real planet; it is scaled to each copy. Returns the province id (0 — none). The same is available to no-code events as the effect "crater" (кратер).

#### `place`

```gdscript
func place(terrain: Node3D, transform: Transform3D)
```

Move or rotate a voxel planet made by `body_planet`: sets its transform and keeps its map material aligned. Setting `position` directly leaves the colours behind.

#### `direction`

```gdscript
func direction(position: Vector3) -> Vector3
```

Direction from the planet's centre for a point in the terrain's local space (feed it to `province_at` or to PaxGame.province_at).

#### `province_at`

```gdscript
func province_at(body: String, position: Vector3) -> int
```

Province id of a game body under a point of its voxel copy (terrain local space). 0 — water or none.

#### `province_position`

```gdscript
func province_position(body: String, id: int, radius: float) -> Vector3
```

Point on a voxel planet of the given radius above the centre of a province (terrain local space) — to place a city, a label or a camera target.
