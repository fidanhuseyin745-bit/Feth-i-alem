extends Control
class_name GameHUD

## Mobil UI sistemi - HUD, butonlar, kaynaklar

signal button_pressed(action: String)
signal selection_mode_changed(mode: String)

@export var show_debug_info: bool = false

# Kaynak göstergeleri
@onready var gold_label: Label = $TopBar/Resources/GoldValue
@onready var food_label: Label = $TopBar/Resources/FoodValue
@onready var materials_label: Label = $TopBar/Resources/MaterialsValue
@onready var turn_label: Label = $TopBar/TurnLabel
@onready var population_label: Label = $TopBar/Resources/PopulationValue

# Butonlar
@onready var end_turn_btn: Button = $BottomBar/EndTurnBtn
@onready var attack_btn: Button = $BottomBar/AttackBtn
@onready var build_btn: Button = $BottomBar/BuildBtn
@onready var recruit_btn: Button = $BottomBar/RecruitBtn

# Seçim paneli
@onready var selection_panel: Panel = $SelectionPanel
@onready var selected_count_label: Label = $SelectionPanel/SelectedCount
@onready var unit_info_label: Label = $SelectionPanel/UnitInfo

# Şehir paneli
@onready var city_panel: Panel = $CityPanel
@onready var city_name_label: Label = $CityPanel/CityName
@onready var city_owner_label: Label = $CityPanel/CityOwner
@onready var city_defense_label: Label = $CityPanel/CityDefense
@onready var city_income_label: Label = $CityPanel/CityIncome
@onready var city_buildings_list: Label = $CityPanel/BuildingsList

# Minimap
@onready var minimap: TextureRect = $Minimap/MinimapTexture

# Joystick (mobil)
@onready var joystick_base: Control = $MobileControls/JoystickBase
@onready var joystick_knob: Control = $MobileControls/JoystickBase/JoystickKnob

var joystick_active: bool = false
var joystick_center: Vector2 = Vector2.ZERO
var joystick_input: Vector2 = Vector2.ZERO

var current_city_selected: Node = null
var selection_mode: String = "move"  # "move", "attack", "build"

func _ready():
	_setup_ui()
	_connect_signals()

func _setup_ui():
	# Kaynak panelini gizle başlangıçta
	selection_panel.visible = false
	city_panel.visible = false
	
	# Mobil kontrolleri ayarla
	joystick_base.visible = true
	joystick_knob.position = joystick_base.size / 2
	
	# Buton stillerini uygula
	_apply_button_styles()

func _apply_button_styles():
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.15, 0.1, 0.9)
	normal_style.set_corner_radius_all(8)
	normal_style.border_color = Color(0.9, 0.7, 0.1)
	normal_style.border_width_left = 2
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.25, 0.15, 0.9)
	hover_style.set_corner_radius_all(8)
	hover_style.border_color = Color(1, 0.9, 0.3)
	hover_style.border_width_left = 3
	
	for btn in [end_turn_btn, attack_btn, build_btn, recruit_btn]:
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))

func _connect_signals():
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	attack_btn.pressed.connect(_on_attack_pressed)
	build_btn.pressed.connect(_on_build_pressed)
	recruit_btn.pressed.connect(_on_recruit_pressed)

# ── Kaynak Güncelleme ──────────────────────────────────────────────────────

func update_resources(gold: int, food: int, materials: int, population: int = 0):
	gold_label.text = "🪙 %d" % gold
	food_label.text = "🍖 %d" % food
	materials_label.text = "🧱 %d" % materials
	population_label.text = "👥 %d" % population if population > 0 else ""

func update_turn(turn: int):
	turn_label.text = "Tur: %d" % turn

func update_selection(selected_count: int, units_info: String = ""):
	if selected_count > 0:
		selection_panel.visible = true
		selected_count_label.text = "%d birim seçili" % selected_count
		unit_info_label.text = units_info
	else:
		selection_panel.visible = false

func update_city_info(city):
	if not city:
		city_panel.visible = false
		return
	
	city_panel.visible = true
	city_name_label.text = city.city_name
	
	var owner_names = {
		"ottoman": "Osmanlı",
		"byzantine": "Bizans",
		"karamanid": "Karamanoğlu",
		"albania": "Arnavutluk",
		"venice": "Venedik",
		"akkoyunlu": "Akkoyunlu"
	}
	city_owner_label.text = "Sahip: " + owner_names.get(city.owner, city.owner)
	city_defense_label.text = "Savunma: %d/%d" % [city.defense_strength, city.max_defense]
	city_income_label.text = "Gelir: %d/turn" % city.income_per_turn
	
	var buildings_text = "Binalar:\n"
	for building in city.buildings:
		buildings_text += "• %s\n" % building
	city_buildings_list.text = buildings_text

