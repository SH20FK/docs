# ui/tab_map.gd
# Вкладка «Карта»: стратегическая матрица силы и угроз, фильтры, оперативное досье и военный симулятор с векторными SVG-иконками.

extends HBoxContainer

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _map_view: Control = null
var _dossier_box: VBoxContainer = null

# Фильтры
var _chk_hostile: CheckBox = null
var _chk_border: CheckBox = null

const SimulatorScript = preload("res://mods/strategist/lib/simulator.gd")
const MapViewScript = preload("res://mods/strategist/lib/map_view.gd")
const IconsScript = preload("res://mods/strategist/lib/icons.gd")

const C_MUTED: Color = Color(0.62, 0.68, 0.76)
const C_DIM: Color = Color(0.45, 0.52, 0.60)
const C_GOLD: Color = Color(1.0, 0.85, 0.35)
const C_THREAT: Color = Color(0.95, 0.38, 0.33)
const C_OPP: Color = Color(0.32, 0.80, 1.0)

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store

func _ready() -> void:
	_build_ui()
	_wire_signals()

func _wire_signals() -> void:
	if store_ref != null and store_ref.has_signal("stances_changed"):
		store_ref.connect("stances_changed", func(_s: Dictionary) -> void: refresh())

func refresh() -> void:
	if _map_view != null and store_ref != null and game_ref != null:
		_map_view.call("set_data", mod_ref, game_ref, store_ref)

func _tr(key: String, fallback: String) -> String:
	if mod_ref == null:
		return fallback
	var s: String = mod_ref.tr_key(key)
	if s.is_empty():
		return fallback
	return s

