# ui/tab_advice.gd
# Вкладка «Советы»: лента оперативных рекомендаций советника с приоритетами, кнопкой «⚡ Отдать приказ» и SVG-иконками.

extends ScrollContainer

signal accept_advice_requested(advice_item: Dictionary)
signal execute_order_requested(order_action: Dictionary)

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _feed_box: VBoxContainer = null

const IconsScript = preload("res://mods/strategist/lib/icons.gd")

func _init(mod: PaxMod = null, game: PaxGame = null, store: RefCounted = null) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store

func _ready() -> void:
	_build_ui()
	_wire_signals()

func _wire_signals() -> void:
	if store_ref != null and store_ref.has_signal("advice_added"):
		store_ref.connect("advice_added", func(_adv: Dictionary) -> void: refresh())

func refresh() -> void:
	_update_feed()

func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(margin)

	_feed_box = VBoxContainer.new()
	_feed_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_box.add_theme_constant_override("separation", 12)
	margin.add_child(_feed_box)

	_update_feed()

func _update_feed() -> void:
	if _feed_box == null:
		return
	for child in _feed_box.get_children():
		child.queue_free()

	var head: HBoxContainer = IconsScript.create_icon_row("advice", mod_ref.tr_key("strat_advice_feed") if mod_ref != null else "Лента рекомендаций советника", 14, Color(0.95, 0.95, 0.95), Color(1.0, 0.85, 0.35))
	_feed_box.add_child(head)

	var advice_list: Array = store_ref.get("advice") if store_ref != null and store_ref.get("advice") != null else []
	var count: int = 0

	for item_any in advice_list:
		if not (item_any is Dictionary):
			continue
		var item: Dictionary = item_any
		var status: String = str(item.get("status", "open"))
		if status == "ignored":
			continue

		_add_advice_card(_feed_box, item)
		count += 1

	if count == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = mod_ref.tr_key("strat_no_advice") if mod_ref != null else "Новых рекомендаций нет"
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_feed_box.add_child(empty_lbl)

func _add_advice_card(parent: Control, item: Dictionary) -> void:
	var card: PanelContainer = PanelContainer.new()
	parent.add_child(card)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Верхняя строка: день и приоритет
	var top_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(top_row)

	var day_val: int = int(item.get("day", 0))
	var day_lbl: Label = Label.new()
	day_lbl.text = "День %d" % day_val
	day_lbl.add_theme_font_size_override("font_size", 11)
	day_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	top_row.add_child(day_lbl)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)

	var prio: String = str(item.get("priority", "medium"))
	var prio_key: String = "strat_priority_" + prio
	var prio_color: Color = Color(0.8, 0.8, 0.8)
	if prio == "high":
		prio_color = Color(1.0, 0.4, 0.3)
	elif prio == "medium":
		prio_color = Color(1.0, 0.8, 0.3)
	elif prio == "low":
		prio_color = Color(0.4, 0.8, 0.9)

	var prio_lbl: Label = Label.new()
	prio_lbl.text = mod_ref.tr_key(prio_key) if mod_ref != null else prio
	prio_lbl.add_theme_font_size_override("font_size", 11)
	prio_lbl.add_theme_color_override("font_color", prio_color)
	top_row.add_child(prio_lbl)

	# Текст совета
	var text_lbl: Label = Label.new()
	text_lbl.text = str(item.get("text", ""))
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(text_lbl)

	# Кнопки действий
	var status: String = str(item.get("status", "open"))
	var order_action: Dictionary = item.get("order_action", {})

	if status == "open":
		var btn_row: HBoxContainer = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)
		vbox.add_child(btn_row)

		# Кнопка «Отдать приказ» (Feature 2)
		if not order_action.is_empty():
			var order_btn: Button = Button.new()
			order_btn.text = mod_ref.tr_key("strat_execute_order") if mod_ref != null else "Отдать приказ"
			order_btn.icon = IconsScript.get_icon("order")
			order_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			order_btn.pressed.connect(func() -> void:
				emit_signal("execute_order_requested", order_action)
				item["status"] = "done"
				_update_feed()
			)
			btn_row.add_child(order_btn)

		var accept_btn: Button = Button.new()
		accept_btn.text = mod_ref.tr_key("strat_accept") if mod_ref != null else "Принять в план"
		accept_btn.icon = IconsScript.get_icon("check")
		accept_btn.pressed.connect(func() -> void:
			item["status"] = "done"
			emit_signal("accept_advice_requested", item)
			_update_feed()
		)
		btn_row.add_child(accept_btn)

		var postpone_btn: Button = Button.new()
		postpone_btn.text = mod_ref.tr_key("strat_postpone") if mod_ref != null else "Отложить"
		postpone_btn.icon = IconsScript.get_icon("hourglass")
		postpone_btn.pressed.connect(func() -> void:
			item["status"] = "postponed"
			_update_feed()
		)
		btn_row.add_child(postpone_btn)

		var ignore_btn: Button = Button.new()
		ignore_btn.text = mod_ref.tr_key("strat_ignore") if mod_ref != null else "Игнорировать"
		ignore_btn.icon = IconsScript.get_icon("cross")
		ignore_btn.pressed.connect(func() -> void:
			item["status"] = "ignored"
			_update_feed()
		)
		btn_row.add_child(ignore_btn)
	elif status == "done":
		var done_box: HBoxContainer = IconsScript.create_icon_row("check", "Принято в работу / Выполнено", 11, Color(0.4, 0.9, 0.4), Color(0.4, 0.9, 0.4))
		vbox.add_child(done_box)
	elif status == "postponed":
		var post_box: HBoxContainer = IconsScript.create_icon_row("hourglass", "Отложено", 11, Color(0.9, 0.7, 0.3), Color(0.9, 0.7, 0.3))
		vbox.add_child(post_box)
