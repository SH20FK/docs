# lib/map_view.gd
# Геополитический компас: нормализация ОТНОСИТЕЛЬНО ПИВОТА (а не min/max),
# узлы заполняют всё полотно, пивот всегда в центре, расширенная таблица кодов.
extends Control

signal country_clicked(country_name: String)
signal country_hovered(country_name: String)
signal quadrant_stats_updated(threats_count: int, pillars_count: int, clients_count: int, targets_count: int)

const StancesScript = preload("res://mods/strategist/lib/stances.gd")

var game_ref: PaxGame = null
var mod_ref: PaxMod = null
var store_ref: RefCounted = null
var stances_data: Dictionary = {}
var active_plan_data: Dictionary = {}

var axis_x: String = "relation"
var axis_y: String = "power"
var pivot_median: bool = true
var show_edges: bool = false
var filter_hostile_only: bool = false
var filter_border_only: bool = false

var selected_country: String = ""
var hovered_country: String = ""

var _current_positions: Dictionary = {}
var _target_positions: Dictionary = {}
var _node_radii: Dictionary = {}
var _node_rects: Dictionary = {}
var _visible_list: Array = []

var _pulse_time: float = 0.0
var _selection_flash: float = 0.0
var _last_plot_rect: Rect2 = Rect2()

# Нормализация: пивот + максимальное отклонение от него
var _pivot_x: float = 0.0
var _pivot_y: float = 50.0
var _max_dev_x: float = 1.0
var _max_dev_y: float = 50.0

const TIER_COLORS := [
	Color(0.25, 0.92, 0.45), Color(0.40, 0.85, 1.00), Color(0.62, 0.70, 0.80),
	Color(1.00, 0.70, 0.25), Color(0.95, 0.35, 0.30), Color(1.00, 0.22, 0.22),
]
const TIER_FILLS := [
	Color(0.05, 0.20, 0.10, 0.96), Color(0.06, 0.16, 0.24, 0.96), Color(0.10, 0.14, 0.22, 0.96),
	Color(0.18, 0.14, 0.06, 0.96), Color(0.20, 0.08, 0.10, 0.96), Color(0.24, 0.05, 0.07, 0.98),
]

const CODE_TABLE := {
	"Россия": "RU", "США": "US", "Китай": "CN", "Франция": "FR",
	"Германия": "DE", "Япония": "JP", "Индия": "IN", "Казахстан": "KZ",
	"Монголия": "MN", "Афганистан": "AF", "Украина": "UA", "Беларусь": "BY",
	"Турция": "TR", "Иран": "IR", "Киргизия": "KG", "Непал": "NP",
	"Пакистан": "PK", "Узбекистан": "UZ", "Северная Корея": "KP",
	"Южная Корея": "KR", "Великобритания": "GB", "Италия": "IT",
	"Польша": "PL", "Испания": "ES", "Канада": "CA", "Бразилия": "BR",
	"Австралия": "AU", "Египет": "EG", "Саудовская Аравия": "SA",
	"Израиль": "IL", "Греция": "GR", "Швеция": "SE", "Норвегия": "NO",
	"Финляндия": "FI", "Дания": "DK", "Нидерланды": "NL", "Бельгия": "BE",
	"Швейцария": "CH", "Австрия": "AT", "Чехия": "CZ", "Венгрия": "HU",
	"Румыния": "RO", "Болгария": "BG", "Сербия": "RS", "Хорватия": "HR",
	"Армения": "AM", "Грузия": "GE", "Азербайджан": "AZ", "Таджикистан": "TJ",
	"Туркменистан": "TM", "Вьетнам": "VN", "Таиланд": "TH", "Индонезия": "ID",
	"Малайзия": "MY", "Филиппины": "PH", "Мексика": "MX", "Аргентина": "AR",
	"Чили": "CL", "Перу": "PE", "Колумбия": "CO", "Венесуэла": "VE",
	"ЮАР": "ZA", "Нигерия": "NG", "Эфиопия": "ET", "Кения": "KE",
	"Алжир": "DZ", "Марокко": "MA", "Ливия": "LY", "Ирак": "IQ",
	"Сирия": "SY", "Ливан": "LB", "Иордания": "JO", "Йемен": "YE",
	"Мьянма": "MM", "Лаос": "LA", "Камбоджа": "KH", "Бангладеш": "BD",
	"Шри-Ланка": "LK", "Бутан": "BT", "Мальдивы": "MV",
	"Новая Зеландия": "NZ", "Ирландия": "IE", "Португалия": "PT",
	"Словакия": "SK", "Словения": "SI", "Литва": "LT", "Латвия": "LV",
	"Эстония": "EE", "Молдова": "MD", "Албания": "AL", "Македония": "MK",
	"Босния": "BA", "Черногория": "ME", "Косово": "XK", "Кипр": "CY",
	"Тунис": "TN", "Судан": "SD", "Сомали": "SO", "Танзания": "TZ",
	"Уганда": "UG", "Гана": "GH", "Кот-д’Ивуар": "CI", "Сенегал": "SN",
	"Мали": "ML", "Чад": "TD", "Нигер": "NE", "Камерун": "CM",
	"Ангола": "AO", "Мозамбик": "MZ", "Зимбабве": "ZW", "Замбия": "ZM",
	"Намибия": "NA", "Ботсвана": "BW", "Мадагаскар": "MG",
	"Оман": "OM", "ОАЭ": "AE", "Катар": "QA", "Кувейт": "KW", "Бахрейн": "BH",
	"Куба": "CU", "Гватемала": "GT", "Гондурас": "HN",
	"Никарагуа": "NI", "Коста-Рика": "CR", "Панама": "PA", "Уругвай": "UY",
	"Парагвай": "PY", "Боливия": "BO", "Эквадор": "EC",
}

