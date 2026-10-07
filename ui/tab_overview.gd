# ui/tab_overview.gd
# Вкладка «Обзор»: оперативная сводка, селектор государственной доктрины, топ-3 угроз и возможностей с векторными SVG-иконками.

extends ScrollContainer

signal ask_advisor_requested()
signal change_profile_requested()

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _content_box: VBoxContainer = null

const DoctrinesScript = preload("res://mods/strategist/lib/doctrines.gd")
const IconsScript = preload("res://mods/strategist/lib/icons.gd")

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store

func _ready() -> void:
	_build_ui()
	_wire_signals()

func _wire_signals() -> void:
	if store_ref != null:
		if store_ref.has_signal("stances_changed"):
			store_ref.connect("stances_changed", func(_s: Dictionary) -> void: refresh())
		if store_ref.has_signal("doctrine_changed"):
			store_ref.connect("doctrine_changed", func(_d: String) -> void: refresh())

func refresh() -> void:
	if _content_box != null:
		_content_box.queue_free()
	_build_ui()

func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(margin)

	_content_box = VBoxContainer.new()
	_content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_box.add_theme_constant_override("separation", 14)
	margin.add_child(_content_box)

	# 1. Шапка профиля советника и кнопка запроса
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 10)
	_content_box.add_child(top_bar)

	var cur_profile: String = mod_ref.get_setting("profile", "akademik") if mod_ref != null else "akademik"
	var profile_name_key: String = "strat_profile_" + cur_profile
	var prof_text: String = mod_ref.tr_key(profile_name_key) if mod_ref != null else cur_profile

	var prof_box: HBoxContainer = IconsScript.create_icon_row(cur_profile, "Советник: %s" % prof_text, 14, Color(0.95, 0.95, 0.95), Color.WHITE, Vector2(18, 18))
	top_bar.add_child(prof_box)

	var change_prof_btn: Button = Button.new()
	change_prof_btn.text = mod_ref.tr_key("strat_change_profile") if mod_ref != null else "Сменить профиль"
	change_prof_btn.pressed.connect(func() -> void:
		emit_signal("change_profile_requested")
	)
	top_bar.add_child(change_prof_btn)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer)

	var ask_btn: Button = Button.new()
	ask_btn.text = mod_ref.tr_key("strat_ask_advisor") if mod_ref != null else "Спросить советника"
	ask_btn.icon = IconsScript.get_icon("order")
	ask_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	ask_btn.pressed.connect(func() -> void:
		emit_signal("ask_advisor_requested")
	)
	top_bar.add_child(ask_btn)

	# 2. Карточки ключевых показателей
	var stats_grid: GridContainer = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 10)
	_content_box.add_child(stats_grid)

	var money_val: float = game_ref.money() if game_ref != null else 0.0
	_add_stat_card(stats_grid, "strat_treasury", "%.0f" % money_val, Color(1.0, 0.85, 0.3))

	var home_body: String = game_ref.home_body() if game_ref != null else ""
	var my_country: String = game_ref.country() if game_ref != null else ""
	var prov_count: int = game_ref.provinces_of(home_body, my_country).size() if game_ref != null else 0
	_add_stat_card(stats_grid, "strat_provinces_count", str(prov_count), Color(0.4, 0.8, 1.0))

	var war_status: String = mod_ref.tr_key("strat_yes") if (game_ref != null and game_ref.at_war()) else (mod_ref.tr_key("strat_no") if mod_ref != null else "Нет")
	var war_color: Color = Color(1.0, 0.3, 0.3) if (game_ref != null and game_ref.at_war()) else Color(0.5, 0.9, 0.5)
	_add_stat_card(stats_grid, "strat_active_wars", war_status, war_color)

	# 3. Блок выбора Государственной Доктрины (Feature 3)
	_build_doctrine_section(_content_box)

	# 4. Топ-3 угроз и Топ-3 возможностей
	var split_cols: HBoxContainer = HBoxContainer.new()
	split_cols.add_theme_constant_override("separation", 14)
	_content_box.add_child(split_cols)

	var threats_panel: PanelContainer = PanelContainer.new()
	threats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_cols.add_child(threats_panel)
	_build_threats_list(threats_panel)

	var opps_panel: PanelContainer = PanelContainer.new()
	opps_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split_cols.add_child(opps_panel)
	_build_opps_list(opps_panel)

	# 5. Тренды (динамика)
	_build_trends_block()

