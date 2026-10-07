# 03 · Planets, moons, stars and star systems

[← Back to the guide](README.md) · Schema: [`bodies.schema.json`](../schemas/bodies.schema.json)

Everything in the sky comes from `data/bodies.json`. A mod adds or changes bodies with
`data/bodies.patch.json`. Distances are **real kilometres**; 1 scene unit = 1000 km.

## A body

```json
{
  "name": "Тея",
  "genus": "rock",
  "r": 4100,
  "a": 285000000,
  "angle": 40,
  "open": true,
  "sid": 7.3,
  "description": "The lost planet.",
  "parameters": {"temperature": 0.3, "water": 0.35, "biomass": 0.05, "radiation": 0.2,
                 "atmosphere": 0.4, "urban": 0.0, "magnetic": 0.3},
  "map": "res://mods/example_theia/planets/theia",
  "map_sea": 0.52
}
```

| Key | Meaning |
|---|---|
| `имя` | **Id** and default name. Display names per language: `"тело_<имя>"` keys in `data/lang/<code>.json`. |
| `род` | `камень` rocky (colonies, provinces, climate) · `газ` gas giant · `звезда` star |
| `r` | Radius, km (Earth 6371, Moon 1737, Jupiter 69911, Sun 696000) |
| `a` | Orbit radius, km, around the parent (`спутник`) or the system centre. Earth: 149 598 000. `0` — at the centre. |
| `угол` | Starting position on the orbit, degrees. |
| `период` | Orbital period, days. Around a star it is computed (Kepler, star mass); **set it for moons** of new planets. |
| `спутник` | Parent body id. Moons, and planets of a secondary star. The parent must be listed **before**. |
| `система` | Star system name (see below). Empty — the Solar System. Moons inherit it. |
| `открыт` | Discovered at start. Undiscovered bodies are hidden until explored or reached by a ship. |
| `параметры` | Climate scales 0..1 — they drive both the simulation and the planet shader. `temperature` ~0.35 is Earth-like; `urban` > 0.01 lets a colony appear. |
| `цвет_породы` | `[r, g, b]` rock colour for bodies without maps. |
| `кольца` | `[inner km, outer km]` from the centre. |
| `полос`, `цвета` | Gas giants: band count and three `[r,g,b]` colours. |
| `провинций`, `провинции_имена` | Provinces for rocky bodies (see below). |
| `дом` | The player's home. Only one body — don't set it unless you replace Earth. |

## Textures and relief

`"map"` names a set of equirectangular maps (2:1, e.g. 2048×1024 or 4096×2048):

| File | Content |
|---|---|
| `<name>_albedo.png` / `.jpg` / `.webp` | Surface colour. |
| `<name>_height.png` | Height, grayscale: white = high. Enables real relief and sea level (`карта_море`, 0..1). |
| `<name>_ocean.png` | Water mask: **white = water**. Gives specular oceans. |

- A short name (`"mars"`) means the game's `res://maps/mars_albedo.jpg`.
- A path with `/` means your files: `"res://mods/my_mod/planets/xeno"` → `xeno_albedo.png`, `xeno_height.png`…
- Missing files are fine: without albedo the surface is procedural, without height it is flat.
- Mod images are read at runtime; no Godot import needed.
- `"height_rainbow": 1` colours height like a rainbow (airless, scientific look).

Tip: NASA/USGS maps of real bodies, planet generators (e.g. *Planet Maker*) or an image model can produce maps.
The example mod generates them with 40 lines of Python + numpy (see `example_theia`).

## Changing existing bodies

```json
{"bodies": {
  "$edit":   [{"$match": {"name": "Марс"}, "parameters": {"water": 0.4, "atmosphere": 0.5}, "map": "res://mods/green_mars/mars"}],
  "$remove": [{"name": "Седна"}]
}}
```
Removing bodies the story refers to (Earth, the Moon, Mars) can break events — prefer changing them.

## Star systems

A mod can add systems anywhere in the galaxy — one neighbour star or a whole cluster.

```json
{
  "systems": {"$append": [{
    "name": "Альфа Центавра",
    "star": "Альфа Центавра A",
    "situation_sv_years": [-1.64, -1.37, -3.84],
    "mass": 1.1,
    "description": "The nearest star system."
  }]},
  "bodies": {"$append": [
    {"name": "Альфа Центавра A", "genus": "star", "system": "Альфа Центавра", "r": 851000, "a": 0, "open": true,
     "shader_parameters": {"core": [1.0, 0.95, 0.8], "edge": [1.0, 0.62, 0.25]}},
    {"name": "Проксима Центавра", "genus": "star", "satellite": "Альфа Центавра A", "r": 107000,
     "a": 1940000000000, "period": 199800000, "open": true},
    {"name": "Проксима b", "genus": "rock", "satellite": "Проксима Центавра", "r": 7160, "a": 7260000, "period": 11.19,
     "map": "res://mods/example_alpha_centauri/planets/proxima_b", "open": true}
  ]}
}
```

How it works:

- The **Solar System is always system 0** at `[0, 0, 0]`; you never list it.
- `положение_св_лет` — position relative to the Sun in light years. Real coordinates work: nearby stars are a few ly away,
  the Pleiades ~444 ly.