var _flags_dict: Dictionary = {}
var _flags_loaded: bool = false
var _flag_textures: Dictionary = {}

func _init() -> void:
	custom_minimum_size = Vector2(560, 460)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_flags()
	resized.connect(_recalc)

func _load_flags() -> void:
	if _flags_loaded:
		return
	_flags_loaded = true
	var json_data: Variant = Pax.json("res://data/flags/countries.json")
	if json_data is Dictionary:
		var d: Dictionary = json_data
		if d.has("countries") and d["countries"] is Dictionary:
			_flags_dict = d["countries"]
		else:
			_flags_dict = d

func _get_flag_texture(c_name: String) -> Texture2D:
	if _flag_textures.has(c_name):
		return _flag_textures[c_name]
	
	_load_flags()
	
	var flag_id: String = ""
	if _flags_dict.has(c_name):
		flag_id = str(_flags_dict[c_name])
	elif _flags_dict.has("1939:" + c_name):
		flag_id = str(_flags_dict["1939:" + c_name])
	elif CODE_TABLE.has(c_name):
		flag_id = str(CODE_TABLE[c_name]).to_lower()
	else:
		flag_id = c_name.to_lower()
	
	if flag_id.is_empty():
		_flag_textures[c_name] = null
		return null
	
	var tex_path: String = "res://data/flags/countries/" + flag_id + ".png"
	var tex: Texture2D = Pax.texture(tex_path)
	_flag_textures[c_name] = tex
	return tex

func _process(delta: float) -> void:
	_pulse_time += delta
	if _selection_flash > 0.0:
		_selection_flash = maxf(0.0, _selection_flash - delta * 3.0)

	var moved: bool = false
	for c_name in _target_positions.keys():
		var t: Vector2 = _target_positions[c_name]
		if not _current_positions.has(c_name):
			_current_positions[c_name] = t
			moved = true
		else:
			var c: Vector2 = _current_positions[c_name]
			if c.distance_squared_to(t) > 0.25:
				_current_positions[c_name] = c.lerp(t, clampf(delta * 9.0, 0.0, 1.0))
				moved = true
			else:
				_current_positions[c_name] = t
	for k in _current_positions.keys():
		if not _target_positions.has(k):
			_current_positions.erase(k)
			moved = true

	# Перерисовка только если есть движение, пульс войны, или недавний выбор
	if moved or _selection_flash > 0.0 or _has_warring_node():
		queue_redraw()

