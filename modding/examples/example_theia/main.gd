extends PaxMod
## Example mod code. Everything a typical gameplay mod needs, in ~60 lines:
## a console command, a window in the bottom bar, reacting to time, a chronicle entry,
## changing a planet's material, and state that survives save/load.

const BODY := "Тея"   # body id from data/bodies.patch.json ("имя")

var observations := 0
var _info: Label


# Called once when the game starts (launcher). No world yet — register commands here.
func _mod_loaded() -> void:
	Pax.register_command("theia", func(_args):
		return "Theia observations: %d" % observations,
		"example_theia — how many times Theia was observed")
	log_info("loaded, textures at " + path("planets/"))


# The planet was just created from JSON: tweak its look from code.
func _body_created(_game: PaxGame, body: Dictionary) -> void:
	if body["name"] == BODY and body.get("material") is ShaderMaterial:
		body["material"].set_shader_parameter("relief", 0.03)   # a bit more dramatic relief


# The world is ready: build UI.
func _world_ready(game: PaxGame) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = tr_key("theia_window_title")
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_info)
	var fly := Button.new()
	fly.text = tr_key("theia_fly")
	fly.pressed.connect(func(): game.focus(BODY))
	box.add_child(fly)
	game.add_window(tr_key("theia_button"), box, Vector2(340, 160))
	_refresh(game)


# Time moved forward (any time skip).
func _days_passed(game: PaxGame, _from_day: int, _days: int) -> void:
	observations += 1
	if observations % 5 == 0:
		game.chronicle(game.home_body(), tr_key("theia_chronicle") % observations, "good", 2)
	_refresh(game)


# Save / load: return plain JSON data, get it back after loading.
func _save_state(_game: PaxGame) -> Dictionary:
	return {"observations": observations}


func _game_loaded(_game: PaxGame, state: Dictionary) -> void:
	observations = int(state.get("observations", 0))


func _refresh(game: PaxGame) -> void:
	if is_instance_valid(_info):
		_info.text = tr_key("theia_window_text") % [observations, game.date_text()]
