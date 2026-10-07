# ui/tab_plans.gd
# Вкладка «Планы»: дерево/список планов, шаги, условия, создание, пересборка с векторными SVG-иконками и Safe Zone.

extends HBoxContainer

signal new_plan_requested(goal_text: String)
signal rebuild_plan_requested(plan_id: String)
signal show_on_map_requested(country_name: String)

var mod_ref: PaxMod = null
var game_ref: PaxGame = null
var store_ref: RefCounted = null

var _plans_list: ItemList = null
var _details_scroll: ScrollContainer = null
var _details_box: VBoxContainer = null
var _selected_plan_id: String = ""

# Диалог создания плана
var _new_plan_dialog: PanelContainer = null
var _goal_edit: LineEdit = null

const DragResizableScript = preload("res://mods/strategist/lib/drag_resizable.gd")
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
		if store_ref.has_signal("plan_updated"):
			store_ref.connect("plan_updated", func(_p: Dictionary) -> void: refresh())
		if store_ref.has_signal("step_completed"):
			store_ref.connect("step_completed", func(_id: String, _s: Dictionary) -> void: refresh())

func refresh() -> void:
	_update_plans_list()
	_update_details_view()

func _build_ui() -> void:
	add_theme_constant_override("separation", 12)

	# Левая колонка: список планов и кнопка создания
	var left_box: VBoxContainer = VBoxContainer.new()
	left_box.custom_minimum_size = Vector2(240, 0)
	left_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(left_box)

	var list_header: HBoxContainer = HBoxContainer.new()
	list_header.add_theme_constant_override("separation", 6)
	left_box.add_child(list_header)

	var list_title_box: HBoxContainer = IconsScript.create_icon_row("target", mod_ref.tr_key("strat_plans_title") if mod_ref != null else "Планы", 14, Color(1.0, 0.85, 0.35), Color(1.0, 0.85, 0.35))
	list_title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_header.add_child(list_title_box)

	var new_btn: Button = Button.new()
	new_btn.text = mod_ref.tr_key("strat_new_plan") if mod_ref != null else "Новый план"
	new_btn.icon = IconsScript.get_icon("target")
	new_btn.pressed.connect(_open_new_plan_dialog)
	list_header.add_child(new_btn)

	_plans_list = ItemList.new()
	_plans_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_plans_list.item_selected.connect(_on_plan_selected)
	left_box.add_child(_plans_list)

	# Правая колонка: детали выбранного плана
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(right_panel)

	_details_scroll = ScrollContainer.new()
	_details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_details_scroll)

	_details_box = VBoxContainer.new()
	_details_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_details_box.add_theme_constant_override("separation", 10)
	_details_scroll.add_child(_details_box)

	_update_plans_list()
	_update_details_view()

func _update_plans_list() -> void:
	if _plans_list == null or store_ref == null:
		return
	_plans_list.clear()

	var plans: Array = store_ref.get("plans") if store_ref.get("plans") != null else []
	var active_id: String = str(store_ref.get("active_plan_id")) if store_ref.get("active_plan_id") != null else ""

	for i in range(plans.size()):
		var p_any: Variant = plans[i]
		if not (p_any is Dictionary):
			continue
		var p: Dictionary = p_any
		var p_id: String = str(p.get("id", ""))
		var title: String = str(p.get("title", "План"))
		var status: String = str(p.get("status", "active"))
		var prefix: String = "[★] " if p_id == active_id else "[•] "
		if status == "done":
			prefix = "[✓] "
		elif status == "archived":
			prefix = "[архив] "

		_plans_list.add_item(prefix + title)
		_plans_list.set_item_metadata(i, p_id)

		if _selected_plan_id.is_empty() and p_id == active_id:
			_selected_plan_id = p_id
			_plans_list.select(i)
		elif _selected_plan_id == p_id:
			_plans_list.select(i)

func _on_plan_selected(index: int) -> void:
	_selected_plan_id = str(_plans_list.get_item_metadata(index))
	_update_details_view()

