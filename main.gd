extends PaxMod
## ВИ-Советник 2.0 (strategist) — интеграция со стабильным API PaxGame, HUD виджет, Event-Driven шина, симулятор и приказы.

const StancesScript = preload("res://mods/strategist/lib/stances.gd")
const StoreScript = preload("res://mods/strategist/lib/store.gd")
const TrackerScript = preload("res://mods/strategist/lib/tracker.gd")
const BriefScript = preload("res://mods/strategist/lib/brief.gd")
const PlannerScript = preload("res://mods/strategist/lib/planner.gd")
const DoctrinesScript = preload("res://mods/strategist/lib/doctrines.gd")

const WindowScript = preload("res://mods/strategist/ui/window.gd")
const HudWidgetScript = preload("res://mods/strategist/ui/hud_widget.gd")
const ProfilePickerScript = preload("res://mods/strategist/ui/profile_picker.gd")

var _store: RefCounted = null
var _window_ui: Control = null
var _hud_widget: Control = null
var _picker_ui: Control = null
var _game: PaxGame = null
var _window_panel: PanelContainer = null

# 1. Загрузка мода при запуске игры
func _mod_loaded() -> void:
	_store = StoreScript.new()
	Pax.register_command("strategist", _console_cmd, "strategist [eval|plan|brief|order] — команды отладки советника")
	log_info("ВИ-Советник 2.0 (strategist v1.1.0) успешно инициализирован.")

# 2. Инициализация мира
func _world_ready(game: PaxGame) -> void:
	_game = game
	if _store == null:
		_store = StoreScript.new()

	# Первоначальный расчёт позиций держав
	var current_stances: Dictionary = _store.get("stances") if _store.get("stances") != null else {}
	var history_list: Array = _store.get("history") if _store.get("history") != null else []
	var new_stances: Dictionary = StancesScript.recalculate_all(game, current_stances, history_list)
	_store.call("set_stances", new_stances)

	# Регистрация хуков
	hook("ai_request", _on_ai_request)
	hook("war_declared", _on_war_declared)
	hook("peace_made", _on_peace_made)
	hook("province_captured", _on_province_captured)
	hook("law_passed", _on_law_passed)
	hook("event_card", _on_event_card)

	# Построение интерфейса окна
	_window_ui = WindowScript.new(self, game, _store)
	_window_ui.connect("ask_advisor_requested", _on_ask_advisor)
	_window_ui.connect("new_plan_requested", _on_new_plan_requested)
	_window_ui.connect("rebuild_plan_requested", _on_rebuild_plan_requested)
	_window_ui.connect("accept_advice_requested", _on_accept_advice)
	_window_ui.connect("execute_order_requested", _on_execute_order)
	_window_ui.connect("change_profile_requested", _show_profile_picker)

	_window_panel = game.add_window(tr_key("strat_button"), _window_ui, Vector2(900, 600))

	# Построение HUD-виджета цели
	if game.hud_layer() != null:
		_hud_widget = HudWidgetScript.new(self, game, _store)
		_hud_widget.connect("open_advisor_requested", _toggle_advisor_window)
		game.hud_layer().call_deferred("add_child", _hud_widget)

	# Проверка профиля при первом старте
	var saved_profile: String = get_setting("profile", "")
	if saved_profile.is_empty():
		call_deferred("_show_profile_picker")
	else:
		_store.set("profile", saved_profile)

