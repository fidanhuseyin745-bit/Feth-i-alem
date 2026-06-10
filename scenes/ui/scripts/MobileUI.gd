extends Control
class_name MobileUI

## Mobil UI Yöneticisi - Genişletilmiş UI sistemi

signal ui_button_pressed(action: String)
signal profession_selected(prof: int)
signal item_used(item: Dictionary)

const ProfessionSystem = preload("res://scenes/3d/scripts/ProfessionSystem.gd")

# UI Panelleri
var main_hud: Control
var profession_panel: Control
var inventory_panel: Control
var map_panel: Control
var trade_panel: Control
var city_panel: Control

# Oyuncu referansı
var player: Node = null
var city_manager: Node = null

# Mevcut panel durumu
var current_panel: String = ""
var is_expanded: bool = false

func _ready():
	_setup_ui()
	_create_panels()

func _setup_ui():
	# Ana HUD
	main_hud = self
	
	# Butonlar için varsayılan stil
	theme = _create_theme()

func _create_theme() -> Theme:
	var theme = Theme.new()
	
	# Buton stili
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
	button_style.set_corner_radius_all(8)
	button_style.border_color = Color(0.9, 0.7, 0.1)
	button_style.border_width_left = 2
	
	theme.set_stylebox("normal", "Button", button_style)
	
	return theme

func _create_panels():
	_create_main_hud()
	_create_profession_panel()
	_create_inventory_panel()
	_create_map_panel()

func _create_main_hud():
	# Üst bar - Kaynaklar
	var top_bar = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.anchors_preset = 5
	top_bar.anchor_left = 0
	top_bar.anchor_top = 0
	top_bar.anchor_right = 0
	top_bar.anchor_bottom = 0
	top_bar.offset_left = 10
	top_bar.offset_top = 10
	top_bar.offset_right = 400
	top_bar.offset_bottom = 90
	add_child(top_bar)
	
	var hbox = HBoxContainer.new()
	top_bar.add_child(hbox)
	
	# Altın
	var gold_label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.text = "🪙 5000"
	hbox.add_child(gold_label)
	
	# Yiyecek
	var food_label = Label.new()
	food_label.name = "FoodLabel"
	food_label.text = " 🍖 1000"
	hbox.add_child(food_label)
	
	# Tur
	var turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = " | Tur: 1"
	hbox.add_child(turn_label)
	
	# Sağ üst - Meslek göstergesi
	var prof_indicator = Label.new()
	prof_indicator.name = "ProfessionIndicator"
	prof_indicator.text = "⚔️ Savaşçı Lv.1"
	prof_indicator.horizontal_alignment = 2
	add_child(prof_indicator)
	
	# Alt bar - Eylemler
	var bottom_bar = PanelContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.anchors_preset = 8
	bottom_bar.anchor_left = 0.5
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 0.5
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = -300
	bottom_bar.offset_top = -90
	bottom_bar.offset_right = 300
	bottom_bar.offset_bottom = -10
	add_child(bottom_bar)
	
	var actions_hbox = HBoxContainer.new()
	bottom_bar.add_child(actions_hbox)
	
	# Eylem butonları
	var actions = [
		{"name": "EndTurn", "text": "⬅️ Tur Bitir", "icon": "⏭️"},
		{"name": "Attack", "text": "⚔️ Saldır", "icon": "⚔️"},
		{"name": "Build", "text": "🏗️ İnşa", "icon": "🏗️"},
		{"name": "Recruit", "text": "👤 Üret", "icon": "👤"},
		{"name": "Trade", "text": "💰 Ticaret", "icon": "💰"},
		{"name": "Profession", "text": "⚔️ Meslek", "icon": "⚔️"}
	]
	
	for action in actions:
		var btn = Button.new()
		btn.name = action["name"] + "Btn"
		btn.text = action["text"]
		btn.pressed.connect(_on_action_button.bind(action["name"]))
		actions_hbox.add_child(btn)