func _update_details_view() -> void:
	if _details_box == null:
		return
	for child in _details_box.get_children():
		child.queue_free()

	var plan: Dictionary = _find_plan_by_id(_selected_plan_id)
	if plan.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = mod_ref.tr_key("strat_select_plan") if mod_ref != null else "Выберите план"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_details_box.add_child(empty_lbl)
		return

	# Заголовок плана и кнопки действий
	var header_bar: HBoxContainer = HBoxContainer.new()
	_details_box.add_child(header_bar)

	var title_lbl: Label = Label.new()
	title_lbl.text = str(plan.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	header_bar.add_child(title_lbl)

	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_bar.add_child(spacer)

	var rebuild_btn: Button = Button.new()
	rebuild_btn.text = mod_ref.tr_key("strat_rebuild_plan") if mod_ref != null else "Пересобрать"
	rebuild_btn.icon = IconsScript.get_icon("refresh")
	rebuild_btn.pressed.connect(func() -> void:
		emit_signal("rebuild_plan_requested", _selected_plan_id)
	)
	header_bar.add_child(rebuild_btn)

	var archive_btn: Button = Button.new()
	archive_btn.text = mod_ref.tr_key("strat_archive_plan") if mod_ref != null else "В архив"
	archive_btn.pressed.connect(func() -> void:
		plan["status"] = "archived"
		_update_plans_list()
		_update_details_view()
	)
	header_bar.add_child(archive_btn)

	# Цель и параметры
	var goal_text: String = str(plan.get("goal", ""))
	var horizon: int = int(plan.get("horizon_days", 365))
	var created: int = int(plan.get("created_day", 0))

	var info_lbl: Label = Label.new()
	info_lbl.text = "%s: %s\n%s: %d %s (с %d дня)" % [
		mod_ref.tr_key("strat_goal") if mod_ref != null else "Цель",
		goal_text,
		mod_ref.tr_key("strat_horizon") if mod_ref != null else "Горизонт",
		horizon,
		mod_ref.tr_key("strat_days") if mod_ref != null else "дн.",
		created
	]
	info_lbl.add_theme_font_size_override("font_size", 12)
	_details_box.add_child(info_lbl)

	# Прогресс-бар выполнения плана
	var steps: Array = plan.get("steps", [])
	var done_count: int = 0
	for st_any in steps:
		if st_any is Dictionary and str(st_any.get("status", "")) == "done":
			done_count += 1
	var total_count: int = steps.size()
	var pct: float = (float(done_count) / float(total_count) * 100.0) if total_count > 0 else 0.0

	var prog_head: Label = Label.new()
	prog_head.text = "Прогресс стратегии: %d/%d (%0.0f%%)" % [done_count, total_count, pct]
	prog_head.add_theme_font_size_override("font_size", 11)
	prog_head.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5) if pct >= 100.0 else Color(0.8, 0.85, 0.9))
	_details_box.add_child(prog_head)

	var prog_bar: ProgressBar = ProgressBar.new()
	prog_bar.custom_minimum_size = Vector2(0, 8)
	prog_bar.show_percentage = false
	prog_bar.min_value = 0.0
	prog_bar.max_value = 100.0
	prog_bar.value = pct
	_details_box.add_child(prog_bar)

	# Шаги плана
	var steps_head_box: HBoxContainer = IconsScript.create_icon_row("scroll", mod_ref.tr_key("strat_steps") if mod_ref != null else "Шаги плана", 14, Color(0.95, 0.95, 0.95), Color(1.0, 0.85, 0.35))
	_details_box.add_child(steps_head_box)

	for i in range(steps.size()):
		var st_any: Variant = steps[i]
		if not (st_any is Dictionary):
			continue
		var st: Dictionary = st_any
		_add_step_card(_details_box, st, plan)

	# Риски и резерв
	var risks: Array = plan.get("risks", [])
	if not risks.is_empty():
		var risks_box: PanelContainer = PanelContainer.new()
		_details_box.add_child(risks_box)
		var r_vbox: VBoxContainer = VBoxContainer.new()
		risks_box.add_child(r_vbox)

		var r_head: HBoxContainer = IconsScript.create_icon_row("threat", mod_ref.tr_key("strat_risks") if mod_ref != null else "Риски", 12, Color(1.0, 0.45, 0.4), Color(1.0, 0.45, 0.4))
		r_vbox.add_child(r_head)

		for r_text in risks:
			var r_lbl: Label = Label.new()
			r_lbl.text = "• " + str(r_text)
			r_lbl.add_theme_font_size_override("font_size", 11)
			r_vbox.add_child(r_lbl)

	var reserve_str: String = str(plan.get("reserve", ""))
	if not reserve_str.is_empty():
		var res_box: HBoxContainer = IconsScript.create_icon_row("fortress", "%s: %s" % [mod_ref.tr_key("strat_reserve") if mod_ref != null else "План Б", reserve_str], 11, Color(0.4, 0.8, 0.9), Color(0.4, 0.8, 0.9))
		_details_box.add_child(res_box)

