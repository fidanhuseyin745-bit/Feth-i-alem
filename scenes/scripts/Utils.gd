extends Node

# --- StyleBox helpers ---

static func create_style_box(
	bg_color: Color,
	corner_radius: int = 10,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(corner_radius)
	if border_width > 0:
		style.border_color = border_color
		style.set_border_width_all(border_width)
	return style

static func apply_button_style(
	btn: Button,
	bg_color: Color,
	font_color: Color,
	corner_radius: int = 10,
	border_color: Color = Color.TRANSPARENT,
	border_width: int = 0
) -> void:
	var style = create_style_box(bg_color, corner_radius, border_color, border_width)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", font_color)

# --- Dialog helper ---

static func show_dialog(parent: Node, title: String, text: String, size: Vector2 = Vector2(500, 400)) -> AcceptDialog:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = text
	parent.add_child(dialog)
	dialog.popup_centered(size)
	return dialog

# --- Toast message helper ---

static func show_toast(
	parent: Node,
	tween_source: Node,
	msg: String,
	font_size: int = 18,
	font_color: Color = Color(1, 0.9, 0.2),
	start_pos: Vector2 = Vector2(150, 400),
	rise_amount: float = 60.0,
	duration: float = 1.5
) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", font_color)
	lbl.position = start_pos
	parent.add_child(lbl)
	var tw = tween_source.create_tween()
	tw.tween_property(lbl, "position:y", start_pos.y - rise_amount, duration)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, duration)
	tw.tween_callback(lbl.queue_free)

# --- Gold spending helper ---

static func try_spend_gold(game_state: Dictionary, cost: int) -> bool:
	if game_state["gold"] >= cost:
		game_state["gold"] -= cost
		return true
	return false
