# Modding Pax Universe

Pax Universe is built to be modded **all the way down**. A mod can add a planet with its own textures and
relief, a whole star system or a cluster of stars with arks flying between them, new characters with
portraits, events, crises, megaprojects, music, a language, new UI windows, custom shaders and 3D models —
or entirely new gameplay written in GDScript with full access to the game.

No tools to install: a mod is **a folder with a `mod.json`**. Edit it in any text editor; the launcher picks it up.

> Русская версия: [../ru/README.md](../ru/README.md)

---

## Five-minute start

1. **Create a mod.** In the game press **F8** (dev console) and type:
   ```
   new my_first_mod My First Mod
   ```
   A folder `mods/my_first_mod/` appears with `mod.json`, `main.gd`, translations and an `AGENTS.md` for AI
   assistants. (Without the game running: `godot --headless --path <game> -- --new-mod my_first_mod`.)

2. **Add a planet.** Create `mods/my_first_mod/data/bodies.patch.json`:
   ```json
   {
     "bodies": {"$append": [{
       "name": "Nibiru", "genus": "rock", "r": 5200, "a": 420000000, "angle": 75, "open": true,
       "parameters": {"temperature": 0.2, "water": 0.3, "atmosphere": 0.4, "biomass": 0.0,
                      "radiation": 0.3, "urban": 0.0, "magnetic": 0.2}
     }]}
   }
   ```

3. Launcher → **Mods** shows your mod, enabled (if the launcher was open, click *Mods* again). Play — Nibiru orbits between Mars and Jupiter.

4. **Check it:** `check my_first_mod` in the F8 console, or
   `godot --headless --path <game> -- --check-mods my_first_mod` (exit code 0 = no errors).

5. **Share it:** `pack my_first_mod` → a zip in `user://mods_dist`. Players drop the zip into their `mods` folder.

---

## What a mod can do — and where to read

| I want to… | How | Guide |
|---|---|---|
| Change numbers, texts, lists of the game | `data/<file>.patch.json` | [02 Data](02-data.md) |
| Add or change planets, moons, stars | `data/bodies.patch.json` + textures | [03 Planets & stars](03-planets-and-stars.md) |
| Add a star system / a cluster | `"systems"` in `bodies.patch.json` | [03](03-planets-and-stars.md#star-systems) |
| Launch arks between stars | `game.launch_ship(…)` | [04 Code](04-code.md#ships-and-arks) |
| Own shader for a planet or star | `"shader"` + `"shader_parameters"` | [03](03-planets-and-stars.md#shaders-and-models) |
| New characters with portraits | `game.add_character(…)` | [05 Recipes](05-recipes.md#characters) |
| Events, crises, megaprojects, factions, leaders | patches of `world_events`, `crises`, `projects`, `factions`, `leaders` | [05 Recipes](05-recipes.md) |
| Music, ambient sounds, 3D models | `music/`, `ambient/`, `models.json` | [05 Recipes](05-recipes.md#music-and-sound) |
| A new language | `data/lang/<code>.json` | [05 Recipes](05-recipes.md#a-new-language) |
| New gameplay, UI windows, anything | `main.gd` (`extends PaxMod`) | [04 Code](04-code.md), [API reference](api-reference.md) |
| Change what the game does at a key moment (order, war, law, election, research, report) | `hook("law_passed", func(d): …)` | [Hooks](hooks.md) |
| Ask the AI with your own prompt | `ask_ai("channel", prompt, data, func(answer): …)` | [04 Code](04-code.md#ai-from-a-mod) |
| Events with options and paid decisions — no code | `data/mod_events.patch.json` | [07 Events and decisions](07-events-and-decisions.md) |
| Your own world map: provinces from an image | a "colour = province" PNG + the 🗺 button in the studio | [08 Your own map](08-your-own-map.md) |
| A destructible voxel planet, models from JSON, your own game | `"components": ["voxel"]` + `Pax.voxel` | [09 Voxels](09-voxels.md) |
| Live inside the world step, keep your state in the save, a block in the world editor, your own rule point | `Pax.bus`, `Pax.features`, `Pax.world_rule` | [10 Features and the world bus](10-features-and-world-bus.md) |
| Find which file holds what | catalog of every data file and its schema | [Data catalog](data-catalog.md) |
| Change what the AI narrator knows | `data/prompt_*.append.txt` | [05 Recipes](05-recipes.md#teaching-the-ai) |

Structure, load order, dependencies, zips: [01 Structure](01-structure.md).
Console, validator, packaging, AI assistants: [06 Tools](06-tools.md).

## Learn from working examples

- **`example_theia`** — a planet with its own albedo/height/ocean maps, a window in the bottom bar, a chronicle
  entry every few time skips and state saved into the save file. ~60 lines of commented code.
- **`example_alpha_centauri`** — a second star system 4.37 light years away (three stars, the eyeball planet
  Proxima b) and an **Arks** window that launches interstellar arks from any colony.

They live in `mods/` of the game source, and in `docs/modding/examples/` of the released game
(copy one into `mods/` to try it).

## Rules that save hours

1. **Patch, don't copy.** Never copy a whole game file into your mod — use `*.patch.json`. Then your mod works
   together with others and survives game updates.
2. **Data keys are Russian** (`"bodies"`, `"name"`, `"genus"`). The game is developed in Russian. Copy keys exactly
   from the game's `data/*.json`; the [schemas](../schemas) and this guide explain every one in English.
3. **Player-visible text goes to `data/lang/`**, at least `en.json` and `ru.json`. Never hard-code it.
4. **GDScript here is strict**: `var x := untyped_value` is a compile error. Write `var x: float = d["a"]`.
5. **Check before sharing**: `--check-mods`.

## Using an AI assistant (Claude Code, Cursor, Copilot…)

Every mod created with `new` contains **`AGENTS.md`** (and `CLAUDE.md` pointing to it): where everything is, the
rules above, and the command to verify. Open the mod folder next to the game folder and ask:
*"Add a red dwarf system 6 light years away with two rocky planets and a crisis when the star flares"* —
then run `--check-mods` and let the assistant fix what it reports.
