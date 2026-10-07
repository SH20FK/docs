# lib/doctrines.gd
# Долгосрочные государственные доктрины державы (на 10-25 лет).

const FORTRESS: String = "fortress"
const SPACE: String = "space"
const HEGEMONY: String = "hegemony"

static func get_all() -> Array:
	return [
		{
			"id": FORTRESS,
			"icon_key": "fortress",
			"name_key": "strat_doctrine_fortress",
			"desc_key": "strat_doctrine_fortress_desc"
		},
		{
			"id": SPACE,
			"icon_key": "space",
			"name_key": "strat_doctrine_space",
			"desc_key": "strat_doctrine_space_desc"
		},
		{
			"id": HEGEMONY,
			"icon_key": "hegemony",
			"name_key": "strat_doctrine_hegemony",
			"desc_key": "strat_doctrine_hegemony_desc"
		}
	]

static func get_prompt_modifier(doctrine_id: String) -> String:
	match doctrine_id:
		FORTRESS:
			return "Генеральная доктрина: «Крепость Держава». Приоритет — укрепление границ, накопление резервов казны и материалов, продовольственная самодостаточность, избегание авантюрных войн."
		SPACE:
			return "Генеральная доктрина: «Космический прорыв». Приоритет — развитие колоний на Луне и планетах, энергосеть, наука, строительство и запуск ковчегов к звёздам."
		HEGEMONY:
			return "Генеральная доктрина: «Континентальная гегемония». Приоритет — военное превосходство, расширение подконтрольных территорий, создание пояса буферных сателлитов и подчинение соперников."
		_:
			return "Генеральная доктрина: Сбалансированное развитие державы."
