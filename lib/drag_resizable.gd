# lib/drag_resizable.gd
# Универсальный контроллер для перемещения (drag) и изменения размера (resize) окон и модальных панелей с соблюдением Safe Zone.

extends RefCounted

# Прикрепляет поведение перетаскивания и растягивания к любой панели Control
static func setup_window(
	target_window: Control,
	drag_handle: Control,
	min_size: Vector2 = Vector2(400, 300),
	safe_top: float = 46.0,
	safe_bottom: float = 38.0,
	safe_left: float = 12.0,
	safe_right: float = 12.0
) -> Control:
	if target_window == null:
		return null

	target_window.custom_minimum_size = min_size

	# 1. Логика перетаскивания (Drag)
	var is_dragging: Dictionary = {"active": false, "offset": Vector2.ZERO}
	var handle_control: Control = drag_handle if drag_handle != null else target_window

	handle_control.mouse_filter = Control.MOUSE_FILTER_STOP
	handle_control.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					is_dragging["active"] = true
					is_dragging["offset"] = target_window.get_global_mouse_position() - target_window.global_position
				else:
					is_dragging["active"] = false
		elif event is InputEventMouseMotion and bool(is_dragging["active"]):
			var new_pos: Vector2 = target_window.get_global_mouse_position() - Vector2(is_dragging["offset"])
			clamp_to_safe_zone(target_window, new_pos, safe_top, safe_bottom, safe_left, safe_right)
	)

	# 2. Рукоятка растягивания в правом нижнем углу (Resize Grip)
	var grip: Control = _create_resize_grip(target_window, min_size, safe_top, safe_bottom, safe_left, safe_right)
	return grip

# Ограничение позиции окна безопасными границами экрана
static func clamp_to_safe_zone(
	target_window: Control,
	wanted_pos: Vector2,
	safe_top: float = 46.0,
	safe_bottom: float = 38.0,
	safe_left: float = 12.0,
	safe_right: float = 12.0
) -> void:
	var vp: Viewport = target_window.get_viewport()
	if vp == null:
		target_window.global_position = wanted_pos
		return

	var vp_size: Vector2 = vp.get_visible_rect().size
	var win_size: Vector2 = target_window.size

	# Окно никогда не должно вылезать за верхнюю/нижнюю панель и края экрана
	var max_x: float = maxf(safe_left, vp_size.x - win_size.x - safe_right)
	var max_y: float = maxf(safe_top, vp_size.y - win_size.y - safe_bottom)

	var clamped_x: float = clampf(wanted_pos.x, safe_left, max_x)
	var clamped_y: float = clampf(wanted_pos.y, safe_top, max_y)

	target_window.global_position = Vector2(clamped_x, clamped_y)

# Создание ручки растягивания (Resize Grip)
static func _create_resize_grip(
	target_window: Control,
	min_sz: Vector2,
	safe_top: float,
	safe_bottom: float,
	safe_left: float,
	safe_right: float
) -> Control:
	var grip_btn: Control = Control.new()
	grip_btn.custom_minimum_size = Vector2(18, 18)
	grip_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	grip_btn.size_flags_vertical = Control.SIZE_SHRINK_END
	grip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	grip_btn.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE

	# Отрисовка насечек в углу
	grip_btn.draw.connect(func() -> void:
		var c: Color = Color(0.65, 0.75, 0.85, 0.6)
		grip_btn.draw_line(Vector2(14, 6), Vector2(6, 14), c, 1.5)
		grip_btn.draw_line(Vector2(14, 10), Vector2(10, 14), c, 1.5)
		grip_btn.draw_line(Vector2(14, 14), Vector2(14, 14), c, 1.5)
	)

	var is_resizing: Dictionary = {"active": false, "start_mouse": Vector2.ZERO, "start_size": Vector2.ZERO}

	grip_btn.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					is_resizing["active"] = true
					is_resizing["start_mouse"] = target_window.get_global_mouse_position()
					is_resizing["start_size"] = target_window.size
				else:
					is_resizing["active"] = false
		elif event is InputEventMouseMotion and bool(is_resizing["active"]):
			var delta: Vector2 = target_window.get_global_mouse_position() - Vector2(is_resizing["start_mouse"])
			var target_sz: Vector2 = Vector2(is_resizing["start_size"]) + delta

			var vp: Viewport = target_window.get_viewport()
			var max_w: float = 1920.0
			var max_h: float = 1080.0
			if vp != null:
				var vp_rect: Rect2 = vp.get_visible_rect()
				max_w = vp_rect.size.x - target_window.global_position.x - safe_right
				max_h = vp_rect.size.y - target_window.global_position.y - safe_bottom

			var new_w: float = clampf(target_sz.x, min_sz.x, max_w)
			var new_h: float = clampf(target_sz.y, min_sz.y, max_h)

			target_window.size = Vector2(new_w, new_h)
			target_window.custom_minimum_size = Vector2(new_w, new_h)
	)

	target_window.add_child(grip_btn)
	return grip_btn