# ── Buton İşleyiciler ──────────────────────────────────────────────────────

func _on_end_turn_pressed():
	button_pressed.emit("end_turn")

func _on_attack_pressed():
	button_pressed.emit("attack")
	selection_mode = "attack"
	selection_mode_changed.emit("attack")

func _on_build_pressed():
	button_pressed.emit("build")
	selection_mode = "build"
	selection_mode_changed.emit("build")

func _on_recruit_pressed():
	button_pressed.emit("recruit")
	_show_recruit_menu()

func _show_recruit_menu():
	# Ünite üretim menüsü göster
	var menu = ConfirmationDialog.new()
	menu.title = "Birim Üret"
	menu.dialog_text = "Hangi birimi üretmek istiyorsun?\n\n🗡 Piyade (50 altın)\n🐴 Süvari (80 altın)\n🏹 Okçu (60 altın)"
	
	var recruit_dialog = Popup.new()
	recruit_dialog.popup_exclusive = true
	
	var vbox = VBoxContainer.new()
	
	var infantry_btn = Button.new()
	infantry_btn.text = "🗡 Piyade - 50 Altın"
	infantry_btn.pressed.connect(func(): _recruit_unit("piyade", 50))
	vbox.add_child(infantry_btn)
	
	var cavalry_btn = Button.new()
	cavalry_btn.text = "🐴 Süvari - 80 Altın"
	cavalry_btn.pressed.connect(func(): _recruit_unit("süvari", 80))
	vbox.add_child(cavalry_btn)
	
	var archer_btn = Button.new()
	archer_btn.text = "🏹 Okçu - 60 Altın"
	archer_btn.pressed.connect(func(): _recruit_unit("okçu", 60))
	vbox.add_child(archer_btn)
	
	recruit_dialog.add_child(vbox)
	add_child(recruit_dialog)
	recruit_dialog.popup_centered()

func _recruit_unit(unit_type: String, cost: int):
	button_pressed.emit("recruit_" + unit_type)

# ── Mobil Kontroller ──────────────────────────────────────────────────────

func _input(event):
	_handle_joystick_input(event)

func _handle_joystick_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed and _is_joystick_area(event.position):
			joystick_active = true
			joystick_center = event.position
			_update_joystick(event.position)
		elif not event.pressed and joystick_active:
			joystick_active = false
			joystick_input = Vector2.ZERO
			joystick_knob.position = joystick_base.size / 2
	elif event is InputEventScreenDrag and joystick_active:
		_update_joystick(event.position)

func _is_joystick_area(pos: Vector2) -> bool:
	# Sol alt köşe joystick alanı
	var joystick_rect = Rect2(
		Vector2(50, get_viewport_rect().size.y - 200),
		Vector2(150, 150)
	)
	return joystick_rect.has_point(pos)

func _update_joystick(touch_pos: Vector2):
	var offset = touch_pos - joystick_center
	var max_distance = 60.0
	
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	
	joystick_input = offset / max_distance
	joystick_knob.position = joystick_base.size / 2 + offset

func get_joystick_input() -> Vector2:
	return joystick_input

# ── Mesajlar / Bildirimler ─────────────────────────────────────────────────

func show_message(msg: String, duration: float = 2.0):
	var label = Label.new()
	label.text = msg
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	label.z_index = 100
	
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.tween_callback(label.queue_free)

func show_toast(msg: String):
	var toast = Label.new()
	toast.text = msg
	toast.add_theme_font_size_override("font_size", 18)
	toast.add_theme_color_override("font_color", Color(1, 1, 1))
	toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast.position.y = get_viewport_rect().size.y - 150
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	add_child(toast)
	
	var tween = create_tween()
	tween.tween_property(toast, "position:y", toast.position.y - 50, 1.5)
	tween.tween_property(toast, "modulate:a", 0.0, 1.5)
	tween.tween_callback(toast.queue_free)

# ── Minimap ────────────────────────────────────────────────────────────────

func update_minimap(player_pos: Vector3, cities: Dictionary, units: Array):
	# Minimap texture güncelleme (daha sonra grafik ile değiştirilebilir)
	pass

# ── Durum Göstergeleri ─────────────────────────────────────────────────────

func show_siege_warning(city_name: String):
	show_message("⚔️ %s kuşatıldı!" % city_name, 3.0)

func show_city_captured(city_name: String, new_owner: String):
	show_message("🏰 %s fethedildi! Yeni sahip: %s" % [city_name, new_owner], 4.0)

func show_victory():
	show_message("☪️ ZAFER! İSTANBUL FETHEDİLDİ!", 5.0)