func _build_ui() -> void:
	add_theme_constant_override("separation", 12)

	# Левая часть: панель фильтров + матрица квадрантов
	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", 6)
	add_child(left_box)

	# Верхняя панель (оси, фильтры, управление)
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 8)
	left_box.add_child(top_bar)

	var axis_keys: Array = ["relation", "power", "threat", "opportunity", "economy", "army", "distance", "border", "activity", "stability"]
	var axis_names: Array = ["Отношение", "Сила", "Угроза", "Возможность", "Экономика", "Армия", "Расстояние", "Пограничность", "Активность", "Стабильность"]

	var opt_x: OptionButton = OptionButton.new()
	for i in range(axis_names.size()):
		opt_x.add_item("X: " + axis_names[i], i)
	opt_x.select(0)
	top_bar.add_child(opt_x)

	var opt_y: OptionButton = OptionButton.new()
	for i in range(axis_names.size()):
		opt_y.add_item("Y: " + axis_names[i], i)
	opt_y.select(1)
	top_bar.add_child(opt_y)

	var btn_swap: Button = Button.new()
	btn_swap.text = "⇄"
	top_bar.add_child(btn_swap)

	var btn_add: MenuButton = MenuButton.new()
	btn_add.text = "+ Страна"
	var popup: PopupMenu = btn_add.get_popup()
	popup.about_to_popup.connect(func() -> void:
		popup.clear()
		if store_ref == null: return
		var stances: Dictionary = store_ref.get("stances") if store_ref.get("stances") != null else {}
		var sorted_names: Array = stances.keys()
		sorted_names.sort()
		for c_name in sorted_names:
			popup.add_item(str(c_name))
	)
	popup.index_pressed.connect(func(idx: int) -> void:
		var c_name: String = popup.get_item_text(idx)
		if store_ref != null:
			var manual: Array = store_ref.get("manual_selected_countries") if store_ref.get("manual_selected_countries") != null else []
			if manual.is_empty() and _map_view != null:
				# Копируем текущий топ-12, если до этого был авторежим
				var current_visible: Array = _map_view.call("_get_active_countries_list")
				manual = current_visible.duplicate()
			if not manual.has(c_name):
				manual.append(c_name)
			store_ref.set("manual_selected_countries", manual)
			refresh()
	)
	top_bar.add_child(btn_add)

	var btn_auto: Button = Button.new()
	btn_auto.text = "Авто Топ-12"
	btn_auto.pressed.connect(func() -> void:
		if store_ref != null:
			store_ref.set("manual_selected_countries", [])
			refresh()
	)
	top_bar.add_child(btn_auto)

	_chk_hostile = CheckBox.new()
	_chk_hostile.text = mod_ref.tr_key("strat_filter_hostile") if mod_ref != null else "Только враждебные"
	top_bar.add_child(_chk_hostile)

	_chk_border = CheckBox.new()
	_chk_border.text = mod_ref.tr_key("strat_filter_border") if mod_ref != null else "Только пограничные"
	top_bar.add_child(_chk_border)

	var _update_axes = func(idx: int) -> void:
		if _map_view != null:
			_map_view.set_axes(axis_keys[opt_x.selected], axis_keys[opt_y.selected])

	opt_x.item_selected.connect(_update_axes)
	opt_y.item_selected.connect(_update_axes)

	btn_swap.pressed.connect(func() -> void:
		var temp: int = opt_x.selected
		opt_x.select(opt_y.selected)
		opt_y.select(temp)
		_update_axes.call(0)
	)

	_chk_hostile.toggled.connect(func(val: bool) -> void:
		if _map_view != null:
			_map_view.set("filter_hostile_only", val)
			_map_view.queue_redraw()
	)
	_chk_border.toggled.connect(func(val: bool) -> void:
		if _map_view != null:
			_map_view.set("filter_border_only", val)
			_map_view.queue_redraw()
	)

	# Контейнер для матрицы
	var matrix_panel: PanelContainer = PanelContainer.new()
	matrix_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	matrix_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_box.add_child(matrix_panel)

	_map_view = MapViewScript.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.connect("country_clicked", _on_country_selected)
	_map_view.connect("country_hovered", _on_country_selected)
	matrix_panel.add_child(_map_view)

	var bottom_bar: HBoxContainer = HBoxContainer.new()
	bottom_bar.add_theme_constant_override("separation", 10)
	left_box.add_child(bottom_bar)

	var lbl_stats: Label = Label.new()
	lbl_stats.text = "Угроз: 0 · Союзников: 0 · Партнёров: 0 · Противников: 0"
	lbl_stats.add_theme_font_size_override("font_size", 11)
	lbl_stats.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	bottom_bar.add_child(lbl_stats)

	var lbl_date: Label = Label.new()
	lbl_date.text = "[2026-07-03]"
	lbl_date.add_theme_font_size_override("font_size", 11)
	lbl_date.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	lbl_date.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bottom_bar.add_child(lbl_date)

	_map_view.connect("quadrant_stats_updated", func(th: int, pi: int, cl: int, ta: int) -> void:
		lbl_stats.text = "Угроз: %d · Союзников: %d · Партнёров: %d · Противников: %d" % [th, pi, cl, ta]
		if game_ref != null:
			lbl_date.text = "[День %d]" % game_ref.day()
	)

	# Правая часть: оперативное досье + военный симулятор
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(330, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var r_sb: StyleBoxFlat = StyleBoxFlat.new()
	r_sb.bg_color = Color(0.07, 0.09, 0.14, 0.95)
	r_sb.border_color = Color(0.22, 0.32, 0.46, 0.75)
	r_sb.set_border_width_all(1)
	r_sb.set_corner_radius_all(6)
	right_panel.add_theme_stylebox_override("panel", r_sb)
	add_child(right_panel)

	var dossier_scroll: ScrollContainer = ScrollContainer.new()
	dossier_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(dossier_scroll)

	var dossier_margin: MarginContainer = MarginContainer.new()
	dossier_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_margin.add_theme_constant_override("margin_left", 12)
	dossier_margin.add_theme_constant_override("margin_top", 12)
	dossier_margin.add_theme_constant_override("margin_right", 12)
	dossier_margin.add_theme_constant_override("margin_bottom", 12)
	dossier_scroll.add_child(dossier_margin)

	_dossier_box = VBoxContainer.new()
	_dossier_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dossier_box.add_theme_constant_override("separation", 10)
	dossier_margin.add_child(_dossier_box)

	_show_default_dossier()
	refresh()

# ─── Вспомогательные построители ───

func _make_card(parent: Control, bg: Color, border: Color, pad: int = 10) -> VBoxContainer:
	var card: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	card.add_theme_stylebox_override("panel", sb)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", pad)
	margin.add_theme_constant_override("margin_top", pad)
	margin.add_theme_constant_override("margin_right", pad)
	margin.add_theme_constant_override("margin_bottom", pad)
	card.add_child(margin)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	parent.add_child(card)
	return v

func _add_divider(parent: Control) -> void:
	var sep: HSeparator = HSeparator.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.30, 0.38, 0.50, 0.30)
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", sb)
	parent.add_child(sep)

func _add_caption(parent: Control, text: String, color: Color = C_DIM) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l

func _add_section_head(parent: Control, icon_key: String, text: String, color: Color) -> void:
	parent.add_child(IconsScript.create_icon_row(icon_key, text, 11, color, color, Vector2(13, 13)))

func _add_bar_row(parent: Control, caption: String, val: float, max_val: float, fill: Color) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	parent.add_child(row)

	var cap: Label = Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", 10)
	cap.add_theme_color_override("font_color", C_MUTED)
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(cap)

	var num: Label = Label.new()
	num.text = "%.0f / %d" % [val, int(max_val)]
	num.add_theme_font_size_override("font_size", 10)
	num.add_theme_color_override("font_color", fill.lightened(0.25))
	row.add_child(num)

	parent.add_child(_create_custom_bar(val, max_val, fill))