func _has_warring_node() -> bool:
	for c in _visible_list:
		if bool(stances_data.get(c, {}).get("war", false)):
			return true
	return false

func set_data(mod: PaxMod, game: PaxGame, store: RefCounted) -> void:
	mod_ref = mod
	game_ref = game
	store_ref = store
	if store_ref != null:
		stances_data = store_ref.get("stances") if store_ref.get("stances") != null else {}
		active_plan_data = store_ref.call("get_active_plan") if store_ref.has_method("get_active_plan") else {}
		axis_x = str(store_ref.get("axis_x")) if store_ref.get("axis_x") != null else "relation"
		axis_y = str(store_ref.get("axis_y")) if store_ref.get("axis_y") != null else "power"
		pivot_median = bool(store_ref.get("pivot_median")) if store_ref.get("pivot_median") != null else true
		show_edges = bool(store_ref.get("show_edges")) if store_ref.get("show_edges") != null else false
		selected_country = str(store_ref.get("selected_country_on_map")) if store_ref.get("selected_country_on_map") != null else ""
	_recalc()

func set_axes(new_x: String, new_y: String) -> void:
	axis_x = new_x
	axis_y = new_y
	if store_ref != null:
		store_ref.set("axis_x", axis_x)
		store_ref.set("axis_y", axis_y)
	_recalc()

func set_show_edges(v: bool) -> void:
	show_edges = v
	if store_ref != null: store_ref.set("show_edges", show_edges)
	queue_redraw()

func set_pivot_median(v: bool) -> void:
	pivot_median = v
	if store_ref != null: store_ref.set("pivot_median", pivot_median)
	_recalc()

func select_country(c_name: String) -> void:
	selected_country = c_name
	_selection_flash = 1.0
	if store_ref != null:
		store_ref.call("set_map_selection", selected_country)
	emit_signal("country_clicked", selected_country)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var found: String = _find_country_at_pos(event.position)
		if found != hovered_country:
			hovered_country = found
			emit_signal("country_hovered", hovered_country)
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked: String = _find_country_at_pos(event.position)
		if not clicked.is_empty():
			select_country(clicked)

func _find_country_at_pos(pos: Vector2) -> String:
	for i in range(_visible_list.size() - 1, -1, -1):
		var c_name: String = _visible_list[i]
		if not _node_rects.has(c_name): continue
		if _node_rects[c_name].has_point(pos):
			return c_name
	return ""

# ─── Расчёт ───

func _recalc() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 50.0 or h < 50.0:
		return

	_visible_list = _get_active_countries_list()
	if _visible_list.is_empty():
		_target_positions.clear()
		_node_radii.clear()
		emit_signal("quadrant_stats_updated", 0, 0, 0, 0)
		queue_redraw()
		return

	var xs: Array = []
	var ys: Array = []
	for c_name in _visible_list:
		var s: Dictionary = stances_data.get(c_name, {})
		xs.append(StancesScript.get_axis_value(s, axis_x))
		ys.append(StancesScript.get_axis_value(s, axis_y))

	# ── КЛЮЧЕВОЕ: пивот и максимальное отклонение ОТ пивота ──
	_pivot_x = 0.0 if axis_x == "relation" else _median(xs)
	_pivot_y = 50.0 if axis_y == "power" else _median(ys)
	if not pivot_median:
		_pivot_x = 0.0 if axis_x == "relation" else 50.0
		_pivot_y = 0.0 if axis_y == "relation" else 50.0

	_max_dev_x = 0.001
	_max_dev_y = 0.001
	for i in range(xs.size()):
		_max_dev_x = maxf(_max_dev_x, absf(float(xs[i]) - _pivot_x))
		_max_dev_y = maxf(_max_dev_y, absf(float(ys[i]) - _pivot_y))

	# Радиусы
	_node_radii.clear()
	for c_name in _visible_list:
		var s: Dictionary = stances_data.get(c_name, {})
		var pw: float = float(s.get("power", float(s.get("provinces", 5)) * 3.0))
		var r: float = 18.0 + clampf(log(maxf(pw, 1.0)) / log(100.0) * 16.0, 0.0, 16.0)
		_node_radii[c_name] = r

	var plot := _plot_rect()
	_last_plot_rect = plot

	var px: Dictionary = {}
	for i in range(_visible_list.size()):
		px[_visible_list[i]] = _to_screen(float(xs[i]), float(ys[i]), plot)

	_resolve_overlaps(px, plot)
	_target_positions = px

	# Квадранты
	var th := 0; var pi := 0; var cl := 0; var ta := 0
	var me: String = game_ref.country() if game_ref != null else ""
	for i in range(_visible_list.size()):
		var c_name: String = _visible_list[i]
		if c_name == me: continue
		var on_ally: bool = float(xs[i]) >= _pivot_x
		var on_strong: bool = float(ys[i]) >= _pivot_y
		if on_strong and not on_ally: th += 1
		elif on_strong and on_ally: pi += 1
		elif not on_strong and on_ally: cl += 1
		else: ta += 1
	emit_signal("quadrant_stats_updated", th, pi, cl, ta)
	queue_redraw()