func _build_doctrine_section(parent: Control) -> void:
	var doc_panel: PanelContainer = PanelContainer.new()
	parent.add_child(doc_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	doc_panel.add_child(vbox)

	var head_row: HBoxContainer = HBoxContainer.new()
	head_row.add_theme_constant_override("separation", 6)
	vbox.add_child(head_row)

	var doc_icon: TextureRect = IconsScript.create_icon_rect("capitol", Vector2(16, 16), Color(1.0, 0.85, 0.35))
	head_row.add_child(doc_icon)

	var h: Label = Label.new()
	h.text = mod_ref.tr_key("strat_doctrine_title") if mod_ref != null else "Государственная доктрина"
	h.add_theme_font_size_override("font_size", 13)
	h.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	head_row.add_child(h)

	var sub: Label = Label.new()
	sub.text = "— " + (mod_ref.tr_key("strat_doctrine_desc") if mod_ref != null else "Генеральный вектор развития")
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	head_row.add_child(sub)

	var cards_row: HBoxContainer = HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 10)
	vbox.add_child(cards_row)

	var cur_doc: String = str(store_ref.get("doctrine")) if store_ref != null and store_ref.get("doctrine") != null else "fortress"
	var all_docs: Array = DoctrinesScript.get_all()

	for doc_item in all_docs:
		var d_id: String = str(doc_item.get("id"))
		var d_icon_key: String = str(doc_item.get("icon_key", "fortress"))
		var d_name: String = mod_ref.tr_key(str(doc_item.get("name_key"))) if mod_ref != null else d_id
		var d_desc: String = mod_ref.tr_key(str(doc_item.get("desc_key"))) if mod_ref != null else ""

		var is_active: bool = (d_id == cur_doc)

		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_row.add_child(card)

		var c_margin: MarginContainer = MarginContainer.new()
		c_margin.add_theme_constant_override("margin_left", 8)
		c_margin.add_theme_constant_override("margin_top", 8)
		c_margin.add_theme_constant_override("margin_right", 8)
		c_margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(c_margin)

		var c_vbox: VBoxContainer = VBoxContainer.new()
		c_vbox.add_theme_constant_override("separation", 4)
		c_margin.add_child(c_vbox)

		var btn: Button = Button.new()
		btn.text = d_name + (" [активна]" if is_active else "")
		btn.icon = IconsScript.get_icon(d_icon_key)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_active:
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
		btn.pressed.connect(func() -> void:
			if store_ref != null and store_ref.has_method("set_doctrine"):
				store_ref.call("set_doctrine", d_id)
				if game_ref != null:
					game_ref.toast("Утверждена доктрина: " + d_name)
		)
		c_vbox.add_child(btn)

		var desc_lbl: Label = Label.new()
		desc_lbl.text = d_desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
		c_vbox.add_child(desc_lbl)

func _add_stat_card(parent: Control, label_tr: String, val_str: String, val_color: Color) -> void:
	var panel: PanelContainer = PanelContainer.new()
	parent.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = mod_ref.tr_key(label_tr) if mod_ref != null else label_tr
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title)

	var val_lbl: Label = Label.new()
	val_lbl.text = val_str
	val_lbl.add_theme_font_size_override("font_size", 16)
	val_lbl.add_theme_color_override("font_color", val_color)
	vbox.add_child(val_lbl)