# 3. Перемотка времени
func _days_passed(game: PaxGame, from_day: int, days: int) -> void:
	_game = game
	if _store == null:
		return

	var home_b: String = game.home_body()
	var my_c: String = game.country()
	var prov_count: int = game.provinces_of(home_b, my_c).size()
	var wars_count: int = 1 if game.at_war() else 0
	var col_count: int = game.colonies().size()

	# Периодическая инвалидация пространственного кэша границ (раз в игровой год)
	if game.day() % 365 < days:
		StancesScript.invalidate_cache()

	# 1. Запись точки метрик
	_store.call("record_metrics_point", game.money(), 0.8, prov_count, wars_count, col_count)

	# 2. Пересчёт тиров и угроз
	var cur_stances: Dictionary = _store.get("stances") if _store.get("stances") != null else {}
	var history_arr: Array = _store.get("history") if _store.get("history") != null else []
	var updated_stances: Dictionary = StancesScript.recalculate_all(game, cur_stances, history_arr)
	_store.call("set_stances", updated_stances)

	# 3. Автотрекинг шагов
	var plans_arr: Array = _store.get("plans") if _store.get("plans") != null else []
	var flags_dict: Dictionary = _store.get("flags") if _store.get("flags") != null else {}
	var completed_steps: Array = TrackerScript.update_all_plans(game, plans_arr, flags_dict)

	for item in completed_steps:
		var st: Dictionary = item.get("step", {})
		var plan_id_val: String = str(item.get("plan_id", ""))
		var step_text: String = str(st.get("what", ""))
		game.toast("[OK] Шаг выполнен: " + step_text)
		_store.call("add_history_entry", game.day(), "advice", "Выполнен шаг: " + step_text)
		_store.call("notify_step_completed", plan_id_val, st)

	# 4. Автосовет при перемотке, если есть угрозы
	_check_auto_advice(game)

	# 5. Обработка ИИ-описаний стран (Волны 1-4 и пассивные)
	_process_ai_descriptions(game)

	# 6. Обновление HUD виджета
	if _hud_widget != null and _hud_widget.has_method("refresh"):
		_hud_widget.call("refresh")

# 4. Сериализация и восстановление состояния
func _save_state(_game_inst: PaxGame) -> Dictionary:
	if _store == null:
		return {}
	return _store.call("serialize")

func _game_loaded(game: PaxGame, state: Dictionary) -> void:
	_game = game
	if _store == null:
		_store = StoreScript.new()
	_store.call("deserialize", state)
	if _window_ui != null and _window_ui.has_method("refresh_all"):
		_window_ui.call("refresh_all")
	if _hud_widget != null and _hud_widget.has_method("refresh"):
		_hud_widget.call("refresh")

# 5. Обработчики хуков игры
func _on_ai_request(d: Dictionary) -> void:
	var channel: String = str(d.get("channel", ""))
	if channel == "assistant" or channel == "interpreter":
		var active_plan: Dictionary = _store.call("get_active_plan") if _store != null else {}
		var plan_summary: String = ""
		if not active_plan.is_empty():
			plan_summary = "Текущий стратегический план: «%s», цель: «%s». " % [
				str(active_plan.get("title", "")),
				str(active_plan.get("goal", ""))
			]

		var doc_id: String = str(_store.get("doctrine")) if _store != null and _store.get("doctrine") != null else "fortress"
		var doc_text: String = DoctrinesScript.get_prompt_modifier(doc_id)

		var current_system: String = str(d.get("system", ""))
		var append_text: String = "\n[Стратегический контекст: %s %s Не противоречь генеральной линии.]" % [doc_text, plan_summary]
		d["system"] = current_system + append_text

func _on_war_declared(d: Dictionary) -> void:
	var target_country: String = str(d.get("target", ""))
	if _store != null:
		_store.call("add_history_entry", _game.day() if _game != null else 0, "war", "Объявлена война державе: " + target_country)
		_store.call("add_advice", _game.day() if _game != null else 0, "Начата война с %s! Сконцентрируйте силы на ключевых провинциях." % target_country, "high", "", {"type": "mobilize", "target": target_country})
		var queue: Array = _store.get("ai_update_queue") if _store.get("ai_update_queue") != null else []
		if not queue.has(target_country): queue.append(target_country)
		_store.set("ai_update_queue", queue)
	_trigger_crisis_briefing("Военный кризис: Война с " + target_country, "Вражеские войска приведены в полную боеготовность. Генеральный штаб запрашивает указания.")

func _on_peace_made(d: Dictionary) -> void:
	var faction: Dictionary = d.get("faction", {})
	var c_name: String = str(faction.get("name", ""))
	if _store != null:
		_store.call("add_history_entry", _game.day() if _game != null else 0, "peace", "Заключён мир с державой: " + c_name)
		var queue: Array = _store.get("ai_update_queue") if _store.get("ai_update_queue") != null else []
		if not queue.has(c_name): queue.append(c_name)
		_store.set("ai_update_queue", queue)

func _on_province_captured(d: Dictionary) -> void:
	var prov_id: int = int(d.get("province", 0))
	var from_country: String = str(d.get("from", ""))
	StancesScript.invalidate_cache() # Инвалидация Spatial Cache
	if _store != null:
		_store.call("add_history_entry", _game.day() if _game != null else 0, "province", "Захвачена провинция #%d (бывший владелец: %s)" % [prov_id, from_country])
		var queue: Array = _store.get("ai_update_queue") if _store.get("ai_update_queue") != null else []
		if not queue.has(from_country): queue.append(from_country)
		_store.set("ai_update_queue", queue)