func _create_profession_panel():
	profession_panel = PanelContainer.new()
	profession_panel.name = "ProfessionPanel"
	profession_panel.visible = false
	profession_panel.anchors_preset = 8
	profession_panel.anchor_left = 0.5
	profession_panel.anchor_top = 0.5
	profession_panel.anchor_right = 0.5
	profession_panel.anchor_bottom = 0.5
	profession_panel.offset_left = -250
	profession_panel.offset_top = -200
	profession_panel.offset_right = 250
	profession_panel.offset_bottom = 200
	add_child(profession_panel)
	
	var scroll = ScrollContainer.new()
	profession_panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	# Başlık
	var title = Label.new()
	title.text = "⚔️ MESLEK SEÇ"
	title.horizontal_alignment = 1
	vbox.add_child(title)
	
	# Meslekler
	var professions = [
		{"id": ProfessionSystem.Profession.WARRIOR, "name": "Savaşçı", "desc": "Yakın dövüş ustası", "icon": "⚔️"},
		{"id": ProfessionSystem.Profession.MERCHANT, "name": "Tüccar", "desc": "Ticaret uzmanı", "icon": "💰"},
		{"id": ProfessionSystem.Profession.FARMER, "name": "Çiftçi", "desc": "Tarım ustası", "icon": "🌾"},
		{"id": ProfessionSystem.Profession.MINER, "name": "Madenci", "desc": "Maden ustası", "icon": "⛏️"},
		{"id": ProfessionSystem.Profession.FISHER, "name": "Balıkçı", "desc": "Deniz ustası", "icon": "🐟"},
		{"id": ProfessionSystem.Profession.BLACKSMITH, "name": "Demirci", "desc": "Silah ustası", "icon": "🔨"},
		{"id": ProfessionSystem.Profession.ARCHER, "name": "Okçu", "desc": "Uzaktan usta", "icon": "🏹"},
		{"id": ProfessionSystem.Profession.HEALER, "name": "Şifacı", "desc": "Şifa ustası", "icon": "💊"},
		{"id": ProfessionSystem.Profession.SCOUT, "name": "Kaşif", "desc": "Keşif ustası", "icon": "🗺️"},
		{"id": ProfessionSystem.Profession.KNIGHT, "name": "Şövalye", "desc": "Süvari birliği", "icon": "🛡️"},
	]
	
	for prof in professions:
		var btn = Button.new()
		btn.text = "%s %s\n%s" % [prof["icon"], prof["name"], prof["desc"]]
		btn.pressed.connect(_on_profession_selected.bind(prof["id"]))
		vbox.add_child(btn)
	
	# Kapat butonu
	var close_btn = Button.new()
	close_btn.text = "✖️ Kapat"
	close_btn.pressed.connect(_close_panel.bind("ProfessionPanel"))
	vbox.add_child(close_btn)

func _create_inventory_panel():
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.visible = false
	inventory_panel.anchors_preset = 1
	inventory_panel.anchor_left = 1.0
	inventory_panel.anchor_top = 0.0
	inventory_panel.anchor_right = 1.0
	inventory_panel.anchor_bottom = 0.0
	inventory_panel.offset_left = -300
	inventory_panel.offset_top = 100
	inventory_panel.offset_right = -10
	inventory_panel.offset_bottom = -100
	add_child(inventory_panel)
	
	var scroll = ScrollContainer.new()
	inventory_panel.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "🎒 ENVANTER"
	vbox.add_child(title)
	
	var empty_label = Label.new()
	empty_label.name = "EmptyLabel"
	empty_label.text = "Envanter boş"
	vbox.add_child(empty_label)

func _create_map_panel():
	map_panel = Control.new()
	map_panel.name = "MapPanel"
	map_panel.visible = false
	map_panel.anchors_preset = 2
	map_panel.anchor_top = 1.0
	map_panel.anchor_bottom = 1.0
	map_panel.offset_left = 10
	map_panel.offset_top = -350
	map_panel.offset_right = 250
	map_panel.offset_bottom = -10
	add_child(map_panel)
	
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.3, 0.2, 0.9)
	bg.size = Vector2(240, 340)
	map_panel.add_child(bg)
	
	var label = Label.new()
	label.text = "🗺️ HARİTA"
	label.position = Vector2(10, 10)
	map_panel.add_child(label)

func _on_action_button(action: String):
	match action:
		"EndTurn":
			ui_button_pressed.emit("end_turn")
		"Attack":
			ui_button_pressed.emit("attack")
		"Build":
			_show_build_menu()
		"Recruit":
			_show_recruit_menu()
		"Trade":
			_toggle_panel("TradePanel")
		"Profession":
			_toggle_panel("ProfessionPanel")
		"Inventory":
			_toggle_panel("InventoryPanel")
		"Map":
			_toggle_panel("MapPanel")

func _toggle_panel(panel_name: String):
	var panel = get_node_or_null(panel_name)
	if panel:
		panel.visible = not panel.visible
		current_panel = panel_name if panel.visible else ""

func _close_panel(panel_name: String):
	var panel = get_node_or_null(panel_name)
	if panel:
		panel.visible = false
		current_panel = ""

func _on_profession_selected(prof_id: int):
	profession_selected.emit(prof_id)
	_close_panel("ProfessionPanel")
	
	# Meslek göstergesini güncelle
	var indicator = get_node_or_null("ProfessionIndicator")
	if indicator:
		var prof_system = ProfessionSystem.new()
		indicator.text = prof_system.get_profession_name()

func _show_build_menu():
	var menu = _create_popup_menu("İnşa Et", [
		"🏰 Kale - 300 altın",
		"⚔️ Kışla - 500 altın",
		"🐴 Ahır - 400 altın",
		"🏹 Okçuluk - 350 altın",
		"📦 Depo - 200 altın",
		"🕌 Cami - 800 altın"
	])
	add_child(menu)
	menu.popup_centered()