func _add_step_card(parent: Control, step: Dictionary, _plan: Dictionary) -> void:
	var card: PanelContainer = PanelContainer.new()
	parent.add_child(card)

	var vbox: VBoxContainer = VBoxContainer.new()
	card.add_child(vbox)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	vbox.add_child(top_row)

	var step_num: int = int(step.get("n", 1))
	var step_what: String = str(step.get("what", ""))
	var step_status: String = str(step.get("status", "pending"))

	var status_icon_key: String = "hourglass"
	var status_color: Color = Color(0.8, 0.8, 0.8)
	if step_status == "done":
		status_icon_key = "check"
		status_color = Color(0.3, 0.9, 0.4)
	elif step_status == "failed":
		status_icon_key = "cross"
		status_color = Color(0.9, 0.3, 0.3)
	elif step_status == "stalled":
		status_icon_key = "hourglass"
		status_color = Color(0.95, 0.65, 0.2)

	var st_icon: TextureRect = IconsScript.create_icon_rect(status_icon_key, Vector2(14, 14), Color.WHITE)
	top_row.add_child(st_icon)

	var name_lbl: Label = Label.new()
	name_lbl.text = "%d. %s" % [step_num, step_what]
	name_lbl.add_theme_color_override("font_color", status_color)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_lbl)

	var status_key: String = "strat_status_" + step_status
	var status_lbl: Label = Label.new()
	status_lbl.text = mod_ref.tr_key(status_key) if mod_ref != null else step_status
	status_lbl.add_theme_font_size_override("font_size", 11)
	top_row.add_child(status_lbl)

	var why_str: String = str(step.get("why", ""))
	if not why_str.is_empty():
		var why_lbl: Label = Label.new()
		why_lbl.text = "%s: %s" % [mod_ref.tr_key("strat_step_why") if mod_ref != null else "Зачем", why_str]
		why_lbl.add_theme_font_size_override("font_size", 11)
		why_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(why_lbl)

	var check: Dictionary = step.get("check", {})
	var check_kind: String = str(check.get("kind", "manual"))
	if check_kind == "manual" and step_status == "pending":
		var manual_btn: Button = Button.new()
		manual_btn.text = mod_ref.tr_key("strat_manual_done_btn") if mod_ref != null else "Отметить выполненным"
		manual_btn.icon = IconsScript.get_icon("check")
		manual_btn.pressed.connect(func() -> void:
			step["status"] = "done"
			if game_ref != null:
				step["done_day"] = game_ref.day()
			if store_ref != null and store_ref.has_method("notify_step_completed"):
				store_ref.call("notify_step_completed", _selected_plan_id, step)
			_update_details_view()
		)
		vbox.add_child(manual_btn)

func _find_plan_by_id(id_val: String) -> Dictionary:
	if store_ref == null or id_val.is_empty():
		return {}
	var plans: Array = store_ref.get("plans") if store_ref.get("plans") != null else []
	for p_any in plans:
		if p_any is Dictionary:
			var p: Dictionary = p_any
			if str(p.get("id", "")) == id_val:
				return p
	return {}