func _on_law_passed(d: Dictionary) -> void:
	var law_data: Dictionary = d.get("law", {})
	var law_name: String = str(law_data.get("name", law_data.get("title", "Закон")))
	if _store != null:
		_store.call("add_history_entry", _game.day() if _game != null else 0, "law", "Принят новый закон: " + law_name)

func _on_event_card(d: Dictionary) -> void:
	var card: Dictionary = d.get("card", {})
	var title: String = str(card.get("title", card.get("заголовок", "")))
	if not title.is_empty() and _store != null:
		_store.call("add_history_entry", _game.day() if _game != null else 0, "crisis", "Событие: " + title)

# 6. Запросы к планировщику, советы и прямое выполнение приказов
func _on_new_plan_requested(goal_text: String) -> void:
	if _game == null or _store == null:
		return

	_game.toast(tr_key("strat_ai_busy"))
	var brief_text: String = BriefScript.build_brief(_game, _store)
	var profile: String = get_setting("profile", "akademik")

	PlannerScript.request_plan(
		self,
		_game,
		brief_text,
		goal_text,
		profile,
		func(plan: Dictionary) -> void:
			_store.call("save_plan", plan)
			_store.call("add_history_entry", _game.day(), "advice", "Сформирован план: «" + str(plan.get("title", "")) + "»")
			_game.toast(tr_key("strat_plan_created"))
			if _hud_widget != null and _hud_widget.has_method("refresh"):
				_hud_widget.call("refresh"),
		func(err_key: String) -> void:
			_game.toast(tr_key(err_key))
	)

func _on_rebuild_plan_requested(plan_id: String) -> void:
	if _game == null or _store == null:
		return
	var active_p: Dictionary = _store.call("get_active_plan")
	var goal_text: String = str(active_p.get("goal", ""))
	_on_new_plan_requested(goal_text)

func _on_ask_advisor() -> void:
	if _game == null or _store == null:
		return

	var brief_text: String = BriefScript.build_brief(_game, _store)
	var profile: String = get_setting("profile", "akademik")
	var prompt_text: String = """
%s
Обстановка:
%s
Дай 1 короткую оперативную рекомендацию (1-2 предложения) правителю.
Если целесообразно конкретное действие, прикрепи order_action.
Ответь ТОЛЬКО JSON:
{
  "advice": "текст рекомендации",
  "priority": "high|medium|low",
  "order_action": {"type": "declare_war|improve_relations|mobilize", "target": "название_державы"}
}
""" % [profile, brief_text]

	_game.toast(tr_key("strat_ai_busy"))
	ask_ai("strategist", prompt_text, {}, func(ans: Dictionary) -> void:
		if ans.is_empty():
			_game.toast(tr_key("strat_ai_unavailable"))
			return
		var adv_text: String = str(ans.get("advice", ""))
		var prio: String = str(ans.get("priority", "medium"))
		var order_act: Dictionary = ans.get("order_action", {})
		if not adv_text.is_empty():
			_store.call("add_advice", _game.day(), adv_text, prio, "", order_act)
			_store.call("add_history_entry", _game.day(), "advice", adv_text)
			_game.toast("Советник: " + adv_text)
	)

func _on_accept_advice(item: Dictionary) -> void:
	if _store == null or _game == null:
		return

	var text_val: String = str(item.get("text", ""))
	var active_plan: Dictionary = _store.call("get_active_plan")

	if not active_plan.is_empty():
		var steps: Array = active_plan.get("steps", [])
		var new_step: Dictionary = StoreScript.create_step(
			steps.size() + 1,
			text_val,
			"Рекомендация советника",
			{},
			30,
			{"kind": "manual"},
			_game.day()
		)
		steps.append(new_step)
		active_plan["steps"] = steps
		_store.call("save_plan", active_plan)
	else:
		var mini_plan: Dictionary = StoreScript.create_plan(
			"Рекомендация: " + text_val.substr(0, 24) + "...",
			text_val,
			60,
			_game.day(),
			"operation",
			[StoreScript.create_step(1, text_val, "Рекомендация советника", {}, 30, {"kind": "manual"}, _game.day())],
			[],
			""
		)
		_store.call("save_plan", mini_plan)

	_game.toast(tr_key("strat_advice_accepted"))