func _median(vals: Array) -> float:
	if vals.is_empty(): return 50.0
	var s: Array = vals.duplicate()
	s.sort()
	return float(s[s.size() / 2])

func _plot_rect() -> Rect2:
	var pad_l: float = 24.0
	var pad_r: float = 24.0
	var pad_t: float = 26.0
	var pad_b: float = 34.0
	return Rect2(
		pad_l, pad_t,
		maxf(100.0, size.x - pad_l - pad_r),
		maxf(100.0, size.y - pad_t - pad_b)
	)

func _to_screen(xv: float, yv: float, plot: Rect2) -> Vector2:
	# Нормализация ОТНОСИТЕЛЬНО ПИВОТА:
	# Для отношения: +1 (Союзник) СЛЕВА (Опоры/Клиенты), -1 (Враг) СПРАВА (Угрозы/Цели)
	var delta_x: float = (xv - _pivot_x) / (2.0 * _max_dev_x)
	var nx: float = 0.5 - delta_x if axis_x == "relation" else 0.5 + delta_x
	var ny: float = 0.5 + (yv - _pivot_y) / (2.0 * _max_dev_y)
	
	# Запас от краёв, чтобы узлы и подписи не срезались
	nx = clampf(nx, 0.07, 0.93)
	ny = clampf(ny, 0.08, 0.92)
	return Vector2(
		plot.position.x + nx * plot.size.x,
		plot.position.y + (1.0 - ny) * plot.size.y
	)

func _resolve_overlaps(pos: Dictionary, plot: Rect2) -> void:
	var names: Array = pos.keys()
	var iters: int = 80
	for _it in range(iters):
		var moved: bool = false
		for i in range(names.size()):
			for j in range(i + 1, names.size()):
				var a: String = names[i]
				var b: String = names[j]
				var pa: Vector2 = pos[a]
				var pb: Vector2 = pos[b]
				var ra: float = float(_node_radii.get(a, 20.0))
				var rb: float = float(_node_radii.get(b, 20.0))
				# Увеличенная дистанция для предотвращения наложения подписей
				var min_d: float = ra + rb + 26.0
				var d: float = pa.distance_to(pb)
				if d < min_d and d > 0.01:
					var push: float = (min_d - d) * 0.5
					var dir: Vector2 = (pb - pa).normalized()
					pos[a] = pa - dir * push
					pos[b] = pb + dir * push
					moved = true
				elif d <= 0.01:
					pos[a] = pa + Vector2(1.0, 0.5)
					moved = true
		for k in names:
			var p: Vector2 = pos[k]
			var r: float = float(_node_radii.get(k, 20.0))
			p.x = clampf(p.x, plot.position.x + r + 8.0, plot.position.x + plot.size.x - r - 8.0)
			p.y = clampf(p.y, plot.position.y + r + 6.0, plot.position.y + plot.size.y - r - 18.0)
			pos[k] = p
		if not moved:
			break