func _open_new_plan_dialog() -> void:
	if _new_plan_dialog != null:
		_new_plan_dialog.queue_free()

	_new_plan_dialog = PanelContainer.new()
	_new_plan_dialog.custom_minimum_size = Vector2(540, 380)
	_new_plan_dialog.size = Vector2(540, 380)
	_new_plan_dialog.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	sb.border_color = Color(0.24, 0.36, 0.52, 0.90)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 14
	_new_plan_dialog.add_theme_stylebox_override("panel", sb)

	if game_ref != null and game_ref.hud_layer() != null:
		game_ref.hud_layer().add_child(_new_plan_dialog)
	else:
		add_child(_new_plan_dialog)

	var vp_size: Vector2 = get_viewport_rect().size
	_new_plan_dialog.position = Vector2(
		maxf(16.0, (vp_size.x - 540.0) * 0.5),
		maxf(50.0, (vp_size.y - 380.0) * 0.5)
	)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_new_plan_dialog.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	# Заголовочная плашка-ручка для перетаскивания (Drag Bar)
	var header_bar: PanelContainer = PanelContainer.new()
	header_bar.custom_minimum_size = Vector2(0, 28)
	header_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var h_sb: StyleBoxFlat = StyleBoxFlat.new()
	h_sb.bg_color = Color(0.12, 0.16, 0.24, 0.8)
	h_sb.set_corner_radius_all(4)
	header_bar.add_theme_stylebox_override("panel", h_sb)
	vbox.add_child(header_bar)

	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_theme_constant_override("separation", 6)
	header_bar.add_child(h_box)

	var drag_icon: TextureRect = IconsScript.create_icon_rect("target", Vector2(16, 16), Color(1.0, 0.85, 0.4))
	h_box.add_child(drag_icon)

	var title: Label = Label.new()
	title.text = mod_ref.tr_key("strat_new_plan_title") if mod_ref != null else "Новый стратегический план"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_child(title)

	var prompt_lbl: Label = Label.new()
	prompt_lbl.text = mod_ref.tr_key("strat_new_plan_prompt") if mod_ref != null else "Укажите цель:"
	prompt_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(prompt_lbl)

	_goal_edit = LineEdit.new()
	_goal_edit.placeholder_text = "например: Отразить нападение и захватить приграничную провинцию"
	vbox.add_child(_goal_edit)

	# Быстрые подсказки на основе топ-угроз/возможностей
	var chips_box: VBoxContainer = VBoxContainer.new()
	chips_box.add_theme_constant_override("separation", 4)
	chips_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(chips_box)

	var stances: Dictionary = store_ref.get("stances") if store_ref != null and store_ref.get("stances") != null else {}
	var threat_name: String = ""
	var opp_name: String = ""

	for c_name in stances.keys():
		var s: Dictionary = stances[c_name]
		if threat_name.is_empty() and float(s.get("threat_index", 0.0)) > 40.0:
			threat_name = str(c_name)
		if opp_name.is_empty() and float(s.get("opportunity_index", 0.0)) > 30.0:
			opp_name = str(c_name)

	if not threat_name.is_empty():
		var t_chip: Button = Button.new()
		var t_fmt: String = mod_ref.tr_key("strat_quick_goal_threat") if mod_ref != null else "Отразить угрозу: %s"
		t_chip.text = t_fmt % threat_name
		t_chip.icon = IconsScript.get_icon("threat")
		t_chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		t_chip.pressed.connect(func() -> void:
			_goal_edit.text = t_chip.text
		)
		chips_box.add_child(t_chip)

	if not opp_name.is_empty():
		var o_chip: Button = Button.new()
		var o_fmt: String = mod_ref.tr_key("strat_quick_goal_opp") if mod_ref != null else "Использовать возможность: %s"
		o_chip.text = o_fmt % opp_name
		o_chip.icon = IconsScript.get_icon("opportunity")
		o_chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
		o_chip.pressed.connect(func() -> void:
			_goal_edit.text = o_chip.text
		)
		chips_box.add_child(o_chip)

	var econ_chip: Button = Button.new()
	econ_chip.text = mod_ref.tr_key("strat_quick_goal_econ") if mod_ref != null else "Укрепить экономику и запасы"
	econ_chip.icon = IconsScript.get_icon("fortress")
	econ_chip.alignment = HORIZONTAL_ALIGNMENT_LEFT
	econ_chip.pressed.connect(func() -> void:
		_goal_edit.text = econ_chip.text
	)
	chips_box.add_child(econ_chip)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	var confirm_btn: Button = Button.new()
	confirm_btn.text = mod_ref.tr_key("strat_create_plan_btn") if mod_ref != null else "Поручить разработку"
	confirm_btn.icon = IconsScript.get_icon("order")
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	confirm_btn.pressed.connect(func() -> void:
		var g_text: String = _goal_edit.text.strip_edges()
		_new_plan_dialog.queue_free()
		_new_plan_dialog = null
		emit_signal("new_plan_requested", g_text)
	)
	btn_row.add_child(confirm_btn)

	var cancel_btn: Button = Button.new()
	cancel_btn.text = mod_ref.tr_key("strat_cancel") if mod_ref != null else "Отмена"
	cancel_btn.pressed.connect(func() -> void:
		_new_plan_dialog.queue_free()
		_new_plan_dialog = null
	)
	btn_row.add_child(cancel_btn)

	DragResizableScript.setup_window(_new_plan_dialog, header_bar, Vector2(480, 320), 48.0, 40.0, 16.0, 16.0)
