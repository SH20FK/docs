# lib/icons.gd
# Нативная подсистема векторных SVG-иконок для строгого научно-стратегического интерфейса.
# Рендерится на лету через встроенный векторный движок ThorVG в ImageTexture высокого разрешения.

extends RefCounted

static var _icon_cache: Dictionary = {}

const SVG_ICONS: Dictionary = {
	"academic": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M6 10v6c0 3 3 5 6 5s6-2 6-5v-6"/><circle cx="12" cy="12" r="2" fill="#ffd54f"/></svg>',
	"commander": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.5 4L20 9.5 7 22.5 1.5 17 14.5 4z"/><path d="M9.5 4L4 9.5 17 22.5 22.5 17 9.5 4z"/><circle cx="12" cy="13.25" r="2.5" fill="#ff5252"/></svg>',
	"fox": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4l4 10 4-4 4 4 4-10-8 4-8-4z"/><path d="M8 14l4 7 4-7"/><circle cx="9" cy="9" r="1" fill="#ffab40"/><circle cx="15" cy="9" r="1" fill="#ffab40"/></svg>',
	"oracle": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 3a9 9 0 0 0 0 18v-18z" fill="#b388ff" fill-opacity="0.3"/><path d="M12 7l1.5 3.5L17 12l-3.5 1.5L12 17l-1.5-3.5L7 12l3.5-1.5L12 7z" fill="#e040fb"/></svg>',
	"fortress": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2L3 6v6c0 5.5 3.8 10.7 9 12 5.2-1.3 9-6.5 9-12V6l-9-4z"/><path d="M12 7v10"/><path d="M8 11h8"/></svg>',
	"space": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/><path d="M12 15l-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-4.05 11a22.4 22.4 0 0 1-3.95 2z"/><path d="M9 12l2 2"/><circle cx="15" cy="9" r="1" fill="#4fc3f7"/></svg>',
	"hegemony": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 16L3 5l5.5 5L12 4l3.5 6L21 5l-2 11H5z"/><path d="M5 19h14"/><path d="M12 11v5"/></svg>',
	"target": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2" fill="#ffd54f"/><path d="M12 2v3m0 14v3M2 12h3m14 0h3"/></svg>',
	"threat": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#ff5252" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>',
	"opportunity": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#40c4ff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M12 8l4 4-4 4"/><path d="M8 12h8"/></svg>',
	"order": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#ffd54f" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" fill="#ffd54f" fill-opacity="0.2"/></svg>',
	"check": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#69f0ae" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><polyline points="9 12 11.5 14.5 16 9.5"/></svg>',
	"cross": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#ff5252" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>',
	"hourglass": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 22h14"/><path d="M5 2h14"/><path d="M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22"/><path d="M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2"/></svg>',
	"scroll": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M19 17V5a2 2 0 0 0-2-2H4"/><path d="M8 21h12a2 2 0 0 0 2-2v-2H10v2a2 2 0 1 1-4 0V5a2 2 0 1 0-4 0v14a2 2 0 0 0 2 2z"/><line x1="8" y1="7" x2="16" y2="7"/><line x1="8" y1="11" x2="14" y2="11"/></svg>',
	"insight": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#ffd54f" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6"/><path d="M10 22h4"/><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1 .23 2.23 1.5 3.5A4.61 4.61 0 0 1 8.91 14"/></svg>',
	"capitol": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 22h16"/><path d="M4 11h16"/><path d="M12 2L2 7h20l-10-5z"/><path d="M6 11v11"/><path d="M10 11v11"/><path d="M14 11v11"/><path d="M18 11v11"/></svg>',
	"refresh": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="#e0e8f5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6"/><path d="M2.5 22v-6h6"/><path d="M2 11.5a10 10 0 0 1 18.8-4.3L21.5 8"/><path d="M22 12.5a10 10 0 0 1-18.8 4.2L2.5 16"/></svg>',
	"star": '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="#ffd54f" stroke="#ffd54f" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>'
}

static func _normalize_key(key: String) -> String:
	match key:
		"academic", "akademik":
			return "academic"
		"commander", "komandir":
			return "commander"
		"fox", "lis":
			return "fox"
		"oracle", "orakul":
			return "oracle"
		"fortress":
			return "fortress"
		"space":
			return "space"
		"hegemony":
			return "hegemony"
		"target", "goal":
			return "target"
		"threat":
			return "threat"
		"opportunity", "opp":
			return "opportunity"
		"order":
			return "order"
		"check", "done":
			return "check"
		"cross", "failed":
			return "cross"
		"hourglass", "pending":
			return "hourglass"
		"scroll", "chronicle":
			return "scroll"
		"insight", "advice":
			return "insight"
		"capitol", "nation":
			return "capitol"
		"refresh":
			return "refresh"
		"star":
			return "star"
		_:
			return "star"

static func get_icon(name_key: String, size_px: int = 18) -> Texture2D:
	var norm_key: String = _normalize_key(name_key)
	var cache_key: String = "%s_%d" % [norm_key, size_px]
	if _icon_cache.has(cache_key):
		return _icon_cache[cache_key]

	if not SVG_ICONS.has(norm_key):
		return null

	var svg_str: String = str(SVG_ICONS[norm_key])
	var img: Image = Image.new()
	# Рендерим SVG под точный размер (базовый viewBox 24x24 px)
	var scale_factor: float = float(size_px) / 24.0
	var err: Error = img.load_svg_from_string(svg_str, scale_factor)
	if err == OK:
		var tex: ImageTexture = ImageTexture.create_from_image(img)
		_icon_cache[cache_key] = tex
		return tex

	return null

static func create_icon_rect(name_key: String, size_px: Vector2 = Vector2(16, 16), tint: Color = Color.WHITE) -> TextureRect:
	var tr: TextureRect = TextureRect.new()
	tr.texture = get_icon(name_key, int(maxf(size_px.x, size_px.y)))
	tr.custom_minimum_size = size_px
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = tint
	tr.mouse_filter = Control.MOUSE_FILTER_PASS
	return tr

static func create_icon_row(
	name_key: String,
	text_str: String,
	font_sz: int = 12,
	text_color: Color = Color.WHITE,
	icon_tint: Color = Color.WHITE,
	icon_sz: Vector2 = Vector2(16, 16)
) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS

	var ic: TextureRect = create_icon_rect(name_key, icon_sz, icon_tint)
	row.add_child(ic)

	var lbl: Label = Label.new()
	lbl.text = text_str
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", text_color)
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(lbl)

	return row