func _add_tag(parent: Control, text: String, color: Color) -> void:
	var tag: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(color.r, color.g, color.b, 0.10)
	sb.border_color = Color(color.r, color.g, color.b, 0.40)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(9)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	tag.add_theme_stylebox_override("panel", sb)

	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", color)
	tag.add_child(l)
	parent.add_child(tag)

func _add_flag_tag(parent: Control, country_name: String) -> void:
	var tex: Texture2D = null
	if _map_view != null and _map_view.has_method("_get_flag_texture"):
		tex = _map_view.call("_get_flag_texture", country_name)
	if tex == null:
		return
	var tr: TextureRect = TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = Vector2(22, 15)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(tr)

# ─── Досье ───

func _clear_dossier() -> void:
	if _dossier_box == null:
		return
	for child in _dossier_box.get_children():
		child.queue_free()

func _show_default_dossier() -> void:
	if _dossier_box == null:
		return
	_clear_dossier()

	_dossier_box.add_child(IconsScript.create_icon_row(
		"capitol",
		_tr("strat_nation_details", "Досье державы"),
		14, C_GOLD, C_GOLD))

	var hint: Label = Label.new()
	hint.text = "Нажмите на плашку любой державы на матрице — здесь появится разведсводка, оценка советника и расчёт симулятора войны."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", C_MUTED)
	_dossier_box.add_child(hint)

func _on_country_selected(country_name: String) -> void:
	if country_name.is_empty() or _dossier_box == null:
		return

	_clear_dossier()

	var stances: Dictionary = store_ref.get("stances") if store_ref != null and store_ref.get("stances") != null else {}
	var s: Dictionary = stances.get(country_name, {})

	# Единая карточка: шапка, параметры, метки, симулятор, сводка советника
	var box: VBoxContainer = _make_card(_dossier_box, Color(0.09, 0.12, 0.18, 0.92), Color(0.20, 0.28, 0.40, 0.65), 10)

	# 1. Шапка: флаг + название + тир
	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	box.add_child(head)

	_add_flag_tag(head, country_name)

	var name_lbl: Label = Label.new()
	name_lbl.text = country_name
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.76))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	head.add_child(name_lbl)

	var player_country: String = game_ref.country() if game_ref != null else "Игрок"
	var is_player: bool = country_name == player_country

	var tier_idx: int = int(s.get("tier", 2)) if not s.is_empty() else -1
	if is_player:
		_add_tag(head, "ВЫ", Color(0.45, 0.88, 1.0))
	elif tier_idx >= 0:
		_add_tag(head, _tr("strat_tier_" + str(tier_idx), "Тир " + str(tier_idx)), _tier_color(tier_idx))

	if is_player:
		_add_caption(box, "Наша держава — центр коалиции. Все стратегические векторы и приказы исходят отсюда.", Color(0.45, 0.88, 1.0))
		return

	if s.is_empty():
		_add_caption(box, "Разведданных по этой державе пока нет.")
		return

	var relation_val: float = float(s.get("relation", 0.5))
	var threat_val: float = float(s.get("threat_index", 0.0))
	var opp_val: float = float(s.get("opportunity_index", 0.0))
	var has_border: bool = bool(s.get("border", false))
	var prov_count: int = int(s.get("provinces", 0))
	var flags: Array = s.get("flags", [])

	# 2. Геополитические параметры
	var rel_color: Color = Color(0.35, 0.9, 0.45) if relation_val > 0.6 else (Color(1.0, 0.45, 0.35) if relation_val < 0.3 else Color(0.80, 0.82, 0.86))
	_add_param_row(box, "Отношения", "%.2f / 1.00" % relation_val, rel_color)
	_add_param_row(box, "Граница", "Общая граница" if has_border else "Нет прямого контакта", C_GOLD if has_border else C_MUTED)
	_add_param_row(box, "Территорий", "%d провинций" % prov_count, Color(0.55, 0.82, 1.0))

	_add_bar_row(box, "Уровень угрозы", threat_val, 100.0, C_THREAT if threat_val > 50.0 else Color(0.88, 0.68, 0.28))
	_add_bar_row(box, "Индекс возможности", opp_val, 100.0, C_OPP)

	# 3. Разведметки — компактными тегами
	if not flags.is_empty():
		_add_divider(box)
		_add_caption(box, "Разведметки", C_GOLD)
		var flow: HFlowContainer = HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		box.add_child(flow)
		for f in flags:
			_add_tag(flow, str(f), Color(0.92, 0.82, 0.48))

	# 4. Военный симулятор
	if game_ref != null:
		var sim: Dictionary = SimulatorScript.simulate_war(game_ref, country_name, stances)
		_build_sim_section(box, sim)

	# 5. Оценка советника
	_add_divider(box)
	var descriptions: Dictionary = store_ref.get("country_descriptions") if store_ref != null and store_ref.get("country_descriptions") != null else {}
	var desc_data: Dictionary = descriptions.get(country_name, {})
	var ai_text: String = str(desc_data.get("text", "Идёт сбор разведданных..."))
	var desc_day: int = int(desc_data.get("day", 0))

	_add_section_head(box, "insight", "Оценка советника", C_GOLD)

	var ai_lbl: Label = Label.new()
	ai_lbl.text = ai_text
	ai_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ai_lbl.add_theme_font_size_override("font_size", 11)
	ai_lbl.add_theme_color_override("font_color", Color(0.86, 0.90, 0.95))
	box.add_child(ai_lbl)

	if desc_day > 0:
		_add_caption(box, "Данные на день %d" % desc_day)

	# 6. Кнопки действий
	var action_box: HBoxContainer = HBoxContainer.new()
	action_box.add_theme_constant_override("separation", 6)
	action_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dossier_box.add_child(action_box)

	var btn_history: Button = Button.new()
	btn_history.text = "История"
	btn_history.add_theme_font_size_override("font_size", 11)
	action_box.add_child(btn_history)

	var btn_ask: Button = Button.new()
	btn_ask.text = "Спросить"
	btn_ask.add_theme_font_size_override("font_size", 11)
	action_box.add_child(btn_ask)

	var btn_hide: Button = Button.new()
	btn_hide.text = "Скрыть"
	btn_hide.add_theme_font_size_override("font_size", 11)
	btn_hide.pressed.connect(func() -> void:
		if store_ref != null and store_ref.has_method("hide_country"):
			store_ref.call("hide_country", country_name, game_ref.day() if game_ref != null else 0)
			if _map_view != null: _map_view.call("_recalculate_target_positions")
	)
	action_box.add_child(btn_hide)

