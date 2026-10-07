# lib/store.gd
# Хранилище состояния мода: планы, история, советы, метрики, тиры, доктрина, ИИ-описания держав и система осей.
# Событийная модель через сигналы + DTO-фабрики.

extends RefCounted

signal stances_changed(stances: Dictionary)
signal plan_updated(plan: Dictionary)
signal step_completed(plan_id: String, step: Dictionary)
signal advice_added(advice: Dictionary)
signal history_added(entry: Dictionary)
signal doctrine_changed(doctrine_id: String)
signal country_descriptions_changed(descriptions: Dictionary)
signal map_selection_changed(selected_country: String)
signal pinned_changed(pinned: Array)
signal hidden_changed(hidden: Dictionary)

var plans: Array = []
var active_plan_id: String = ""
var stances: Dictionary = {}
var advice: Array = []
var history: Array = []
var metrics: Dictionary = {
	"money": [],
	"trust": [],
	"provinces": [],
	"wars": [],
	"colonies": []
}
var triggers: Array = []
var flags: Dictionary = {}
var profile: String = ""
var doctrine: String = "fortress"

# Новые поля для системы осей и ИИ-описаний
var country_descriptions: Dictionary = {} # country_name -> { "text": String, "day": int, "hash": String, "image": String }
var pinned_countries: Array = []           # Array[String]
var hidden_countries: Dictionary = {}      # country_name -> until_day (int)
var manual_selected_countries: Array = []  # Array[String] (ручной фильтр до 40 стран)
var country_history: Dictionary = {}       # country_name -> Array[Dictionary: {day, relation, power, threat}] (до 12 точек)
var ai_description_queue: Array = []       # Array[String] (страны в очереди на генерацию)
var selected_country_on_map: String = ""
var axis_x: String = "relation"
var axis_y: String = "power"
var pivot_median: bool = true
var show_edges: bool = false

const MAX_ADVICE: int = 30
const MAX_HISTORY: int = 50
const MAX_METRIC_POINTS: int = 24
const MAX_COUNTRY_HISTORY_POINTS: int = 12

func reset() -> void:
	plans.clear()
	active_plan_id = ""
	stances.clear()
	advice.clear()
	history.clear()
	metrics = {
		"money": [],
		"trust": [],
		"provinces": [],
		"wars": [],
		"colonies": []
	}
	triggers.clear()
	flags.clear()
	profile = ""
	doctrine = "fortress"
	country_descriptions.clear()
	pinned_countries.clear()
	hidden_countries.clear()
	manual_selected_countries.clear()
	country_history.clear()
	ai_description_queue.clear()
	selected_country_on_map = ""
	axis_x = "relation"
	axis_y = "power"
	pivot_median = true
	show_edges = false

# -------------------------------------------------------------
# DTO-фабрики (безопасное создание структур с дефолтами)
# -------------------------------------------------------------
static func create_step(n: int, what: String, why: String = "", needs: Dictionary = {}, days: int = 30, check: Dictionary = {}, since_day: int = 0) -> Dictionary:
	var validated_check: Dictionary = check
	if validated_check.is_empty():
		validated_check = {"kind": "manual"}
	return {
		"n": n,
		"what": what,
		"why": why,
		"needs": needs,
		"days": days,
		"status": "pending",
		"check": validated_check,
		"since_day": since_day,
		"done_day": 0
	}

static func create_plan(title: String, goal: String, horizon_days: int = 365, created_day: int = 0, kind: String = "strategic", steps: Array = [], risks: Array = [], reserve: String = "") -> Dictionary:
	var plan_id: String = "plan_" + str(created_day) + "_" + str(Time.get_ticks_msec() % 10000)
	return {
		"id": plan_id,
		"title": title,
		"goal": goal,
		"horizon_days": horizon_days,
		"created_day": created_day,
		"parent": "",
		"kind": kind,
		"steps": steps,
		"risks": risks,
		"indicators": [],
		"reserve": reserve,
		"status": "active"
	}