# 7. Выполнение приказов советника в один клик (Feature 2)
func _on_execute_order(action_dict: Dictionary) -> void:
	if _game == null or action_dict.is_empty():
		return

	var act_type: String = str(action_dict.get("type", ""))
	var target_c: String = str(action_dict.get("target", ""))

	match act_type:
		"declare_war":
			if not target_c.is_empty():
				_game.declare_war(target_c)
				_game.toast("Приказ выполнен: объявлена война %s" % target_c)
				_store.call("add_history_entry", _game.day(), "war", "По совету ВИ объявлена война: " + target_c)
		"improve_relations":
			if not target_c.is_empty():
				_game.change_relation(target_c, 0.15)
				_game.toast("Приказ выполнен: направлено посольство в %s" % target_c)
				_store.call("add_history_entry", _game.day(), "peace", "По совету ВИ улучшены дипломатические связи с: " + target_c)
		"mobilize":
			_game.toast("Приказ выполнен: войска приведены в высшую боеготовность")
			_store.call("add_history_entry", _game.day(), "advice", "Объявлена мобилизация вооруженных сил")
		_:
			_game.toast(tr_key("strat_order_executed"))

# 8. Интерактивные кризисные брифинги (Feature 4)
func _trigger_crisis_briefing(title: String, text: String) -> void:
	if _game == null:
		return

	var options: PackedStringArray = [
		"1. Перевести экономику на военные рельсы (+казну в резерв)",
		"2. Направить экстренных послов для поиска коалиции",
		"3. Сформировать ударный кулак и контратаковать"
	]

	_game.show_choice(
		"[КРИЗИС] " + title,
		text,
		options,
		func(choice_idx: int) -> void:
			if choice_idx == 0:
				_store.call("set_doctrine", "fortress")
				_game.toast("Доктрина изменена на «Крепость Держава»")
				_store.call("add_history_entry", _game.day(), "crisis", "Выбран оборонительный ответ на кризис.")
			elif choice_idx == 1:
				_game.toast("Послы направлены соседним державам")
				_store.call("add_history_entry", _game.day(), "crisis", "Выбран дипломатический ответ на кризис.")
			elif choice_idx == 2:
				_store.call("set_doctrine", "hegemony")
				_game.toast("Доктрина изменена на «Континентальная гегемония»")
				_store.call("add_history_entry", _game.day(), "crisis", "Выбран силовой ответ на кризис.")
	)

func _check_auto_advice(game: PaxGame) -> void:
	var stances: Dictionary = _store.get("stances") if _store != null else {}
	var has_critical_threat: bool = false
	var threat_country: String = ""

	for c in stances.keys():
		var s: Dictionary = stances[c]
		if float(s.get("threat_index", 0.0)) > 65.0:
			has_critical_threat = true
			threat_country = str(c)
			break

	if has_critical_threat:
		_store.call("add_advice", game.day(), "Критическая угроза со стороны %s! Рекомендуется укрепить приграничные районы." % threat_country, "high", "", {"type": "mobilize", "target": threat_country})

func _toggle_advisor_window() -> void:
	if _window_panel != null:
		_window_panel.visible = not _window_panel.visible

func _show_profile_picker() -> void:
	if _picker_ui != null:
		_picker_ui.queue_free()

	_picker_ui = ProfilePickerScript.new(self)
	_picker_ui.connect("profile_selected", func(p_id: String) -> void:
		if _store != null:
			_store.set("profile", p_id)
		_picker_ui.queue_free()
		_picker_ui = null
		if _hud_widget != null and _hud_widget.has_method("refresh"):
			_hud_widget.call("refresh")
		if _window_ui != null and _window_ui.has_method("refresh_all"):
			_window_ui.call("refresh_all")
	)

	if _game != null and _game.hud_layer() != null:
		_game.hud_layer().add_child(_picker_ui)

