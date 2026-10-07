extends PaxMod
## Example: a voxel copy of the home planet. Everything here goes through Pax.voxel.
## mod.json has "components": ["voxel"] — the launcher installs the voxel library and the
## game loads it before this script, so Voxel* classes may be used by name if you need them.

const RADIUS := 200.0

var _game: PaxGame
var _body := ""
var _planet: Node3D            # VoxelLodTerrain made by Pax.voxel.body_planet
var _camera: Camera3D
var _view: SubViewportContainer
var _world: SubViewport
var _station: MeshInstance3D
var _label: Label
var _count: Label
var _yaw := 0.6
var _pitch := 0.35
var _distance := 620.0
var _rotating := false
# Craters are the mod's own state: voxel worlds are not saved by the game,
# so we record what we dug and replay it after loading.
var craters: Array = []


func _world_ready(game: PaxGame) -> void:
	_game = game
	_body = game.home_body()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = tr_key("vox_title")
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)
	if not Pax.voxel.enable():
		var no := Label.new()
		no.text = tr_key("vox_no_component")
		no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(no)
		game.add_window(tr_key("vox_button"), box, Vector2(420, 120))
		return

	# A 3D world of our own inside the window: the game's scene is left alone.
	_view = SubViewportContainer.new()
	_view.stretch = true
	_view.custom_minimum_size = Vector2(620, 420)
	_view.gui_input.connect(_on_input)
	box.add_child(_view)
	_world = SubViewport.new()
	_world.own_world_3d = true
	_view.add_child(_world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.01, 0.015, 0.03)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.45, 0.47, 0.52)
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 35, 0)
	_world.add_child(sun)

	# 1. The planet: relief from the body's maps, colours and provinces from the game.
	_planet = Pax.voxel.body_planet(_body, {"radius": RADIUS, "editable": true, "provinces": 0.6})
	_world.add_child(_planet)

	# 2. The camera needs a viewer — voxel terrain loads around it.
	_camera = Camera3D.new()
	_camera.far = 8000.0
	_world.add_child(_camera)
	Pax.voxel.viewer(_camera)
	_place_camera()

	# 3. A model built from data (models/station.json) — no Blender involved.
	var data = JSON.parse_string(read_text("models/station.json"))
	if data is Dictionary:
		_station = Pax.voxel.model(data)
		_station.position = Vector3(RADIUS * 1.45, RADIUS * 0.25, 0)
		_station.visible = false
		_world.add_child(_station)

	_label = Label.new()
	_label.text = tr_key("vox_hint")
	box.add_child(_label)
	var row := HBoxContainer.new()
	box.add_child(row)
	var station := CheckButton.new()
	station.text = tr_key("vox_station")
	station.toggled.connect(func(on: bool):
		if is_instance_valid(_station):
			_station.visible = on)
	row.add_child(station)
	var reset := Button.new()
	reset.text = tr_key("vox_reset")
	reset.pressed.connect(_heal)
	row.add_child(reset)
	_count = Label.new()
	row.add_child(_count)
	game.add_window(tr_key("vox_button"), box, Vector2(660, 540))

	# Provinces change hands in the game — repaint ours.
	hook("province_captured", func(_d): Pax.voxel.refresh_provinces(_planet.material))
	_replay()


func _place_camera() -> void:
	var dir := Vector3(cos(_pitch) * sin(_yaw), sin(_pitch), cos(_pitch) * cos(_yaw))
	_camera.look_at_from_position(dir * _distance, Vector3.ZERO)


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_RIGHT:
			_rotating = e.pressed
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(RADIUS * 1.4, _distance - 25.0)
			_place_camera()
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(RADIUS * 6.0, _distance + 25.0)
			_place_camera()
		elif e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var hit := _hit(e.position)
			if not hit.is_empty():
				_crater(hit["position"], 14.0)
	elif e is InputEventMouseMotion:
		if _rotating:
			_yaw -= e.relative.x * 0.006
			_pitch = clampf(_pitch + e.relative.y * 0.006, -1.4, 1.4)
			_place_camera()
		else:
			_describe(_hit(e.position))


# Mouse → ray from the camera → point on the voxel planet.
func _hit(mouse: Vector2) -> Dictionary:
	var p := mouse * Vector2(_world.size) / _view.size
	return Pax.voxel.raycast(_planet, _camera.project_ray_origin(p), _camera.project_ray_normal(p), _distance * 2.0)


# 4. Provinces: the point under the cursor → province id → name and owner.
func _describe(hit: Dictionary) -> void:
	if hit.is_empty():
		_label.text = tr_key("vox_hint")
		return
	var id: int = Pax.voxel.province_at(_body, hit["position"])
	if id == 0:
		_label.text = tr_key("vox_over") % [tr_key("vox_nothing"), ""]
		return
	var p := _game.province(_body, id)
	_label.text = tr_key("vox_over") % [str(p.get("name", "")), (tr_key("vox_owner") % str(p["owner"])) if str(p.get("owner", "")) != "" else ""]


# 5. Destruction: carve a sphere out of the planet.
func _crater(position: Vector3, radius: float) -> void:
	Pax.voxel.dig(_planet, position, radius)
	craters.append([position.x, position.y, position.z, radius])
	_count.text = tr_key("vox_craters") % craters.size()


func _heal() -> void:
	for c in craters:
		Pax.voxel.fill(_planet, Vector3(c[0], c[1], c[2]), float(c[3]) + 1.0)
	craters.clear()
	_count.text = tr_key("vox_craters") % 0


func _replay() -> void:
	if not is_instance_valid(_planet):
		return
	# The planet needs a moment to load before it can be edited.
	await _planet.get_tree().create_timer(3.0).timeout
	for c in craters:
		Pax.voxel.dig(_planet, Vector3(c[0], c[1], c[2]), float(c[3]))
	if is_instance_valid(_count):
		_count.text = tr_key("vox_craters") % craters.size()


func _save_state(_g: PaxGame) -> Dictionary:
	return {"craters": craters}


func _game_loaded(_g: PaxGame, state: Dictionary) -> void:
	craters = state.get("craters", [])