func _show_recruit_menu():
	var menu = _create_popup_menu("Birim Üret", [
		"🗡️ Piyade - 50 altın",
		"🐴 Süvari - 80 altın",
		"🏹 Okçu - 60 altın"
	])
	add_child(menu)
	menu.popup_centered()

func _create_popup_menu(title: String, options: Array) -> PopupMenu:
	var popup = PopupMenu.new()
	popup.title = title
	
	for option in options:
		popup.add_item(option)
	
	return popup

func update_resources(gold: int, food: int, materials: int = 0):
	var gold_label = get_node_or_null("TopBar/GoldLabel")
	if gold_label:
		gold_label.text = "🪙 %d" % gold
	
	var food_label = get_node_or_null("TopBar/FoodLabel")
	if food_label:
		food_label.text = " 🍖 %d" % food

func update_turn(turn: int):
	var turn_label = get_node_or_null("TopBar/TurnLabel")
	if turn_label:
		turn_label.text = " | Tur: %d" % turn

func update_profession(prof_name: String, level: int):
	var indicator = get_node_or_null("ProfessionIndicator")
	if indicator:
		indicator.text = "%s Lv.%d" % [prof_name, level]

func update_inventory(items: Array):
	var empty_label = inventory_panel.get_node_or_null("EmptyLabel")
	if empty_label:
		empty_label.visible = items.size() == 0

func show_city_info(city_data):
	# Şehir bilgi panelini göster
	pass

func show_notification(message: String, duration: float = 2.0):
	var notification = Label.new()
	notification.text = message
	notification.horizontal_alignment = 1
	notification.vertical_alignment = 1
	notification.set_anchors_preset(8)
	notification.anchor_left = 0.5
	notification.anchor_top = 0.3
	notification.anchor_right = 0.5
	notification.anchor_bottom = 0.3
	notification.offset_left = -200
	notification.offset_right = 200
	notification.add_theme_font_size_override("font_size", 24)
	notification.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	notification.z_index = 100
	
	add_child(notification)
	
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, duration)
	tween.tween_callback(notification.queue_free)

func show_toast(message: String):
	var toast = Label.new()
	toast.text = message
	toast.add_theme_font_size_override("font_size", 16)
	toast.add_theme_color_override("font_color", Color.WHITE)
	toast.set_anchors_preset(5)
	toast.anchor_left = 0.5
	toast.anchor_top = 1.0
	toast.anchor_right = 0.5
	toast.anchor_bottom = 1.0
	toast.offset_left = -150
	toast.offset_top = -50
	toast.offset_right = 150
	toast.offset_bottom = -20
	toast.horizontal_alignment = 1
	
	add_child(toast)
	
	var tween = create_tween()
	tween.tween_property(toast, "position:y", toast.position.y - 30, 2.0)
	tween.tween_property(toast, "modulate:a", 0.0, 2.0)
	tween.tween_callback(toast.queue_free)

# ── Joystick Kontrol ──────────────────────────────────────────────────────

var joystick_base: Control
var joystick_knob: Control
var joystick_input: Vector2 = Vector2.ZERO
var joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO

func setup_joystick():
	joystick_base = Control.new()
	joystick_base.name = "JoystickBase"
	joystick_base.anchors_preset = 2
	joystick_base.anchor_top = 1.0
	joystick_base.anchor_bottom = 1.0
	joystick_base.offset_left = 30
	joystick_base.offset_top = -200
	joystick_base.offset_right = 180
	joystick_base.offset_bottom = -30
	add_child(joystick_base)
	
	var bg = ColorRect.new()
	bg.color = Color(0.3, 0.3, 0.3, 0.5)
	bg.size = Vector2(150, 150)
	bg.position = Vector2(0, 0)
	joystick_base.add_child(bg)
	
	joystick_knob = ColorRect.new()
	joystick_knob.color = Color(0.9, 0.7, 0.1, 0.8)
	joystick_knob.size = Vector2(60, 60)
	joystick_knob.position = Vector2(45, 45)
	joystick_base.add_child(joystick_knob)

func _input(event):
	_handle_joystick(event)

func _handle_joystick(event: InputEvent):
	if not joystick_base:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed and _is_in_joystick_area(event.position):
			joystick_active = true
			joystick_center = event.position
			_update_joystick(event.position)
		elif not event.pressed:
			joystick_active = false
			joystick_input = Vector2.ZERO
			joystick_knob.position = Vector2(45, 45)
	
	elif event is InputEventScreenDrag and joystick_active:
		_update_joystick(event.position)

func _is_in_joystick_area(pos: Vector2) -> bool:
	var rect = Rect2(Vector2(30, get_viewport_rect().size.y - 200), Vector2(150, 150))
	return rect.has_point(pos)

func _update_joystick(touch_pos: Vector2):
	var offset = touch_pos - joystick_center
	var max_distance = 60.0
	
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	
	joystick_input = offset / max_distance
	joystick_knob.position = Vector2(45, 45) + offset
	
	if player:
		player.set_joystick_input(joystick_input)

func get_joystick_input() -> Vector2:
	return joystick_input