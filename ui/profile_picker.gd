# ui/profile_picker.gd
# Полноэкранный модальный диалог выбора профиля стратегического советника с премиальным тактическим дизайном.

extends Control

signal profile_selected(profile_id: String)

var mod_ref: PaxMod = null
var _panel: PanelContainer = null

const DragResizableScript = preload("res://mods/strategist/lib/drag_resizable.gd")
const IconsScript = preload("res://mods/strategist/lib/icons.gd")

func _init(mod: PaxMod = null) -> void:
	mod_ref = mod
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Полупрозрачный глубокий фон с размытием
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.02, 0.04, 0.07, 0.78)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Главная панель окна
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 500)
	_panel.size = Vector2(760, 500)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.14, 0.98)
	sb.border_color = Color(0.24, 0.36, 0.52, 0.90)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# Начальное центрирование
	var vp_size: Vector2 = get_viewport_rect().size
	_panel.position = Vector2(
		maxf(16.0, (vp_size.x - 760.0) * 0.5),
		maxf(50.0, (vp_size.y - 500.0) * 0.5)
	)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	_panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(vbox)

	# 1. Заголовочная плашка-ручка для перетаскивания (Drag Bar)
	var header_bar: PanelContainer = PanelContainer.new()
	header_bar.custom_minimum_size = Vector2(0, 34)
	header_bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	var h_sb: StyleBoxFlat = StyleBoxFlat.new()
	h_sb.bg_color = Color(0.11, 0.15, 0.24, 0.9)
	h_sb.border_color = Color(0.22, 0.32, 0.46, 0.6)
	h_sb.set_border_width_all(1)
	h_sb.set_corner_radius_all(5)
	header_bar.add_theme_stylebox_override("panel", h_sb)
	vbox.add_child(header_bar)

	var h_margin: MarginContainer = MarginContainer.new()
	h_margin.add_theme_constant_override("margin_left", 10)
	h_margin.add_theme_constant_override("margin_right", 10)
	h_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	header_bar.add_child(h_margin)

	var h_box: HBoxContainer = HBoxContainer.new()
	h_box.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_theme_constant_override("separation", 8)
	h_margin.add_child(h_box)

	var cap_icon: TextureRect = IconsScript.create_icon_rect("capitol", Vector2(18, 18), Color(1.0, 0.85, 0.4))
	h_box.add_child(cap_icon)

	var title_lbl: Label = Label.new()
	title_lbl.text = (mod_ref.tr_key("strat_profile_picker_title") if mod_ref != null else "Выберите профиль советника").to_upper()
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_child(title_lbl)

	var drag_hint: Label = Label.new()
	drag_hint.text = "[перетаскивание ≡]"
	drag_hint.add_theme_font_size_override("font_size", 10)
	drag_hint.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72))
	drag_hint.mouse_filter = Control.MOUSE_FILTER_PASS
	h_box.add_child(drag_hint)

	# 2. Описание
	var desc_lbl: Label = Label.new()
	desc_lbl.text = mod_ref.tr_key("strat_profile_picker_desc") if mod_ref != null else "Профиль определяет приоритеты анализа, тон рекомендаций и акценты при формулировании планов."
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.80, 0.88))
	vbox.add_child(desc_lbl)

	# 3. Сетка 2x2 просторных карточек профилей
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	vbox.add_child(grid)

	_add_profile_card(grid, "akademik", "strat_profile_akademik", "strat_profile_akademik_desc", Color(1.0, 0.85, 0.35), "ЭКОНОМИКА И РЕСУРСЫ")
	_add_profile_card(grid, "komandir", "strat_profile_komandir", "strat_profile_komandir_desc", Color(1.0, 0.40, 0.40), "ВОЕННАЯ СИЛА И КОНТРОЛЬ")
	_add_profile_card(grid, "lis", "strat_profile_lis", "strat_profile_lis_desc", Color(1.0, 0.68, 0.28), "ДИПЛОМАТИЯ И МАНЕВРЫ")
	_add_profile_card(grid, "orakul", "strat_profile_orakul", "strat_profile_orakul_desc", Color(0.78, 0.55, 1.0), "КРИЗИСЫ И АНАЛОГИИ")

	# 4. Нижняя строка
	var bottom_row: HBoxContainer = HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom_row)

	var close_btn: Button = Button.new()
	close_btn.text = "Закрыть (выбрать позже)"
	close_btn.custom_minimum_size = Vector2(200, 32)
	close_btn.pressed.connect(func() -> void:
		queue_free()
	)
	bottom_row.add_child(close_btn)

	DragResizableScript.setup_window(_panel, header_bar, Vector2(680, 460), 48.0, 40.0, 16.0, 16.0)

func _add_profile_card(parent: Control, profile_key: String, title_tr: String, desc_tr: String, accent_color: Color, tag_text: String) -> void:
	var card_panel: PanelContainer = PanelContainer.new()
	card_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_panel.custom_minimum_size = Vector2(330, 130)

	var sb_normal: StyleBoxFlat = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.13, 0.20, 0.95)
	sb_normal.border_color = Color(0.22, 0.32, 0.46, 0.70)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(6)
	card_panel.add_theme_stylebox_override("panel", sb_normal)

	var c_margin: MarginContainer = MarginContainer.new()
	c_margin.add_theme_constant_override("margin_left", 14)
	c_margin.add_theme_constant_override("margin_top", 12)
	c_margin.add_theme_constant_override("margin_right", 14)
	c_margin.add_theme_constant_override("margin_bottom", 12)
	card_panel.add_child(c_margin)

	var content_vbox: VBoxContainer = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 8)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_margin.add_child(content_vbox)

	# Верхняя строка карточки: Иконка + Заголовок + Тэг
	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 10)
	content_vbox.add_child(top_row)

	var p_icon: TextureRect = IconsScript.create_icon_rect(profile_key, Vector2(32, 32), Color.WHITE)
	top_row.add_child(p_icon)

	var titles_vbox: VBoxContainer = VBoxContainer.new()
	titles_vbox.add_theme_constant_override("separation", 2)
	titles_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(titles_vbox)

	var p_title: Label = Label.new()
	p_title.text = mod_ref.tr_key(title_tr) if mod_ref != null else profile_key
	p_title.add_theme_font_size_override("font_size", 14)
	p_title.add_theme_color_override("font_color", accent_color)
	titles_vbox.add_child(p_title)

	var tag_lbl: Label = Label.new()
	tag_lbl.text = tag_text
	tag_lbl.add_theme_font_size_override("font_size", 9)
	tag_lbl.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78))
	titles_vbox.add_child(tag_lbl)

	# Описание
	var p_desc: Label = Label.new()
	p_desc.text = mod_ref.tr_key(desc_tr) if mod_ref != null else ""
	p_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	p_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_desc.add_theme_font_size_override("font_size", 11)
	p_desc.add_theme_color_override("font_color", Color(0.80, 0.86, 0.92))
	content_vbox.add_child(p_desc)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(spacer)

	# Кнопка выбора
	var select_btn: Button = Button.new()
	select_btn.text = "Выбрать профиль"
	select_btn.custom_minimum_size = Vector2(0, 26)
	select_btn.add_theme_font_size_override("font_size", 11)
	select_btn.pressed.connect(func() -> void:
		if mod_ref != null:
			mod_ref.set_setting("profile", profile_key)
		emit_signal("profile_selected", profile_key)
	)
	content_vbox.add_child(select_btn)

	parent.add_child(card_panel)