static func create_advice_item(day: int, text: String, priority: String = "medium", plan_id: String = "", order_action: Dictionary = {}) -> Dictionary:
	return {
		"id": "adv_" + str(day) + "_" + str(Time.get_ticks_msec() % 10000),
		"day": day,
		"text": text,
		"priority": priority, # high | medium | low
		"status": "open",     # open | done | postponed | ignored
		"plan_id": plan_id,
		"order_action": order_action
	}

# -------------------------------------------------------------
# Методы модификации состояния с эмиссией сигналов
# -------------------------------------------------------------
func set_stances(new_stances: Dictionary) -> void:
	stances = new_stances
	emit_signal("stances_changed", stances)

func set_doctrine(new_doctrine: String) -> void:
	doctrine = new_doctrine
	emit_signal("doctrine_changed", doctrine)

func add_advice(day: int, text: String, priority: String, plan_id: String = "", order_action: Dictionary = {}) -> void:
	var item: Dictionary = create_advice_item(day, text, priority, plan_id, order_action)
	advice.push_front(item)
	while advice.size() > MAX_ADVICE:
		advice.pop_back()
	emit_signal("advice_added", item)

func add_history_entry(day: int, kind: String, text: String) -> void:
	var item: Dictionary = {
		"day": day,
		"kind": kind, # war | peace | law | province | advice | crisis
		"text": text
	}
	history.push_front(item)
	while history.size() > MAX_HISTORY:
		history.pop_back()
	emit_signal("history_added", item)

func notify_step_completed(plan_id: String, step: Dictionary) -> void:
	emit_signal("step_completed", plan_id, step)

# Фиксация точки метрик игрока (до 24 точек)
func record_metrics_point(money_val: float, trust_val: float, prov_val: int, wars_val: int, col_val: int) -> void:
	_append_metric("money", money_val)
	_append_metric("trust", trust_val)
	_append_metric("provinces", float(prov_val))
	_append_metric("wars", float(wars_val))
	_append_metric("colonies", float(col_val))

func _append_metric(key: String, val: float) -> void:
	var arr: Array = metrics.get(key, [])
	arr.append(val)
	while arr.size() > MAX_METRIC_POINTS:
		arr.pop_front()
	metrics[key] = arr

# -------------------------------------------------------------
# Управление описаниями стран и историей держав
# -------------------------------------------------------------
func set_country_description(country_name: String, text_val: String, day_val: int, hash_val: String, image_val: String = "") -> void:
	country_descriptions[country_name] = {
		"text": text_val,
		"day": day_val,
		"hash": hash_val,
		"image": image_val
	}
	emit_signal("country_descriptions_changed", country_descriptions)

func get_country_description(country_name: String) -> Dictionary:
	return country_descriptions.get(country_name, {})

func is_pinned(country_name: String) -> bool:
	return pinned_countries.has(country_name)

func toggle_pin(country_name: String) -> void:
	if pinned_countries.has(country_name):
		pinned_countries.erase(country_name)
	else:
		pinned_countries.append(country_name)
	emit_signal("pinned_changed", pinned_countries)

func is_hidden(country_name: String, current_day: int) -> bool:
	if not hidden_countries.has(country_name):
		return false
	var until_day: int = int(hidden_countries[country_name])
	if current_day >= until_day:
		hidden_countries.erase(country_name)
		return false
	return true

func hide_country(country_name: String, current_day: int, turns_count: int = 10) -> void:
	# Примерно 30 дней на ход
	hidden_countries[country_name] = current_day + turns_count * 30
	emit_signal("hidden_changed", hidden_countries)

func unhide_country(country_name: String) -> void:
	if hidden_countries.has(country_name):
		hidden_countries.erase(country_name)
		emit_signal("hidden_changed", hidden_countries)

