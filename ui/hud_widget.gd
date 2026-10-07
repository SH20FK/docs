# ui/hud_widget.gd
# Компактный мини-индикатор текущей цели и шага плана на HUD игры с векторными SVG-иконками.

extends PanelContainer

signal open_advisor_requested()

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _icon_rect: TextureRect = null
var _star_rect: TextureRect = null
var _plan_lbl: Label = null
var _step_lbl: Label = null
var _open_btn: Button = null

var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

const IconsScript = preload("res://mods/strategist/lib/icons.gd")

const SAFE_TOP: float = 48.0
const SAFE_BOTTOM: float = 40.0
const SAFE_LEFT: float = 12.0
const SAFE_RIGHT: float = 16.0

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_build_ui()
	_wire_signals()
	_init_position()
	refresh()

	var vp: Viewport = get_viewport()
	if vp != null:
		vp.size_changed.connect(_on_viewport_resized)

func _init_position() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var init_w: float = custom_minimum_size.x
	var target_x: float = maxf(SAFE_LEFT, vp_size.x - init_w - SAFE_RIGHT)
	var target_y: float = SAFE_TOP
	position = Vector2(target_x, target_y)

func _on_viewport_resized() -> void:
	_clamp_position(position)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_is_dragging = false
	elif event is InputEventMouseMotion and _is_dragging:
		var wanted_pos: Vector2 = get_global_mouse_position() - _drag_offset
		_clamp_position(wanted_pos)

func _clamp_position(wanted: Vector2) -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		position = wanted
		return
	var vp_size: Vector2 = vp.get_visible_rect().size
	var max_x: float = maxf(SAFE_LEFT, vp_size.x - size.x - SAFE_RIGHT)
	var max_y: float = maxf(SAFE_TOP, vp_size.y - size.y - SAFE_BOTTOM)
	position = Vector2(clampf(wanted.x, SAFE_LEFT, max_x), clampf(wanted.y, SAFE_TOP, max_y))

func _wire_signals() -> void:
	if store_ref != null:
		if store_ref.has_signal("plan_updated"):
			store_ref.connect("plan_updated", func(_p: Dictionary) -> void: refresh())
		if store_ref.has_signal("step_completed"):
			store_ref.connect("step_completed", func(_id: String, _s: Dictionary) -> void: refresh())
		if store_ref.has_signal("doctrine_changed"):
			store_ref.connect("doctrine_changed", func(_d: String) -> void: refresh())

func refresh() -> void:
	if _plan_lbl == null:
		return

	var profile: String = "akademik"
	if mod_ref != null:
		profile = mod_ref.get_setting("profile", "akademik")
	elif store_ref != null and store_ref.get("profile") != null:
		profile = str(store_ref.get("profile"))

	if _icon_rect != null:
		_icon_rect.texture = IconsScript.get_icon(profile)
		_icon_rect.modulate = Color.WHITE

	var active_plan: Dictionary = {}
	if store_ref != null and store_ref.has_method("get_active_plan"):
		active_plan = store_ref.call("get_active_plan")

	if active_plan.is_empty():
		_plan_lbl.text = mod_ref.tr_key("strat_hud_no_active_plan") if mod_ref != null else "Нет активного плана"
		_plan_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		_step_lbl.text = ""
		if _star_rect != null:
			_star_rect.visible = false
		return

	if _star_rect != null:
		_star_rect.visible = true

	var title: String = str(active_plan.get("title", "План"))
	var steps: Array = active_plan.get("steps", [])
	var cur_step_num: int = 1
	var cur_step_what: String = ""
	var total_steps: int = steps.size()

	for i in range(total_steps):
		var st_any: Variant = steps[i]
		if st_any is Dictionary:
			var st: Dictionary = st_any
			if str(st.get("status", "")) == "pending":
				cur_step_num = int(st.get("n", i + 1))
				cur_step_what = str(st.get("what", ""))
				break

	_plan_lbl.text = title
	_plan_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))

	if not cur_step_what.is_empty():
		var prefix: String = mod_ref.tr_key("strat_hud_step_prefix") if mod_ref != null else "Шаг %d/%d"
		_step_lbl.text = ("[" + prefix + ": %s]") % [cur_step_num, total_steps, cur_step_what]
	else:
		_step_lbl.text = "[Все шаги завершены]"

func _build_ui() -> void:
	custom_minimum_size = Vector2(360, 36)
	mouse_default_cursor_shape = Control.CURSOR_MOVE

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.13, 0.94)
	sb.border_color = Color(0.35, 0.45, 0.60, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	add_theme_stylebox_override("panel", sb)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(margin)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(hbox)

	_icon_rect = IconsScript.create_icon_rect("academic", Vector2(18, 18), Color(1.0, 0.85, 0.35))
	hbox.add_child(_icon_rect)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	text_box.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(text_box)

	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	title_row.mouse_filter = Control.MOUSE_FILTER_PASS
	text_box.add_child(title_row)

	_star_rect = IconsScript.create_icon_rect("star", Vector2(12, 12), Color(1.0, 0.85, 0.35))
	title_row.add_child(_star_rect)

	_plan_lbl = Label.new()
	_plan_lbl.text = "Загрузка стратегии..."
	_plan_lbl.add_theme_font_size_override("font_size", 11)
	_plan_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_plan_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	title_row.add_child(_plan_lbl)

	_step_lbl = Label.new()
	_step_lbl.text = ""
	_step_lbl.add_theme_font_size_override("font_size", 10)
	_step_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	_step_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	text_box.add_child(_step_lbl)

	_open_btn = Button.new()
	_open_btn.text = mod_ref.tr_key("strat_hud_open_btn") if mod_ref != null else "Советник"
	_open_btn.icon = IconsScript.get_icon("capitol")
	_open_btn.add_theme_font_size_override("font_size", 11)
	_open_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_open_btn.pressed.connect(func() -> void:
		emit_signal("open_advisor_requested")
	)
	hbox.add_child(_open_btn)