func _get_active_countries_list() -> Array:
	if store_ref == null: return []
	var manual: Array = store_ref.get("manual_selected_countries") if store_ref.get("manual_selected_countries") != null else []
	var cur_day: int = game_ref.day() if game_ref != null else 0
	var pool: Array = []

	if not manual.is_empty():
		for n in manual:
			var nn: String = str(n)
			if store_ref.has_method("is_hidden") and store_ref.call("is_hidden", nn, cur_day): continue
			var s: Dictionary = stances_data.get(nn, {})
			if filter_hostile_only and int(s.get("tier", 2)) < 4 and not bool(s.get("war", false)): continue
			if filter_border_only and not bool(s.get("border", false)): continue
			pool.append(nn)
		return pool.slice(0, 40)

	var scored: Array = []
	for c_name in stances_data.keys():
		var nn: String = str(c_name)
		if store_ref.has_method("is_hidden") and store_ref.call("is_hidden", nn, cur_day): continue
		var s: Dictionary = stances_data[c_name]
		if filter_hostile_only and int(s.get("tier", 2)) < 4 and not bool(s.get("war", false)): continue
		if filter_border_only and not bool(s.get("border", false)): continue
		var sig: float = float(s.get("significance", 0.0))
		if store_ref.has_method("is_pinned") and store_ref.call("is_pinned", nn): sig += 1000.0
		scored.append([sig, nn])
	scored.sort_custom(func(a, b): return float(a[0]) > float(b[0]))
	for i in range(mini(12, scored.size())):
		pool.append(scored[i][1])
	return pool

# ─── Отрисовка ───

