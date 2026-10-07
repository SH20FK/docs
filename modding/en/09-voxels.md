# 09. Voxels: destructible worlds and models from data

The game itself does not use voxels — this is a toolbox for mods. With it you can make destructible planets, a voxel
copy of Earth with its provinces, stations and ships without a 3D editor, or even your own game on top of Pax Universe.
Everything is available through `Pax.voxel`. The full list of functions is in the [API reference](api-reference.md),
section PaxVoxel. A live example is the **"🧊 Voxel world"** template in the studio (the `example_voxel` mod).

## Enabling

Add to `mod.json`:

```json
"components": ["voxel"]
```

The launcher downloads the [Voxel Tools](https://github.com/Zylann/godot_voxel) library (Marc Gilleron, MIT, about
10 MB), and the game loads it **before** your code — so your scripts may use the library's classes by name:
`VoxelLodTerrain`, `VoxelBuffer`, `VoxelTool`, `VoxelGeneratorGraph` and the rest. A mod without the component can
still build models from data (see below) — they do not need the library.

## Models from data

A station, a ship, a building is JSON, not a Blender file. The game turns it into a mesh.

```json
{
  "size": [36, 14, 36],
  "palette": ["#d8dce4", "#f2b33d", "#5b7fc7"],
  "shapes": [
    {"type": "torus", "center": [18, 7, 18], "radius": 14, "tube": 1.8, "color": 1},
    {"type": "cylinder", "center": [18, 7, 18], "radius": 2.6, "height": 12, "color": 2},
    {"type": "line", "from": [4, 7, 18], "to": [32, 7, 18], "width": 1, "color": 3}
  ],
  "voxels": [[18, 0, 18, 2]]
}
```

```gdscript
var station: MeshInstance3D = Pax.voxel.model(JSON.parse_string(read_text("models/station.json")))
```

Shapes: `box` (from, to), `sphere`, `cylinder`, `torus` (center, radius, tube, axis), `line` (from, to, width).
`color` is a palette index from one; `0` carves. Up to 96 cells per side. An AI writes such JSON well: ask the studio
terminal to "make a voxel model of an orbital shipyard in the models/station.json format".

## A voxel planet

```gdscript
var planet := Pax.voxel.planet({"radius": 300, "relief": 24, "editable": true})
world.add_child(planet)
Pax.voxel.viewer(camera)            # without a viewer a voxel world does not load
Pax.voxel.dig(planet, point, 20)    # a crater
Pax.voxel.fill(planet, point, 10)   # a mound
var hit := Pax.voxel.raycast(planet, from, direction)  # {position, normal, distance}
```

Parameters: `radius`, `relief` (height of mountains), `noise` ({seed, frequency, octaves}), `heightmap` (your own 2:1
heightmap), `lods` (levels of detail), `editable` (can it be dug), `color` or `material`, `collisions`.

## A copy of a game planet with provinces

```gdscript
var earth := Pax.voxel.body_planet(game.home_body(), {"radius": 200, "editable": true})
```

Relief comes from the body's maps (land above the sea, brighter is higher), colours from its image, and on top —
**provinces in their owners' colours**: the same data the game map uses. So presets and scenarios marked up in the
preset editor, with a map from an image, from Azgaar or with the planet brush look right on the voxel world too.

- `Pax.voxel.province_at(body, point)` — which province is under a point of the voxel planet;
- `Pax.voxel.province_position(body, id, radius)` — a point above the province centre (a city, a label, a camera target);
- `Pax.voxel.refresh_provinces(earth.material)` — repaint after owners change (handy in the `province_captured` hook);
- `Pax.voxel.place(earth, transform)` — move and rotate the planet so the map does not slide off.

Provinces are now open in `Pax.game` as well: `province_count`, `province_at`, `province`, `province_owner`,
`set_province_owner`, `provinces_of`, `province_direction` — for any body.

## Scenarios

A voxel scenario is built from the same bricks as any other:

1. **Map and countries** — a preset (preset editor, [08 Your own map](08-your-own-map.md)).
2. **Story** — no-code events and decisions ([07](07-events-and-decisions.md)). Two effects are there for voxels:
   - `"кратер": {"province": 1368, "radius": 300}` (crater) — a strike on a province on every voxel copy of the body;
     instead of an id use `"случайная"` (random) or a country name (a random province of it); radius in km of the real planet;
   - `"province": {"id": "Франция", "owner": ""}` (province) — change a province's owner (id, `"случайная"` or a country).
3. **Look** — a voxel copy of the planet in the mod's window or in place of the body.

`example_voxel` has a "Meteorite" event: a crater in a random province and a chronicle entry.

## Good to know

- **Saving.** The game does not store voxel worlds. Record what you dug and replay it after loading with
  `_save_state` / `_game_loaded` — the example does exactly that.
- **Files.** Library classes that write to disk (`VoxelStream…`, `VoxelVoxLoader`, `debug_dump_as_scene`,
  `save_modified_blocks`) are closed to mods: the guard will not let them through.
- **Multiplayer.** A voxel mod must be installed by every player of the session. If it only shows a picture and does not
  change the rules, set `"client_only": true` in `mod.json`.
- **Performance.** Generation, meshing and levels of detail run in the library's C++ code on background threads.
  A planet of 200–300 voxels in radius loads in a few seconds. Set `"editable": true` to dig — the planet then loads
  completely, which costs more memory.
- **What is not drawn.** Chunks outside the camera, the inside of the planet and hidden cube faces are never drawn. The
  far side of the planet is culled by an invisible sphere inside it (`planet()` adds it, `"occlusion": false` removes it):
  near the surface that is a quarter fewer chunks. It works in the main game window — `viewer()` turns culling on;
  inside a SubViewport Godot does not perform occlusion culling.
- **Models.** With the component installed, JSON models are built by the library's C++ mesher, which merges neighbouring
  faces of one colour: the example station has a third of the vertices.
