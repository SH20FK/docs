extends PaxMod
## Galaxy tutorial. The data files do most of the work:
##  • data/galaxy.patch.json          — a known star (40 Eridani) and a new galaxy in the Local Group
##  • data/galaxy_systems.patch.json  — real planets and companion stars of 40 Eridani
##  • data/galaxy_secrets.patch.json  — the secret planet Vulcan hidden at 40 Eridani
## This code shows the rest:
##  • hook "system_generated" — edit a star's system before its bodies are created
##  • _system_charted / _secret_found — react when the player enters a star or finds a secret
##  • game.galaxy() / game.chart_star() — read the galaxy map and build a system from code


func _mod_loaded() -> void:
	# Every star of the Sagittarius Dwarf gets a lonely rogue planet far from its star.
	hook("system_generated", func(d: Dictionary) -> void:
		var star: Dictionary = d["star"]
		if str(star.get("galaxy", "")) != "стрелец_кг":
			return
		var system: Dictionary = d["system"]
		(d["bodies"] as Array).append({
			"name": str(system["name"]) + " X", "genus": "rock", "system": str(system["name"]),
			"r": 5000.0, "a": 60.0 * 149597870.7, "angle": 45.0, "open": true,
			"description": tr_key("example_galaxy_бродяга"),
			"parameters": {"temperature": 0.0, "water": 0.3, "biomass": 0.0, "radiation": 0.1,
				"atmosphere": 0.0, "urban": 0.0, "magnetic": 0.1},
			"color_rock": [0.35, 0.38, 0.45]}))
	Pax.register_command("chart", func(args: PackedStringArray) -> String:
		if Pax.game == null:
			return "No world loaded."
		var key := args[0] if args.size() > 0 else "стрелец_кг:0"
		var name := Pax.game.chart_star(key)
		return "Charted: " + name if name != "" else "No such star (use galaxy:id, e.g. млечный:17).",
		"chart <galaxy:id> — build a star's system without flying there")


func _system_charted(_game: PaxGame, system_name: String, star: Dictionary) -> void:
	log_info("charted %s in %s" % [system_name, str(star.get("galaxy", ""))])


func _secret_found(game: PaxGame, secret_id: String, _body_name: String) -> void:
	game.toast(tr_key("example_galaxy_нашли") % game.tr_key("гал_тайна_" + secret_id))