func _draw() -> void:
	_node_rects.clear()
	var plot := _last_plot_rect
	if plot.size.x < 10.0 or plot.size.y < 10.0:
		plot = _plot_rect()
		_last_plot_rect = plot

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.045, 0.07, 1.0), true)

	var mid := plot.position + plot.size * 0.5

	# 1. Заливка квадрантов с градиентным ощущением
	# Top-Left: ОПОРЫ (зеленый)
	draw_rect(Rect2(plot.position, Vector2(mid.x - plot.position.x, mid.y - plot.position.y)), Color(0.04, 0.16, 0.10, 0.32))
	# Top-Right: УГРОЗЫ (красный)
	draw_rect(Rect2(Vector2(mid.x, plot.position.y), Vector2(plot.end.x - mid.x, mid.y - plot.position.y)), Color(0.22, 0.05, 0.08, 0.35))
	# Bottom-Left: КЛИЕНТЫ (синий)
	draw_rect(Rect2(Vector2(plot.position.x, mid.y), Vector2(mid.x - plot.position.x, plot.end.y - mid.y)), Color(0.05, 0.12, 0.22, 0.30))
	# Bottom-Right: ЦЕЛИ (янтарный)
	draw_rect(Rect2(Vector2(mid.x, mid.y), Vector2(plot.end.x - mid.x, plot.end.y - mid.y)), Color(0.20, 0.14, 0.04, 0.32))

	# 2. Сетка
	var gc := Color(0.5, 0.62, 0.82, 0.055)
	for i in range(1, 6):
		var t: float = float(i) / 6.0
		var gx: float = plot.position.x + plot.size.x * t
		var gy: float = plot.position.y + plot.size.y * t
		draw_line(Vector2(gx, plot.position.y), Vector2(gx, plot.end.y), gc, 1.0)
		draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), gc, 1.0)

	# 3. Оси и внешняя рамка
	var ac := Color(0.55, 0.70, 0.92, 0.85)
	draw_rect(plot, Color(0.28, 0.40, 0.58, 0.45), false, 1.0)
	draw_line(Vector2(plot.position.x, mid.y), Vector2(plot.end.x, mid.y), ac, 1.5)
	draw_line(Vector2(mid.x, plot.end.y), Vector2(mid.x, plot.position.y), ac, 1.5)
	_arrow(Vector2(plot.end.x, mid.y), Vector2(1, 0), ac)
	_arrow(Vector2(mid.x, plot.position.y), Vector2(0, -1), ac)

	var font: Font = ThemeDB.fallback_font

	# 4. Ненавязчивые маркеры квадрантов в углах (минималистичные)
	var w_th: float = font.get_string_size("УГРОЗЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var w_ri: float = font.get_string_size("ПРОТИВНИКИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, plot.position + Vector2(10, 14), "СОЮЗНИКИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.45, 0.92, 0.55, 0.28))
	draw_string(font, Vector2(plot.end.x - w_th - 10, plot.position.y + 14), "УГРОЗЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.42, 0.42, 0.28))
	draw_string(font, Vector2(plot.position.x + 10, plot.end.y - 6), "ПАРТНЁРЫ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.42, 0.75, 1.0, 0.28))
	draw_string(font, Vector2(plot.end.x - w_ri - 10, plot.end.y - 6), "ПРОТИВНИКИ", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.78, 0.35, 0.28))

	# 5. Подписи осей со стрелками и индикацией направления
	var lx: String = _axis_label(axis_x)
	var ly: String = _axis_label(axis_y)
	var lx_w: float = font.get_string_size(lx, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, Vector2(plot.position.x + plot.size.x * 0.5 - lx_w * 0.5, size.y - 6), lx, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.85, 0.96))
	var ly_w: float = font.get_string_size(ly, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(font, Vector2(plot.position.x + plot.size.x * 0.5 - ly_w * 0.5, plot.position.y - 8), ly, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.75, 0.85, 0.96))

	# 6. Рёбра связей
	if show_edges:
		var nm: Array = _current_positions.keys()
		for i in range(nm.size()):
			for j in range(i + 1, nm.size()):
				var a: String = nm[i]; var b: String = nm[j]
				var sa: Dictionary = stances_data.get(a, {})
				var sb: Dictionary = stances_data.get(b, {})
				if bool(sa.get("war", false)) or bool(sb.get("war", false)):
					draw_line(_current_positions[a], _current_positions[b], Color(1.0, 0.3, 0.3, 0.25), 1.2)
				elif int(sa.get("tier", 2)) == 0 and int(sb.get("tier", 2)) == 0:
					draw_line(_current_positions[a], _current_positions[b], Color(0.35, 0.92, 0.5, 0.30), 1.2)

	# 7. Узлы
	for c_name in _visible_list:
		if not _current_positions.has(c_name): continue
		_draw_node(c_name, _current_positions[c_name], font)

	# 8. Тултип
	if not hovered_country.is_empty() and _current_positions.has(hovered_country):
		_draw_tooltip(_current_positions[hovered_country], hovered_country, font)

func _arrow(tip: Vector2, dir: Vector2, col: Color) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var base := tip - dir * 8.0
	draw_line(tip, base + perp * 4.0, col, 1.6)
	draw_line(tip, base - perp * 4.0, col, 1.6)

func _draw_node(c_name: String, pos: Vector2, font: Font) -> void:
	var s: Dictionary = stances_data.get(c_name, {})
	var r: float = float(_node_radii.get(c_name, 20.0))
	var is_hov: bool = c_name == hovered_country
	var is_sel: bool = c_name == selected_country
	if is_hov or is_sel: r += 2.5

	var tier: int = clampi(int(s.get("tier", 2)), 0, 5)
	var is_war: bool = bool(s.get("war", false))
	var threat: float = float(s.get("threat_index", 0.0))

	var outline: Color = TIER_COLORS[tier]
	var fill: Color = TIER_FILLS[tier]
	if is_war:
		var pulse: float = 0.5 + 0.5 * sin(_pulse_time * 5.0)
		outline = Color(1.0, 0.25, 0.25).lerp(Color(1.0, 0.70, 0.70), pulse)

	var outline_w: float = 1.6 + (threat / 100.0) * 2.4
	if is_sel:
		outline_w += 1.4
		outline = outline.lightened(0.35)

	# 1. Пульсирующее кольцо активного плана
	var is_in_plan: bool = active_plan_data.get("goal", "").contains(c_name) or active_plan_data.get("title", "").contains(c_name)
	if is_in_plan:
		var rp: float = 0.5 + 0.5 * sin(_pulse_time * 4.0)
		draw_arc(pos, r + 6.0 + rp * 3.0, 0.0, TAU, 40, Color(1.0, 0.88, 0.35, 0.55 + 0.4 * rp), 1.8)

	# 2. Вспышка выбора
	if is_sel and _selection_flash > 0.0:
		draw_circle(pos, r + 10.0 * _selection_flash, Color(1.0, 1.0, 0.7, 0.35 * _selection_flash))

	# 3. Тень
	draw_circle(pos + Vector2(0, 2), r + 0.5, Color(0.0, 0.0, 0.0, 0.45))

	# 4. Флаг страны (заполняет 100% круг через текстурированный полигон)
	var flag_tex: Texture2D = _get_flag_texture(c_name)
	if flag_tex != null:
		var num_pts: int = 32
		var pts: PackedVector2Array = PackedVector2Array()
		var uvs: PackedVector2Array = PackedVector2Array()
		var cols: PackedColorArray = PackedColorArray([Color.WHITE])

		var tw: float = maxf(1.0, float(flag_tex.get_width()))
		var th: float = maxf(1.0, float(flag_tex.get_height()))
		var scale_u: float = 0.5
		var scale_v: float = 0.5
		if tw >= th:
			scale_u = 0.5 * (th / tw)
			scale_v = 0.5
		else:
			scale_u = 0.5
			scale_v = 0.5 * (tw / th)

		for i in range(num_pts):
			var angle: float = float(i) * TAU / float(num_pts)
			var dir := Vector2(cos(angle), sin(angle))
			pts.append(pos + dir * r)
			var u: float = clampf(0.5 + dir.x * scale_u, 0.0, 1.0)
			var v: float = clampf(0.5 + dir.y * scale_v, 0.0, 1.0)
			uvs.append(Vector2(u, v))

		draw_polygon(pts, cols, uvs, flag_tex)
		# Тонкая внутренняя тень по контуру для глубины
		draw_arc(pos, r - 0.5, 0.0, TAU, 36, Color(0.0, 0.0, 0.0, 0.45), 1.5)
	else:
		draw_circle(pos, r, fill)
		var code: String = _country_code(c_name)
		var fs: int = clampi(int(r * 0.9), 11, 18)
		var tw: float = font.get_string_size(code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, pos + Vector2(-tw * 0.5, fs * 0.35), code, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.98, 0.98, 1.0))

	# 5. Обводка кружка по цвету тира
	draw_arc(pos, r, 0.0, TAU, 40, outline, outline_w)
	if is_hov or is_sel:
		draw_arc(pos, r + 2.5, 0.0, TAU, 40, outline.lightened(0.45), 1.2)

	# 6. Лаконичный индикатор войны/союза (если есть)
	if is_war:
		var bp := pos + Vector2(r * 0.7, r * 0.7)
		draw_circle(bp, 6.0, Color(0.75, 0.1, 0.1, 0.95))
		draw_string(font, bp + Vector2(-3.5, 3.5), "⚔", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	elif tier == 0:
		var bp := pos + Vector2(r * 0.7, r * 0.7)
		draw_circle(bp, 6.0, Color(0.1, 0.55, 0.2, 0.95))
		draw_string(font, bp + Vector2(-3.5, 3.5), "🛡", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# 7. Подпись названия страны (чистый текст с мягкой тенью, без громоздких рамок)
	var lbl: String = _short_label(c_name, 14)
	var lw: float = font.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var lpos := Vector2(pos.x - lw * 0.5, pos.y + r + 13)
	
	draw_string(font, lpos + Vector2(1, 1), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.0, 0.0, 0.0, 0.9))
	draw_string(font, lpos, lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.92, 0.95, 0.98))

	_node_rects[c_name] = Rect2(pos.x - r - 4, pos.y - r - 4, (r + 4) * 2.0, (r + 4) * 2.0 + 18.0)