func _build_threats_list(parent: Control) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	parent.add_child(vbox)

	var head: HBoxContainer = IconsScript.create_icon_row("threat", mod_ref.tr_key("strat_top_threats") if mod_ref != null else "Топ-3 угроз", 13, Color(1.0, 0.4, 0.3), Color(1.0, 0.4, 0.3), Vector2(16, 16))
	vbox.add_child(head)

	var stances: Dictionary = store_ref.get("stances") if store_ref != null and store_ref.get("stances") != null else {}
	var sorted_threats: Array = []
	for c_name in stances.keys():
		var s: Dictionary = stances[c_name]
		var t_idx: float = float(s.get("threat_index", 0.0))
		sorted_threats.append({"name": c_name, "score": t_idx, "info": s})

	sorted_threats.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var count: int = 0
	for item in sorted_threats:
		if count >= 3:
			break
		var score: float = float(item.get("score", 0.0))
		if score <= 0.0:
			continue
		var row: Label = Label.new()
		row.text = "%d. %s — угроза: %.0f/100" % [count + 1, str(item.get("name")), score]
		row.add_theme_font_size_override("font_size", 12)
		vbox.add_child(row)
		count += 1

	if count == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = mod_ref.tr_key("strat_no_threats") if mod_ref != null else "Угроз нет"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(empty_lbl)

func _build_opps_list(parent: Control) -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	parent.add_child(vbox)

	var head: HBoxContainer = IconsScript.create_icon_row("opportunity", mod_ref.tr_key("strat_top_opportunities") if mod_ref != null else "Топ-3 возможностей", 13, Color(0.3, 0.8, 1.0), Color(0.3, 0.8, 1.0), Vector2(16, 16))
	vbox.add_child(head)

	var stances: Dictionary = store_ref.get("stances") if store_ref != null and store_ref.get("stances") != null else {}
	var sorted_opps: Array = []
	for c_name in stances.keys():
		var s: Dictionary = stances[c_name]
		var o_idx: float = float(s.get("opportunity_index", 0.0))
		sorted_opps.append({"name": c_name, "score": o_idx, "info": s})

	sorted_opps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", 0.0)) > float(b.get("score", 0.0))
	)

	var count: int = 0
	for item in sorted_opps:
		if count >= 3:
			break
		var score: float = float(item.get("score", 0.0))
		if score <= 0.0:
			continue
		var row: Label = Label.new()
		row.text = "%d. %s — индекс: %.0f/100" % [count + 1, str(item.get("name")), score]
		row.add_theme_font_size_override("font_size", 12)
		vbox.add_child(row)
		count += 1

	if count == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = mod_ref.tr_key("strat_no_opportunities") if mod_ref != null else "Возможностей нет"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		vbox.add_child(empty_lbl)

func _build_trends_block() -> void:
	var trends_panel: PanelContainer = PanelContainer.new()
	_content_box.add_child(trends_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	trends_panel.add_child(vbox)

	var title: Label = Label.new()
	title.text = mod_ref.tr_key("strat_trends_12m") if mod_ref != null else "Тренды (12 месяцев)"
	title.add_theme_font_size_override("font_size", 13)
	vbox.add_child(title)

	var metrics: Dictionary = store_ref.get("metrics") if store_ref != null and store_ref.get("metrics") != null else {}
	var money_series: Array = metrics.get("money", [])
	var prov_series: Array = metrics.get("provinces", [])

	var summary_lbl: Label = Label.new()
	if money_series.size() >= 2:
		var diff: float = float(money_series[money_series.size() - 1]) - float(money_series[0])
		var prov_diff: float = float(prov_series[prov_series.size() - 1]) - float(prov_series[0]) if prov_series.size() >= 2 else 0.0
		summary_lbl.text = "Динамика казны: %+0.0f | Динамика территорий: %+0.0f провинций" % [diff, prov_diff]
	else:
		summary_lbl.text = "Накопление данных за периоды перемотки времени..."
	summary_lbl.add_theme_font_size_override("font_size", 11)
	summary_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(summary_lbl)