func record_country_history_point(country_name: String, day_val: int, rel_val: float, pow_val: float, threat_val: float) -> void:
	var arr: Array = country_history.get(country_name, [])
	arr.append({
		"day": day_val,
		"relation": rel_val,
		"power": pow_val,
		"threat": threat_val
	})
	while arr.size() > MAX_COUNTRY_HISTORY_POINTS:
		arr.pop_front()
	country_history[country_name] = arr

func get_country_history(country_name: String) -> Array:
	return country_history.get(country_name, [])

func queue_ai_description(country_name: String) -> void:
	if not ai_description_queue.has(country_name):
		ai_description_queue.append(country_name)

func pop_ai_description_queue() -> String:
	if ai_description_queue.is_empty():
		return ""
	return str(ai_description_queue.pop_front())

func set_map_selection(country_name: String) -> void:
	selected_country_on_map = country_name
	emit_signal("map_selection_changed", selected_country_on_map)

# Получение активного плана
func get_active_plan() -> Dictionary:
	if active_plan_id.is_empty():
		return {}
	for p_any in plans:
		if p_any is Dictionary:
			var p: Dictionary = p_any
			if p.get("id", "") == active_plan_id:
				return p
	return {}

# Добавление или обновление плана
func save_plan(plan_data: Dictionary) -> void:
	var p_id: String = plan_data.get("id", "")
	if p_id.is_empty():
		p_id = "plan_" + str(Time.get_ticks_msec())
		plan_data["id"] = p_id

	var found: bool = false
	for i in range(plans.size()):
		var p: Dictionary = plans[i]
		if p.get("id", "") == p_id:
			plans[i] = plan_data
			found = true
			break
	if not found:
		plans.append(plan_data)

	if active_plan_id.is_empty() or plan_data.get("status", "") == "active":
		active_plan_id = p_id

	emit_signal("plan_updated", plan_data)

# Сериализация для сейва игры
func serialize() -> Dictionary:
	return {
		"version": 3,
		"plans": plans,
		"active_plan_id": active_plan_id,
		"stances": stances,
		"advice": advice,
		"history": history,
		"metrics": metrics,
		"triggers": triggers,
		"flags": flags,
		"profile": profile,
		"doctrine": doctrine,
		"country_descriptions": country_descriptions,
		"pinned_countries": pinned_countries,
		"hidden_countries": hidden_countries,
		"manual_selected_countries": manual_selected_countries,
		"country_history": country_history,
		"axis_x": axis_x,
		"axis_y": axis_y,
		"pivot_median": pivot_median,
		"show_edges": show_edges
	}

# Восстановление из сохранённого словаря
func deserialize(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		return
	plans = data.get("plans", [])
	active_plan_id = str(data.get("active_plan_id", ""))
	stances = data.get("stances", {})
	advice = data.get("advice", [])
	history = data.get("history", [])
	var loaded_metrics: Dictionary = data.get("metrics", {})
	if not loaded_metrics.is_empty():
		metrics = loaded_metrics
	triggers = data.get("triggers", [])
	flags = data.get("flags", {})
	profile = str(data.get("profile", ""))
	doctrine = str(data.get("doctrine", "fortress"))

	country_descriptions = data.get("country_descriptions", {})
	pinned_countries = data.get("pinned_countries", [])
	hidden_countries = data.get("hidden_countries", {})
	manual_selected_countries = data.get("manual_selected_countries", [])
	country_history = data.get("country_history", {})
	axis_x = str(data.get("axis_x", "relation"))
	axis_y = str(data.get("axis_y", "power"))
	pivot_median = bool(data.get("pivot_median", true))
	show_edges = bool(data.get("show_edges", false))

	emit_signal("stances_changed", stances)
	emit_signal("country_descriptions_changed", country_descriptions)
	var active_p: Dictionary = get_active_plan()
	if not active_p.is_empty():
		emit_signal("plan_updated", active_p)