func _country_code(name: String) -> String:
	if CODE_TABLE.has(name):
		return CODE_TABLE[name]
	if name.length() >= 2:
		return name.substr(0, 2).to_upper()
	return name.to_upper()

func _short_label(name: String, max_len: int) -> String:
	if name.length() <= max_len: return name
	return name.substr(0, max_len - 1) + "…"

func _badges(s: Dictionary, is_war: bool, tier: int) -> Array:
	var list: Array = []
	if is_war: list.append("⚔")
	elif tier == 0: list.append("🛡")
	var flags: Array = s.get("flags", [])
	if flags.has("пограничник"): list.append("▣")
	if flags.has("предатель"): list.append("⚠")
	if flags.has("должник"): list.append("✓")
	if flags.has("торговый договор"): list.append("↹")
	return list

func _draw_tooltip(pos: Vector2, c_name: String, font: Font) -> void:
	var s: Dictionary = stances_data.get(c_name, {})
	var rel: float = float(s.get("relation", 0.5))
	var pw: float = float(s.get("power", 50.0))
	var th: float = float(s.get("threat_index", 0.0))
	var tier: int = int(s.get("tier", 2))
	var action: String = ""
	match tier:
		0: action = "Союзник: укреплять союз"
		1: action = "Партнёр: развивать торговлю"
		2: action = "Нейтрал: наблюдать"
		3: action = "Настороженный: контрмеры"
		4: action = "Противник: сдерживать"
		5: action = "Война: вести боевые действия"

	var l1: String = "%s — тир %d" % [c_name, tier]
	var l2: String = "Отношение %.2f · Сила %.0f · Угроза %.0f" % [rel, pw, th]

	var box_w: float = 260.0
	var box_h: float = 58.0
	var bx: float = clampf(pos.x - box_w * 0.5, 8.0, size.x - box_w - 8.0)
	var by: float = pos.y - box_h - 14.0
	if by < 8.0: by = pos.y + 22.0
	by = clampf(by, 8.0, size.y - box_h - 8.0)

	draw_rect(Rect2(bx, by, box_w, box_h), Color(0.05, 0.08, 0.13, 0.97), true)
	draw_rect(Rect2(bx, by, box_w, box_h), Color(0.32, 0.46, 0.68, 0.9), false, 1.0)
	draw_string(font, Vector2(bx + 10, by + 18), l1, HORIZONTAL_ALIGNMENT_LEFT, int(box_w - 20), 12, Color(1.0, 0.9, 0.4))
	draw_string(font, Vector2(bx + 10, by + 34), l2, HORIZONTAL_ALIGNMENT_LEFT, int(box_w - 20), 10, Color(0.88, 0.92, 0.98))
	draw_string(font, Vector2(bx + 10, by + 50), action, HORIZONTAL_ALIGNMENT_LEFT, int(box_w - 20), 10, Color(0.5, 0.85, 1.0))


func _axis_label(key: String) -> String:
	match key:
		"relation": return "← Союзники ··· [ Отношение ] ··· Враги →"
		"power": return "↑ Высокая ··· [ Сила ] ··· Низкая ↓"
		"threat": return "← Низкая ··· [ Угроза ] ··· Высокая →"
		"opportunity": return "← Низкая ··· [ Возможность ] ··· Высокая →"
		"economy": return "← Слабая ··· [ Экономика ] ··· Сильная →"
		"army": return "← Малая ··· [ Армия ] ··· Крупная →"
		"distance": return "← Близко ··· [ Расстояние ] ··· Далеко →"
		"border": return "← Без границы ··· [ Граница ] ··· Сосед →"
		"activity": return "← Пассивный ··· [ Активность ] ··· Активный →"
		"stability": return "← Кризис ··· [ Стабильность ] ··· Порядок →"
	return key