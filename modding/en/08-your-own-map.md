# 08 · Your own world map

A mod can replace Earth's province layout with its own — for alternate history, fantasy or another planet. You draw one image; the studio builds the game files.

## The image

- **Size**: width exactly twice the height — from 512×256 to 8192×4096. 2048×1024 or 4096×2048 work well.
- **Projection**: equirectangular. Left edge is 180°W, right edge 180°E, top is the north pole.
- **Each province is its own colour.** The same colour in two places is one province in two pieces.
- **Water** is black `#000000` or transparency.
- Save as PNG. Turn anti-aliasing off if you can; if some is left, the studio removes the tiny half-tone specks on borders.

## Legend (optional)

A file with the same name and `.json` extension next to the image — names and countries by colour:

```json
{
  "#c82828": {"name": {"ru": "Красная марка", "en": "Red March"}, "country": "RED"},
  "#28c828": {"name": "Green Dale", "country": "GRN"}
}
```

Without a legend provinces are called "Province 1", "Province 2"…

## Building

In the mod studio select the image in the file list and press **🗺** above the list. The mod gets:

| File | Contents |
|---|---|
| `data/regions2.json` | provinces: names, country, colour, area, centre, neighbours, coast |
| `data/regions2.bin` | the map: province number in every pixel |
| `data/regions2_grow.bin` | build-up order inside each province |

Area is computed on a real sphere, neighbours come from shared borders, and a province may cross the date line.

## Next

1. Enable the mod and open the **preset editor**: paint provinces to countries and save the preset — ship it in your mod's `presets/` or in the store.
2. To make the world look like yours, replace the planet's look: your own Earth textures or a new body — [03 Planets and stars](03-planets-and-stars.md).
3. Test with "▶ Play with the mod". Without a preset for your map, countries get land around their capitals.

A mod with its own map changes the game for every country, so every player needs it in multiplayer.

## Planet brush: paint the world yourself

The **🖌** button in the studio opens a window where the world is painted with a brush — on the flat map or right on
the globe.

- **Paint with:** water, plains, forest, desert, mountains, snow and ice, tundra. Brush size is a slider.
- **"New continents"** gives a starting point: random continents with a climate by latitude. It is easier to begin
  from than an empty ocean. **"Flood everything"** is a blank sheet. **"Undo stroke"** goes back up to eight steps.
- **Globe:** the left button paints, the right one spins, the wheel zooms. The brush is round on the sphere — it does
  not stretch near the poles.
- **"Save into the mod"** writes the planet's look (`maps/<map>_albedo.jpg`, `_ocean.jpg`) and splits the painted land
  into as many provinces as you asked for (`data/regions2.*` for Earth, `data/regions/<map>.*` for another body).
  The drawing is saved into the mod (`planet_paint_<map>.png`) and opens again when you come back.

The **"Planet (map)"** field is the body's `"map"` field from `data/bodies.json`: `earth` is Earth; for your own
planet use its map name. Provinces are named "Province N"; hand them to countries in the preset editor. Every save
splits the land anew, so mark up the preset once the map is final.

## A map from Azgaar

A world from [Fantasy Map Generator](https://azgaar.github.io/Fantasy-Map-Generator/) is imported directly — no images,
no recolouring (tested on version 1.153).

1. In the generator: left menu → **Export** → **Export To JSON** → **full**. A `.json` file is downloaded.
2. Put it into the mod folder, select it in the studio file list and press **🗺**.

What you get:

- `data/regions2.*` — the map: every Azgaar province becomes a game province with the same name. Land without
  a province is grouped into "Wildlands". Lakes and ocean are water. The position on the planet comes from the Azgaar
  map coordinates (Options → Geography), so poles and the equator stay where they were.
- `presets/<world>/` — a **ready preset**: the Azgaar states with their lands, capitals, population and colours, the
  world's year and era, and rules for the AI ("this is an invented world, there are no Earth countries here"). The mod
  is playable right away: enable it, pick the preset in the menu and choose a state. Write the texts — description,
  lore and goals of the states — in the preset editor; a repeated import keeps what you wrote.
- `maps/earth_albedo.jpg`, `maps/earth_ocean.jpg` — the look of the planet: the biomes, mountains, snow and seas of
  your world instead of Earth's continents — on the globe and under the provinces.
- `data/azgaar_states.json` — a reference: states, their capitals and province ids, all towns with coordinates and
  population. The game does not read this file; it is for you and the AI agent.

The `.map` file (Save → machine) will not do: it holds no cell borders, the generator rebuilds them on load. The JSON
export is required. If you prefer an image: the **Provinces** layer without labels and relief, a 2:1 canvas,
**Export → .png**, recolour the ocean to black — and the same **🗺** button.
