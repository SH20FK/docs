# ui/tab_chronicle.gd
# Вкладка «Летопись»: лог рекомендаций и событий мира, оценка точности планов с векторными SVG-иконками.

extends ScrollContainer

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _chronicle_box: VBoxContainer = null

const IconsScript = preload("res://mods/strategist/lib/icons.gd")

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store

func _ready() -> void:
	_build_ui()
	_wire_signals()

func _wire_signals() -> void:
	if store_ref != null and store_ref.has_signal("history_added"):
		store_ref.connect("history_added", func(_entry: Dictionary) -> void: refresh())

func refresh() -> void:
	_update_view()

func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(margin)

	_chronicle_box = VBoxContainer.new()
	_chronicle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chronicle_box.add_theme_constant_override("separation", 12)
	margin.add_child(_chronicle_box)

	_update_view()

func _update_view() -> void:
	if _chronicle_box == null:
		return
	for child in _chronicle_box.get_children():
		child.queue_free()

	# 1. Заголовок и карточка точности
	var head: HBoxContainer = IconsScript.create_icon_row("scroll", mod_ref.tr_key("strat_chronicle_title") if mod_ref != null else "Летопись решений и исходов", 14, Color(0.95, 0.95, 0.95), Color(1.0, 0.85, 0.35))
	_chronicle_box.add_child(head)

	_build_accuracy_card(_chronicle_box)

	# 2. Список событий летописи
	var history_list: Array = store_ref.get("history") if store_ref != null and store_ref.get("history") != null else []
	var count: int = 0

	for item_any in history_list:
		if not (item_any is Dictionary):
			continue
		var item: Dictionary = item_any
		_add_history_row(_chronicle_box, item)
		count += 1

	if count == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = mod_ref.tr_key("strat_no_history") if mod_ref != null else "Летопись пока пуста"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_chronicle_box.add_child(empty_lbl)

func _build_accuracy_card(parent: Control) -> void:
	var card: PanelContainer = PanelContainer.new()
	parent.add_child(card)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("margin_left", 8)
	card.add_child(hbox)

	var plans: Array = store_ref.get("plans") if store_ref != null and store_ref.get("plans") != null else []
	var done_steps: int = 0
	var total_finished_steps: int = 0

	for p_any in plans:
		if p_any is Dictionary:
			var p: Dictionary = p_any
			var steps: Array = p.get("steps", [])
			for st_any in steps:
				if st_any is Dictionary:
					var st: Dictionary = st_any
					var status: String = str(st.get("status", ""))
					if status == "done":
						done_steps += 1
						total_finished_steps += 1
					elif status == "failed":
						total_finished_steps += 1

	var accuracy_pct: float = (float(done_steps) / float(total_finished_steps) * 100.0) if total_finished_steps > 0 else 100.0

	var acc_row: HBoxContainer = IconsScript.create_icon_row(
		"target",
		"%s: %.0f%% (выполнено шагов: %d/%d)" % [
			mod_ref.tr_key("strat_accuracy") if mod_ref != null else "Точность советника",
			accuracy_pct,
			done_steps,
			total_finished_steps
		],
		12,
		Color(1.0, 0.85, 0.3),
		Color(1.0, 0.85, 0.3)
	)
	hbox.add_child(acc_row)

func _add_history_row(parent: Control, item: Dictionary) -> void:
	var row_panel: PanelContainer = PanelContainer.new()
	parent.add_child(row_panel)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	row_panel.add_child(hbox)

	var day_val: int = int(item.get("day", 0))
	var day_lbl: Label = Label.new()
	day_lbl.text = "[День %d]" % day_val
	day_lbl.add_theme_font_size_override("font_size", 11)
	day_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	day_lbl.custom_minimum_size = Vector2(75, 0)
	hbox.add_child(day_lbl)

	var kind_str: String = str(item.get("kind", "advice"))
	var icon_key: String = "advice"
	var kind_color: Color = Color(0.8, 0.8, 0.8)
	match kind_str:
		"war":
			icon_key = "commander"
			kind_color = Color(1.0, 0.35, 0.35)
		"peace":
			icon_key = "fox"
			kind_color = Color(0.4, 0.9, 0.4)
		"law":
			icon_key = "scroll"
			kind_color = Color(0.9, 0.75, 0.3)
		"province":
			icon_key = "target"
			kind_color = Color(0.4, 0.8, 1.0)
		"advice":
			icon_key = "advice"
			kind_color = Color(1.0, 0.85, 0.3)
		"crisis":
			icon_key = "threat"
			kind_color = Color(1.0, 0.5, 0.2)

	var badge_box: HBoxContainer = IconsScript.create_icon_row(icon_key, kind_str.to_upper(), 10, kind_color, kind_color, Vector2(14, 14))
	badge_box.custom_minimum_size = Vector2(95, 0)
	hbox.add_child(badge_box)

	var text_lbl: Label = Label.new()
	text_lbl.text = str(item.get("text", ""))
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(text_lbl)