# Консольная команда отладки
func _console_cmd(args: PackedStringArray) -> String:
	if _game == null or _store == null:
		return "Мир не загружен."
	var sub: String = args[0] if args.size() > 0 else "eval"
	match sub:
		"eval":
			var stances: Dictionary = _store.get("stances")
			return "Держав в базе: %d, Доктрина: %s" % [stances.size(), str(_store.get("doctrine"))]
		"brief":
			return BriefScript.build_brief(_game, _store)
		"plan":
			_on_new_plan_requested("Тестовый стратегический план")
			return "Запрос на генерацию плана отправлен."
		"order":
			_on_execute_order({"type": "mobilize"})
			return "Тестовый приказ выполнен."
		_:
			return "Использование: strategist [eval|brief|plan|order]"

func _process_ai_descriptions(game: PaxGame) -> void:
	if _store == null:
		return
	var cur_day: int = game.day()
	var queue: Array = _store.get("ai_update_queue") if _store.get("ai_update_queue") != null else []
	var descriptions: Dictionary = _store.get("country_descriptions") if _store.get("country_descriptions") != null else {}
	var stances: Dictionary = _store.get("stances") if _store.get("stances") != null else {}
	
	var active_countries: Array = []
	for c_name in stances.keys():
		active_countries.append({"name": str(c_name), "sig": float(stances[c_name].get("significance", 0.0))})
	
	active_countries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["sig"] > b["sig"]
	)
	
	var top12: Array = []
	var limit: int = min(12, active_countries.size())
	for i in range(limit):
		top12.append(active_countries[i]["name"])
	
	var to_update: Array = []
	var max_updates: int = 3
	
	while queue.size() > 0 and to_update.size() < max_updates:
		var c: String = queue.pop_front()
		if not to_update.has(c) and stances.has(c):
			to_update.append(c)
	
	if to_update.size() < max_updates:
		if cur_day == 2:
			to_update.append_array(top12.slice(0, min(3, top12.size())))
		elif cur_day == 3:
			to_update.append_array(top12.slice(3, min(6, top12.size())))
		elif cur_day == 4:
			to_update.append_array(top12.slice(6, min(9, top12.size())))
		elif cur_day == 5:
			to_update.append_array(top12.slice(9, top12.size()))
	
	if cur_day >= 5 and cur_day % 5 == 0 and to_update.size() < max_updates:
		for c_name in top12:
			if to_update.size() >= max_updates:
				break
			if to_update.has(c_name):
				continue
			
			var s: Dictionary = stances.get(c_name, {})
			var h: String = str(s.get("hash", ""))
			var desc: Dictionary = descriptions.get(c_name, {})
			var last_h: String = str(desc.get("hash", ""))
			var last_d: int = int(desc.get("day", 0))
			
			if h != last_h and (cur_day - last_d) >= 5:
				to_update.append(c_name)
	
	for c_name in to_update:
		if queue.has(c_name):
			queue.erase(c_name)
		_request_country_description(c_name, stances.get(c_name, {}))
	
	_store.set("ai_update_queue", queue)

func _request_country_description(c_name: String, s: Dictionary) -> void:
	if _game == null or _store == null:
		return
	var active_p: Dictionary = _store.call("get_active_plan")
	var rel: float = float(s.get("relation", 0.5))
	var pow_val: float = float(s.get("axis_power", 0.0))
	var is_b: bool = bool(s.get("border", false))
	var flags_arr: Array = s.get("flags", [])
	
	var flags_str: String = ", ".join(PackedStringArray(flags_arr))
	var plan_title: String = active_p.get("title", "Нет")
	var b_str: String = "да" if is_b else "нет"
	
	var prompt: String = "Опиши державу в 2–3 предложениях, максимум 350 символов. По-русски.\nДержава: %s\nОтношение: %.2f\nСила: %.0f/100\nГраницы: %s\nФлаги: %s\nНаш активный план: «%s»" % [c_name, rel, pow_val, b_str, flags_str, plan_title]
	
	ask_ai("strategist", prompt, {}, func(ans: Dictionary) -> void:
		if ans.is_empty():
			return
		var text: String = str(ans.get("text", ans.get("advice", ans.get("description", ""))))
		if text.is_empty():
			return
		
		var descriptions: Dictionary = _store.get("country_descriptions") if _store.get("country_descriptions") != null else {}
		descriptions[c_name] = {
			"text": text,
			"day": _game.day(),
			"hash": str(s.get("hash", ""))
		}
		_store.set("country_descriptions", descriptions)
		
		if _window_ui != null and _window_ui.has_method("refresh_all"):
			_window_ui.call("refresh_all")
	)
