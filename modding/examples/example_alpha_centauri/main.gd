extends PaxMod
## Interstellar arks window. Shows how to:
##  • list bodies of all star systems (game.systems / game.system_bodies)
##  • estimate a trip (game.travel_days / game.distance_ly)
##  • launch an ark (game.launch_ship) and react to its arrival (_ship_arrived)
##  • add a console command with arguments

var _game: PaxGame
var _from: OptionButton
var _to: OptionButton
var _speed: HSlider
var _speed_label: Label
var _people: SpinBox
var _eta: Label
var _flying: Label


func _mod_loaded() -> void:
	Pax.register_command("ark", _ark_command,
		"ark <from> <to> [speed_c] [people] — launch an interstellar ark (use _ for spaces: Проксима_b)")


func _ark_command(args: PackedStringArray) -> String:
	if Pax.game == null:
		return "No world loaded."
	if args.size() < 2:
		return "ark <from body> <to body> [speed_c=0.1] [people=1000]"
	var from := args[0].replace("_", " ")
	var to := args[1].replace("_", " ")
	var speed := float(args[2]) if args.size() > 2 else 0.1
	var people := float(args[3]) if args.size() > 3 else 1000.0
	var ship := Pax.game.launch_ship(from, to, speed, people, {"why": "console"}, "ark", id)
	if ship.is_empty():
		return "Unknown body."
	return "Launched #%d, arrives on day %d" % [ship["id"], ship["until_day"]]


func _world_ready(game: PaxGame) -> void:
	_game = game
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_label(tr_key("acen_title"), 16))

	box.add_child(_label(tr_key("acen_from")))
	_from = OptionButton.new()
	box.add_child(_from)

	box.add_child(_label(tr_key("acen_to")))
	_to = OptionButton.new()
	box.add_child(_to)

	_speed_label = _label("")
	box.add_child(_speed_label)
	_speed = HSlider.new()
	_speed.min_value = 0.01
	_speed.max_value = 0.5
	_speed.step = 0.01
	_speed.value = 0.1
	box.add_child(_speed)

	box.add_child(_label(tr_key("acen_people")))
	_people = SpinBox.new()
	_people.min_value = 10
	_people.max_value = 100000
	_people.step = 10
	_people.value = 2000
	box.add_child(_people)

	_eta = _label("")
	box.add_child(_eta)
	var launch := Button.new()
	launch.text = tr_key("acen_launch")
	launch.pressed.connect(_launch)
	box.add_child(launch)
	_flying = _label("")
	box.add_child(_flying)

	_from.item_selected.connect(func(_i: int): _update_eta())
	_to.item_selected.connect(func(_i: int): _update_eta())
	_speed.value_changed.connect(func(_v: float): _update_eta())

	game.add_window(tr_key("acen_button"), box, Vector2(360, 380))
	_fill_lists()


func _days_passed(_g: PaxGame, _from_day: int, _days: int) -> void:
	_fill_lists()


func _ship_arrived(game: PaxGame, ship: Dictionary) -> void:
	# Only our ships: other mods may launch theirs.
	if str(ship.get("mod", "")) != id:
		return
	var to := str(ship["where_to"])
	game.toast(tr_key("acen_arrived") % [game.tr_key("body_" + to), game.body_system(to)])
	_fill_lists()


func _fill_lists() -> void:
	if _from == null:
		return
	_from.clear()
	for body in _game.colonies():
		_from.add_item(body)
	_to.clear()
	for system in _game.systems():
		for body in _game.system_bodies(system["name"]):
			if str(_game.body(body).get("genus", "")) == "rock":
				_to.add_item("%s — %s" % [body, system["name"]])
				_to.set_item_metadata(_to.item_count - 1, body)
	_update_eta()


func _update_eta() -> void:
	_speed_label.text = tr_key("acen_speed") % snappedf(_speed.value, 0.01)
	_flying.text = tr_key("acen_flying") % _game.ships().size()
	if _from.item_count == 0 or _to.item_count == 0:
		_eta.text = tr_key("acen_no_colony")
		return
	var from := _from.get_item_text(_from.selected)
	var to := str(_to.get_item_metadata(_to.selected))
	var days := _game.travel_days(from, to, _speed.value)
	_eta.text = tr_key("acen_eta") % [snappedf(days / 365.25, 0.1), snappedf(_game.distance_ly(from, to), 0.001)]


func _launch() -> void:
	if _from.item_count == 0 or _to.item_count == 0:
		return
	var from := _from.get_item_text(_from.selected)
	var to := str(_to.get_item_metadata(_to.selected))
	_game.launch_ship(from, to, _speed.value, _people.value, {}, "ark", id)
	_update_eta()


func _label(text: String, size: int = 13) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