func _tier_color(tier_idx: int) -> Color:
	match tier_idx:
		0:
			return Color(0.40, 0.90, 0.55)
		1:
			return Color(0.55, 0.85, 0.65)
		2:
			return Color(0.70, 0.75, 0.82)
		3:
			return Color(0.95, 0.72, 0.30)
		4:
			return Color(0.98, 0.48, 0.32)
		_:
			return C_THREAT

func _build_sim_section(parent: Control, sim: Dictionary) -> void:
	_add_divider(parent)
	_add_section_head(parent, "commander", _tr("strat_sim_title", "Военный симулятор"), C_THREAT)

	var win_chance: float = float(sim.get("win_chance", 50.0))
	var win_color: Color = Color(0.35, 0.9, 0.45) if win_chance > 65.0 else (Color(1.0, 0.8, 0.25) if win_chance > 40.0 else C_THREAT)

	_add_bar_row(parent, _tr("strat_sim_win_chance", "Шанс победы"), win_chance, 100.0, win_color)

	var ratio: float = float(sim.get("power_ratio", 1.0))
	var duration: int = int(sim.get("duration_days", 180))
	var risk: float = float(sim.get("coalition_risk", 20.0))

	_add_param_row(parent, _tr("strat_sim_power_ratio", "Соотношение сил"), "%.2fx" % ratio, Color(0.55, 0.85, 1.0))
	_add_param_row(parent, _tr("strat_sim_duration", "Прогноз срока"), "~%d дн." % duration, Color(0.82, 0.86, 0.92))
	_add_param_row(parent, _tr("strat_sim_allies_risk", "Риск коалиции"), "%.0f%%" % risk, C_THREAT if risk > 50.0 else C_MUTED)

	var verdict_key: String = str(sim.get("verdict_key", "strat_sim_verdict_favorable"))
	_add_caption(parent, _tr(verdict_key, verdict_key), win_color)

func _create_custom_bar(val: float, max_val: float, fill_color: Color) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = max_val
	bar.value = val

	var bg_sb: StyleBoxFlat = StyleBoxFlat.new()
	bg_sb.bg_color = Color(0.12, 0.16, 0.24, 0.9)
	bg_sb.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg_sb)

	var fill_sb: StyleBoxFlat = StyleBoxFlat.new()
	fill_sb.bg_color = fill_color
	fill_sb.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill_sb)
	return bar

func _add_param_row(parent: Control, label_str: String, val_str: String, color: Color) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)

	var l_lbl: Label = Label.new()
	l_lbl.text = label_str
	l_lbl.add_theme_font_size_override("font_size", 11)
	l_lbl.add_theme_color_override("font_color", C_MUTED)
	l_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l_lbl)

	var r_lbl: Label = Label.new()
	r_lbl.text = val_str
	r_lbl.add_theme_font_size_override("font_size", 11)
	r_lbl.add_theme_color_override("font_color", color)
	r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	r_lbl.clip_text = true
	row.add_child(r_lbl)