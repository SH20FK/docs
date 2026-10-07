# ui/window.gd
# Главное окно мода «ВИ-Советник 2.0»: заголовочная плашка-ручка, TabContainer с векторными SVG-иконками, перетаскивание и изменение размера.

extends PanelContainer

signal ask_advisor_requested()
signal new_plan_requested(goal: String)
signal rebuild_plan_requested(plan_id: String)
signal accept_advice_requested(advice_item: Dictionary)
signal execute_order_requested(order_action: Dictionary)
signal change_profile_requested()

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _header_bar: PanelContainer = null
var _tab_container: TabContainer = null
var _tab_overview: Control = null
var _tab_plans: Control = null
var _tab_map: Control = null
var _tab_advice: Control = null
var _tab_chronicle: Control = null

const DragResizableScript = preload("res://mods/strategist/lib/drag_resizable.gd")
const IconsScript = preload("res://mods/strategist/lib/icons.gd")

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store
	custom_minimum_size = Vector2(880, 580)
	size = Vector2(880, 580)

func _ready() -> void:
	_build_ui()
	_setup_drag_resize()

func _setup_drag_resize() -> void:
	var target_ctrl: Control = self
	var parent_ctrl: Control = get_parent() as Control
	if parent_ctrl != null and parent_ctrl is PanelContainer:
		target_ctrl = parent_ctrl

	DragResizableScript.setup_window(target_ctrl, _header_bar, Vector2(720, 480), 48.0, 38.0, 12.0, 12.0)

func refresh_all() -> void:
	if _tab_overview != null and _tab_overview.has_method("refresh"):
		_tab_overview.call("refresh")
	if _tab_plans != null and _tab_plans.has_method("refresh"):
		_tab_plans.call("refresh")
	if _tab_map != null and _tab_map.has_method("refresh"):
		_tab_map.call("refresh")
	if _tab_advice != null and _tab_advice.has_method("refresh"):
		_tab_advice.call("refresh")
	if _tab_chronicle != null and _tab_chronicle.has_method("refresh"):
		_tab_chronicle.call("refresh")

func _build_ui() -> void:
	var main_sb: StyleBoxFlat = StyleBoxFlat.new()
	main_sb.bg_color = Color(0.06, 0.08, 0.13, 0.96)
	main_sb.border_color = Color(0.24, 0.35, 0.50, 0.85)
	main_sb.set_border_width_all(1)
	main_sb.set_corner_radius_all(6)
	main_sb.shadow_color = Color(0, 0, 0, 0.5)
	main_sb.shadow_size = 6
	add_theme_stylebox_override("panel", main_sb)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(main_vbox)

	# 1. Заголовочная панель-ручка для перетаскивания (Drag Bar)
	_header_bar = PanelContainer.new()
	_header_bar.custom_minimum_size = Vector2(0, 28)
	_header_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var h_sb: StyleBoxFlat = StyleBoxFlat.new()
	h_sb.bg_color = Color(0.10, 0.15, 0.23, 0.95)
	h_sb.border_color = Color(0.22, 0.32, 0.46, 0.7)
	h_sb.set_border_width_all(1)
	h_sb.set_corner_radius_all(4)
	_header_bar.add_theme_stylebox_override("panel", h_sb)
	main_vbox.add_child(_header_bar)

	var h_margin: MarginContainer = MarginContainer.new()
	h_margin.add_theme_constant_override("margin_left", 8)
	h_margin.add_theme_constant_override("margin_right", 8)
	h_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_header_bar.add_child(h_margin)

	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_theme_constant_override("separation", 8)
	h_margin.add_child(h_box)

	var h_title_box: HBoxContainer = IconsScript.create_icon_row("capitol", mod_ref.tr_key("strat_title") if mod_ref != null else "ВИ-Советник 2.0", 12, Color(1.0, 0.85, 0.35), Color(1.0, 0.85, 0.35), Vector2(16, 16))
	h_title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_box.add_child(h_title_box)

	var hint_lbl: Label = Label.new()
	hint_lbl.text = "[перетаскивание]"
	hint_lbl.add_theme_font_size_override("font_size", 10)
	hint_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_child(hint_lbl)

	# 2. Вкладки
	_tab_container = TabContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tab_container)

	# 1. Обзор
	var TabOverviewScript = preload("res://mods/strategist/ui/tab_overview.gd")
	_tab_overview = TabOverviewScript.new(mod_ref, game_ref, store_ref)
	_tab_overview.name = mod_ref.tr_key("strat_tab_overview") if mod_ref != null else "Обзор"
	_tab_overview.connect("ask_advisor_requested", func() -> void: emit_signal("ask_advisor_requested"))
	_tab_overview.connect("change_profile_requested", func() -> void: emit_signal("change_profile_requested"))
	_tab_container.add_child(_tab_overview)
	_tab_container.set_tab_icon(0, IconsScript.get_icon("capitol", 16))

	# 2. Планы
	var TabPlansScript = preload("res://mods/strategist/ui/tab_plans.gd")
	_tab_plans = TabPlansScript.new(mod_ref, game_ref, store_ref)
	_tab_plans.name = mod_ref.tr_key("strat_tab_plans") if mod_ref != null else "Планы"
	_tab_plans.connect("new_plan_requested", func(g: String) -> void: emit_signal("new_plan_requested", g))
	_tab_plans.connect("rebuild_plan_requested", func(p_id: String) -> void: emit_signal("rebuild_plan_requested", p_id))
	_tab_container.add_child(_tab_plans)
	_tab_container.set_tab_icon(1, IconsScript.get_icon("target", 16))

	# 3. Карта
	var TabMapScript = preload("res://mods/strategist/ui/tab_map.gd")
	_tab_map = TabMapScript.new(mod_ref, game_ref, store_ref)
	_tab_map.name = mod_ref.tr_key("strat_tab_map") if mod_ref != null else "Карта"
	_tab_container.add_child(_tab_map)
	_tab_container.set_tab_icon(2, IconsScript.get_icon("commander", 16))

	# 4. Советы
	var TabAdviceScript = preload("res://mods/strategist/ui/tab_advice.gd")
	_tab_advice = TabAdviceScript.new(mod_ref, game_ref, store_ref)
	_tab_advice.name = mod_ref.tr_key("strat_tab_advice") if mod_ref != null else "Советы"
	_tab_advice.connect("accept_advice_requested", func(item: Dictionary) -> void: emit_signal("accept_advice_requested", item))
	_tab_advice.connect("execute_order_requested", func(act: Dictionary) -> void: emit_signal("execute_order_requested", act))
	_tab_container.add_child(_tab_advice)
	_tab_container.set_tab_icon(3, IconsScript.get_icon("advice", 16))

	# 5. Летопись
	var TabChronicleScript = preload("res://mods/strategist/ui/tab_chronicle.gd")
	_tab_chronicle = TabChronicleScript.new(mod_ref, game_ref, store_ref)
	_tab_chronicle.name = mod_ref.tr_key("strat_tab_chronicle") if mod_ref != null else "Летопись"
	_tab_container.add_child(_tab_chronicle)
	_tab_container.set_tab_icon(4, IconsScript.get_icon("scroll", 16))