- Bodies choose a system with `"system"`; moons and planets of secondary stars inherit it through `"satellite"`.
- `масса` (in Suns) sets how fast top-level planets orbit (Kepler). Give moons an explicit `"period"`.
- **Light** comes from the body's own star: a planet of Proxima is lit by Proxima even though the system's main star is A.
- The camera: *system view* frames the focused body's system; zooming out further opens the galaxy map (give your star a `"system"` entry in `galaxy.json` to put it there).
- The Sun's ageing (red giant, habitable zone drift) only affects the Solar System.
- **Asteroid belts** can belong to a system: `"belts": {"$append": [{"name": "…", "system": "Альфа Центавра", "inner": …}]}`.

A cluster is just many systems. Generate them with a script or in your mod's code before the world is built
(write the patch file), or keep a hand-made list — each system costs a few bodies.

### The galaxy: every star has a system

Zooming out past a system opens the **galaxy map** (key U): the Milky Way with 1000 stars, and further out the
Local Group. Andromeda is a map of its own — click it. Any star can be entered: the game builds its system on
the first visit and keeps only "this star is charted" in the save (generation is deterministic).

- `data/galaxy.json` — seed, star count, arms, known stars (`l`, `b`, `св_лет`), the Local Group. A neighbour with
  `"key"` and `"stars_of"` becomes its own enterable galaxy (see Andromeda). A known star with `"system"` points to
  a ready system from `bodies.json` (like the Sun or your mod's system).
- `data/galaxy_systems.json` — real planets of known stars, keyed by the star's English name: `r_земли`, `a_ае`, `K`,
  `вода`, `атм`, `жизнь`, companion stars in `"stars"`. A known star without a record gets generated planets.
- `data/galaxy_secrets.json` — easter eggs hidden in stars: own planet (`"planet"` with an internal `"name"`; its
  translation is the lang key `тело_<имя>`), guests in orbit (`"guests"`) and on the ground (`"on_earth"`, kinds from
  `data/guests.json`). Without `"star"` the game picks one by class and place (`ядро`, `рукав`, `окраина`).
  Texts: `гал_тайна_<id>` and `гал_тайна_<id>_текст`.

```json
{"mysteries": {"$append": [{"id": "my_secret", "galaxy": "млечный", "where": "окраина", "class": "K",
  "planet": {"name": "Моя планета", "type": "умеренная", "r_земли": 1.0, "a_ае": 0.8, "water": 0.5, "atm": 0.6},
  "guests": ["monolith_servers"]}]}}
```

In code: `game.galaxy()`, `game.galaxies()`, `game.chart_star("млечный:17")`, `game.enter_star(...)`,
`game.charted_stars()`, `game.secrets_found()`; callbacks `_system_charted`, `_secret_found`; the hook
`system_generated` lets you edit or add bodies of a generated system before they are created.

### Arks between stars

Travel is part of the game, not only of mods: `game.launch_ship(from, to, speed_c, people)` — see
[04 Code → Ships and arks](04-code.md#ships-and-arks). At 0.1 c Proxima b is ~45 years away; the ark flies
visibly across space, and on arrival founds a colony.

## Shaders and models

### Own shader

```json
{"name": "Pulsar-7", "genus": "star", "r": 20, "a": 0, "system": "Vela",
 "shader": "res://mods/my_mod/shaders/pulsar.gdshader",
 "shader_parameters": {"beam_color": [0.6, 0.8, 1.0], "spin": 30.0, "noise": "res://mods/my_mod/textures/noise.png"}}
```

- `шейдер` replaces the body's material shader (a Godot `shader_type spatial` shader). Start from the game's
  `shaders/planet.gdshader`, `star.gdshader` or `gas.gdshader` to keep lighting and climate uniforms.
- `шейдер_параметры` sets uniforms: numbers; `[r,g,b]` becomes `vec3` or a `source_color`; `[x,y,z,w]` a `vec4`;
  a string path becomes a texture (`sampler2D`).
- The game still sets climate uniforms (`temperature`, `water`, …) on rocky bodies — declare them to use them.
- Built-in star uniforms: `core`, `edge` (colours). Planet: `relief`, `map_albedo`, `use_map`, `rock_tint`, … (see the shader files).

Change materials from code at any time: `game.body_material("Марс").set_shader_parameter("relief", 0.03)`.

### Model instead of a sphere

`"mesh": "res://mods/my_mod/models/asteroid.glb"` — any glTF/GLB (1 unit = the body radius). Good for asteroids,
artificial worlds, Dyson swarms, derelicts.

## Provinces

Rocky bodies are divided into provinces (the political map, wars, colonisation). For bodies from mods the game
**generates 24 provinces automatically** (cached in `user://mod_cache/regions/`). Control it:

```json
{"name": "Тея", "provinces_count": 12,
 "provinces_names": [{"en": "Wind Valley", "ru": "Долина Ветров"}, "Red Hills", "…"]}
```
Unnamed ones become *Regio I, II…*. For hand-made borders put `data/regions/тело_<name>.json` + `.bin` into the mod
(format: see `tools/провинции/без_карт.py` in the game source).

## Checklist

- `check <id>` finds: missing parents, unknown systems, texture sets without `_albedo`, missing shader/model files.
- `json res://data/bodies.json` shows the merged list.
- `eval game.body_names()`, `eval game.systems()` in a running game.
