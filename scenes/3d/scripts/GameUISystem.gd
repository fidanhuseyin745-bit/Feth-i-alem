extends CanvasLayer
class_name GameUISystem

## Genshin Impact tarzı kapsamlı UI sistemi

signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)
signal action_performed(action: String, data: Dictionary)

# UI Referansları
var top_bar: Control
var bottom_bar: Control
var action_menu: Control
var profession_panel: Control
var inventory_panel: Control
var quest_panel: Control
var settings_panel: Control
var notification_area: Control
var loading_screen: Control

# Durum
var current_menu: String = ""
var is_paused: bool = false
var is_fullscreen: bool = false

# Tema renkleri (Genshin tarzı)
var theme_colors = {
	"primary": Color(0.2, 0.15, 0.35),      # Koyu mor
	"secondary": Color(0.9, 0.7, 0.1),       # Altın
	"accent": Color(0.3, 0.5, 0.8),           # Mavi
	"success": Color(0.2, 0.8, 0.3),          # Yeşil
	"danger": Color(0.9, 0.2, 0.2),           # Kırmızı
	"text": Color(1, 1, 1),
	"text_secondary": Color(0.7, 0.7, 0.7)
}

func _ready() -> void:
	_setup_theme()
	_create_all_ui()
	_show_initial_ui()

func _setup_theme() -> void:
	var theme = Theme.new()
	
	# Buton stili
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.2, 0.15, 0.3, 0.9)
	btn_normal.set_corner_radius_all(8)
	btn_normal.border_color = theme_colors["secondary"]
	btn_normal.border_width_left = 2
	theme.set_stylebox("normal", "Button", btn_normal)
	
	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.3, 0.25, 0.4, 0.95)
	btn_hover.set_corner_radius_all(8)
	btn_hover.border_color = theme_colors["secondary"]
	btn_hover.border_width_left = 3
	theme.set_stylebox("hover", "Button", btn_hover)
	
	var btn_pressed = StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.4, 0.35, 0.5, 1)
	btn_pressed.set_corner_radius_all(8)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	
	# Panel stili
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	panel_style.set_corner_radius_all(12)
	panel_style.border_color = theme_colors["secondary"]
	panel_style.border_width_all = 2
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	
	# Label stili
	var label_style = Label.new()
	label_style.add_theme_color_override("font_color", theme_colors["text"])
	theme.set_default_font("sans-serif", label_style.get_theme_font("font"))
	
	self.theme = theme

func _create_all_ui() -> void:
	_create_loading_screen()
	_create_top_bar()
	_create_bottom_bar()
	_create_action_menu()
	_create_profession_panel()
	_create_inventory_panel()
	_create_quest_panel()
	_create_settings_panel()
	_create_notification_area()
	_create_minimap()

func _create_loading_screen() -> void:
	loading_screen = Control.new()
	loading_screen.name = "LoadingScreen"
	loading_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_screen.visible = false
	add_child(loading_screen)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.03, 0.1, 1)
	loading_screen.add_child(bg)
	
	var title = Label.new()
	title.text = "⚔️ FETH-İ ALEM ⚔️"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", theme_colors["secondary"])
	loading_screen.add_child(title)
	
	var progress = Label.new()
	progress.name = "Progress"
	progress.text = "Yükleniyor..."
	progress.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	progress.position.y = -100
	loading_screen.add_child(progress)

func _create_top_bar() -> void:
	top_bar = Control.new()
	top_bar.name = "TopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_top = 10
	top_bar.offset_left = 10
	top_bar.offset_right = -10
	top_bar.custom_minimum_size = Vector2(0, 60)
	add_child(top_bar)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.85)
	bg_style.set_corner_radius_all(10)
	bg.add_theme_stylebox_override("panel", bg_style)
	top_bar.add_child(bg)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	bg.add_child(hbox)
	
	# Altın
	var gold_container = _create_resource_display("🪙", "5000", "Gold")
	hbox.add_child(gold_container)
	
	# Yiyecek
	var food_container = _create_resource_display("🍖", "1000", "Food")
	hbox.add_child(food_container)
	
	# Malzeme
	var mats_container = _create_resource_display("🪵", "500", "Materials")
	hbox.add_child(mats_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# Tur
	var turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.text = "Tur: 1"
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.add_theme_color_override("font_color", theme_colors["text"])
	hbox.add_child(turn_label)
	
	# Meslek göstergesi
	var prof_label = Label.new()
	prof_label.name = "ProfessionLabel"
	prof_label.text = " ⚔️ Savaşçı Lv.1"
	prof_label.add_theme_font_size_override("font_size", 18)
	prof_label.add_theme_color_override("font_color", theme_colors["secondary"])
	hbox.add_child(prof_label)
	
	# Ayarlar butonu
	var settings_btn = Button.new()
	settings_btn.text = "⚙️"
	settings_btn.custom_minimum_size = Vector2(40, 40)
	settings_btn.pressed.connect(_on_settings_pressed)
	hbox.add_child(settings_btn)

func _create_resource_display(icon: String, value: String, name: String) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.name = name + "Container"
	container.custom_minimum_size = Vector2(100, 40)
	
	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 24)
	container.add_child(icon_label)
	
	var value_label = Label.new()
	value_label.name = name + "Value"
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", theme_colors["secondary"])
	container.add_child(value_label)
	
	return container

func _create_bottom_bar() -> void:
	bottom_bar = Control.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_bottom = -10
	bottom_bar.custom_minimum_size = Vector2(0, 80)
	add_child(bottom_bar)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.85)
	bg_style.set_corner_radius_all(10)
	bg.add_theme_stylebox_override("panel", bg_style)
	bottom_bar.add_child(bg)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(hbox)
	
	var actions = [
		{"name": "attack", "icon": "⚔️", "label": "Saldır"},
		{"name": "build", "icon": "🏗️", "label": "İnşa"},
		{"name": "recruit", "icon": "👤", "label": "Üret"},
		{"name": "trade", "icon": "💰", "label": "Ticaret"},
		{"name": "profession", "icon": "⚔️", "label": "Meslek"},
		{"name": "quests", "icon": "📜", "label": "Görevler"},
		{"name": "inventory", "icon": "🎒", "label": "Envanter"},
	]
	
	for action in actions:
		var btn = _create_action_button(action["icon"], action["label"])
		btn.pressed.connect(_on_action_button_pressed.bind(action["name"]))
		hbox.add_child(btn)

func _create_action_button(icon: String, label: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 60)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon_lbl = Label.new()
	icon_lbl.text = icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 24)
	vbox.add_child(icon_lbl)
	
	var label_lbl = Label.new()
	label_lbl.text = label
	label_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label_lbl)
	
	btn.add_child(vbox)
	return btn

func _create_action_menu() -> void:
	action_menu = Control.new()
	action_menu.name = "ActionMenu"
	action_menu.set_anchors_preset(Control.PRESET_CENTER)
	action_menu.custom_minimum_size = Vector2(400, 300)
	action_menu.visible = false
	add_child(action_menu)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.1, 0.2, 0.95)
	bg_style.set_corner_radius_all(15)
	bg_style.border_color = theme_colors["secondary"]
	bg_style.border_width_all = 3
	bg.add_theme_stylebox_override("panel", bg_style)
	action_menu.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(vbox)
	
	var title = Label.new()
	title.name = "Title"
	title.text = "AKSİYONLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", theme_colors["secondary"])
	vbox.add_child(title)
	
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(300, 2)
	vbox.add_child(separator)
	
	# Saldırı butonları
	var attack_section = _create_menu_section("⚔️ SALDIRI", [
		{"id": "attack_light", "text": "Hafif Saldırı - 10 stamina"},
		{"id": "attack_heavy", "text": "Ağır Saldırı - 25 stamina"},
		{"id": "attack_special", "text": "Özel Yetenek - 50 stamina"},
	])
	vbox.add_child(attack_section)

func _create_menu_section(title: String, items: Array) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.custom_minimum_size = Vector2(350, 40 * items.size())
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 18)
	title_lbl.add_theme_color_override("font_color", theme_colors["accent"])
	section.add_child(title_lbl)
	
	for item in items:
		var btn = Button.new()
		btn.text = item["text"]
		btn.custom_minimum_size = Vector2(300, 35)
		btn.pressed.connect(_on_menu_item_pressed.bind(item["id"]))
		section.add_child(btn)
	
	return section

func _create_profession_panel() -> void:
	profession_panel = Control.new()
	profession_panel.name = "ProfessionPanel"
	profession_panel.set_anchors_preset(Control.PRESET_CENTER)
	profession_panel.custom_minimum_size = Vector2(500, 600)
	profession_panel.visible = false
	add_child(profession_panel)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.97)
	bg_style.set_corner_radius_all(15)
	bg_style.border_color = theme_colors["secondary"]
	bg_style.border_width_all = 3
	bg.add_theme_stylebox_override("panel", bg_style)
	profession_panel.add_child(bg)
	
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bg.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(450, 550)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚔️ MESLEK SEÇİMİ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", theme_colors["secondary"])
	vbox.add_child(title)
	
	var professions = [
		{"id": 0, "name": "Savaşçı", "icon": "⚔️", "desc": "Yakın dövüş ustası", "cost": "Başlangıç"},
		{"id": 1, "name": "Tüccar", "icon": "💰", "desc": "Ticaret uzmanı", "cost": "1000 altın"},
		{"id": 2, "name": "Çiftçi", "icon": "🌾", "desc": "Tarım ustası", "cost": "500 altın"},
		{"id": 3, "name": "Madenci", "icon": "⛏️", "desc": "Maden ustası", "cost": "800 altın"},
		{"id": 4, "name": "Balıkçı", "icon": "🐟", "desc": "Deniz ustası", "cost": "600 altın"},
		{"id": 5, "name": "Demirci", "icon": "🔨", "desc": "Silah ustası", "cost": "1200 altın"},
		{"id": 6, "name": "Okçu", "icon": "🏹", "desc": "Uzaktan usta", "cost": "700 altın"},
		{"id": 7, "name": "Şifacı", "icon": "💊", "desc": "Şifa ustası", "cost": "1500 altın"},
		{"id": 8, "name": "Kaşif", "icon": "🗺️", "desc": "Keşif ustası", "cost": "900 altın"},
		{"id": 9, "name": "Şövalye", "icon": "🛡️", "desc": "Süvari birliği", "cost": "2000 altın"},
	]
	
	for prof in professions:
		var prof_btn = _create_profession_button(prof)
		vbox.add_child(prof_btn)
	
	var close_btn = Button.new()
	close_btn.text = "✖️ Kapat"
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.pressed.connect(_close_panel.bind("ProfessionPanel"))
	vbox.add_child(close_btn)

func _create_profession_button(prof: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(400, 60)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(hbox)
	
	var icon_lbl = Label.new()
	icon_lbl.text = prof["icon"]
	icon_lbl.add_theme_font_size_override("font_size", 32)
	icon_lbl.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(icon_lbl)
	
	var info_vbox = VBoxContainer.new()
	
	var name_lbl = Label.new()
	name_lbl.text = prof["name"]
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", theme_colors["text"])
	info_vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = prof["desc"] + " - " + prof["cost"]
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", theme_colors["text_secondary"])
	info_vbox.add_child(desc_lbl)
	
	hbox.add_child(info_vbox)
	
	btn.pressed.connect(_on_profession_selected.bind(prof["id"]))
	return btn

func _create_inventory_panel() -> void:
	inventory_panel = Control.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	inventory_panel.offset_right = -10
	inventory_panel.offset_top = 100
	inventory_panel.custom_minimum_size = Vector2(300, 400)
	inventory_panel.visible = false
	add_child(inventory_panel)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	bg_style.set_corner_radius_all(12)
	bg_style.border_color = theme_colors["accent"]
	bg_style.border_width_all = 2
	bg.add_theme_stylebox_override("panel", bg_style)
	inventory_panel.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "🎒 ENVANTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", theme_colors["accent"])
	vbox.add_child(title)
	
	# Örnek eşyalar
	var items = [
		{"icon": "🗡️", "name": "Demir Kılıç", "qty": 1},
		{"icon": "🛡️", "name": "Ahşap Kalkan", "qty": 1},
		{"icon": "💊", "name": "Şifa İksiri", "qty": 5},
		{"icon": "🪵", "name": "Ahşap", "qty": 20},
		{"icon": "🪨", "name": "Taş", "qty": 15},
	]
	
	for item in items:
		var item_row = _create_inventory_item(item)
		vbox.add_child(item_row)

func _create_inventory_item(item: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 40)
	
	var icon = Label.new()
	icon.text = item["icon"]
	icon.add_theme_font_size_override("font_size", 24)
	icon.custom_minimum_size = Vector2(50, 0)
	row.add_child(icon)
	
	var name = Label.new()
	name.text = item["name"]
	name.add_theme_font_size_override("font_size", 16)
	row.add_child(name)
	
	var qty = Label.new()
	qty.text = "x%d" % item["qty"]
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty.add_theme_font_size_override("font_size", 16)
	qty.add_theme_color_override("font_color", theme_colors["secondary"])
	row.add_child(qty)
	
	return row

func _create_quest_panel() -> void:
	quest_panel = Control.new()
	quest_panel.name = "QuestPanel"
	quest_panel.set_anchors_preset(Control.PRESET_CENTER)
	quest_panel.custom_minimum_size = Vector2(450, 500)
	quest_panel.visible = false
	add_child(quest_panel)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.97)
	bg_style.set_corner_radius_all(15)
	bg_style.border_color = theme_colors["success"]
	bg_style.border_width_all = 3
	bg.add_theme_stylebox_override("panel", bg_style)
	quest_panel.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "📜 GÖREVLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", theme_colors["success"])
	vbox.add_child(title)
	
	var quests = [
		{"title": "İstanbul'u Fethet", "desc": "Bizans başkentini ele geçir", "reward": "5000 altın", "progress": "0/1"},
		{"title": "Kale İnşa Et", "desc": "Yeni bir kale inşa et", "reward": "2000 altın", "progress": "0/1"},
		{"title": "Düşman Ordusunu Yen", "desc": "5000 düşman askerini yok et", "reward": "3000 altın", "progress": "0/5000"},
	]
	
	for quest in quests:
		var quest_card = _create_quest_card(quest)
		vbox.add_child(quest_card)
	
	var close_btn = Button.new()
	close_btn.text = "✖️ Kapat"
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.pressed.connect(_close_panel.bind("QuestPanel"))
	vbox.add_child(close_btn)

func _create_quest_card(quest: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 100)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.12, 0.2, 0.8)
	bg_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", bg_style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = quest["title"]
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", theme_colors["text"])
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = quest["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", theme_colors["text_secondary"])
	vbox.add_child(desc_lbl)
	
	var hbox = HBoxContainer.new()
	
	var reward_lbl = Label.new()
	reward_lbl.text = "🎁 " + quest["reward"]
	reward_lbl.add_theme_font_size_override("font_size", 14)
	reward_lbl.add_theme_color_override("font_color", theme_colors["secondary"])
	hbox.add_child(reward_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	var progress_lbl = Label.new()
	progress_lbl.text = quest["progress"]
	progress_lbl.add_theme_font_size_override("font_size", 14)
	progress_lbl.add_theme_color_override("font_color", theme_colors["success"])
	hbox.add_child(progress_lbl)
	
	vbox.add_child(hbox)
	
	return card

func _create_settings_panel() -> void:
	settings_panel = Control.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.custom_minimum_size = Vector2(400, 450)
	settings_panel.visible = false
	add_child(settings_panel)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.97)
	bg_style.set_corner_radius_all(15)
	bg_style.border_color = Color(0.5, 0.5, 0.5)
	bg_style.border_width_all = 2
	bg.add_theme_stylebox_override("panel", bg_style)
	settings_panel.add_child(bg)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚙️ AYARLAR"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title)
	
	# Grafik ayarları
	var graphics_section = _create_settings_section("🎨 Grafik", [
		{"type": "slider", "name": "Glow", "min": 0, "max": 100, "value": 80},
		{"type": "slider", "name": "Parçacıklar", "min": 0, "max": 100, "value": 70},
		{"type": "dropdown", "name": "Kalite", "options": ["Düşük", "Orta", "Yüksek", "Ultra"]},
	])
	vbox.add_child(graphics_section)
	
	# Ses ayarları
	var audio_section = _create_settings_section("🔊 Ses", [
		{"type": "slider", "name": "Ses Seviyesi", "min": 0, "max": 100, "value": 80},
		{"type": "slider", "name": "Müzik", "min": 0, "max": 100, "value": 60},
	])
	vbox.add_child(audio_section)
	
	# Kontroller
	var controls_section = _create_settings_section("🎮 Kontroller", [
		{"type": "slider", "name": "Mouse Hassasiyeti", "min": 1, "max": 100, "value": 50},
		{"type": "toggle", "name": "Titreşim"},
	])
	vbox.add_child(controls_section)
	
	var hbox = HBoxContainer.new()
	
	var resume_btn = Button.new()
	resume_btn.text = "▶️ Devam Et"
	resume_btn.custom_minimum_size = Vector2(150, 50)
	resume_btn.pressed.connect(_close_panel.bind("SettingsPanel"))
	hbox.add_child(resume_btn)
	
	var quit_btn = Button.new()
	quit_btn.text = "🚪 Çıkış"
	quit_btn.custom_minimum_size = Vector2(150, 50)
	quit_btn.pressed.connect(_on_quit_pressed)
	hbox.add_child(quit_btn)
	
	vbox.add_child(hbox)

func _create_settings_section(title: String, items: Array) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.custom_minimum_size = Vector2(350, 30 * items.size())
	
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", theme_colors["text"])
	section.add_child(title_lbl)
	
	for item in items:
		match item["type"]:
			"slider":
				var slider_row = _create_slider_row(item["name"], item["min"], item["max"], item["value"])
				section.add_child(slider_row)
			"dropdown":
				var dropdown_row = _create_dropdown_row(item["name"], item["options"])
				section.add_child(dropdown_row)
			"toggle":
				var toggle_row = _create_toggle_row(item["name"])
				section.add_child(toggle_row)
	
	return section

func _create_slider_row(name: String, min_val: int, max_val: int, default_val: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(350, 30)
	
	var lbl = Label.new()
	lbl.text = name
	lbl.custom_minimum_size = Vector2(150, 0)
	row.add_child(lbl)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(200, 0)
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = default_val
	row.add_child(slider)
	
	return row

func _create_dropdown_row(name: String, options: Array) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(350, 30)
	
	var lbl = Label.new()
	lbl.text = name
	lbl.custom_minimum_size = Vector2(150, 0)
	row.add_child(lbl)
	
	var option_btn = OptionButton.new()
	option_btn.custom_minimum_size = Vector2(150, 30)
	for opt in options:
		option_btn.add_item(opt)
	row.add_child(option_btn)
	
	return row

func _create_toggle_row(name: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(350, 30)
	
	var lbl = Label.new()
	lbl.text = name
	lbl.custom_minimum_size = Vector2(150, 0)
	row.add_child(lbl)
	
	var check = CheckButton.new()
	row.add_child(check)
	
	return row

func _create_notification_area() -> void:
	notification_area = Control.new()
	notification_area.name = "NotificationArea"
	notification_area.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	notification_area.offset_top = -100
	notification_area.custom_minimum_size = Vector2(400, 80)
	add_child(notification_area)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.08, 0.15, 0.9)
	bg_style.set_corner_radius_all(10)
	bg.add_theme_stylebox_override("panel", bg_style)
	notification_area.add_child(bg)
	
	var label = Label.new()
	label.name = "NotificationText"
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	notification_area.add_child(label)

func _create_minimap() -> void:
	var minimap = Control.new()
	minimap.name = "Minimap"
	minimap.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	minimap.offset_right = -20
	minimap.offset_top = 80
	minimap.custom_minimum_size = Vector2(150, 150)
	add_child(minimap)
	
	var bg = PanelContainer.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	bg_style.set_corner_radius_all(75)
	bg.add_theme_stylebox_override("panel", bg_style)
	minimap.add_child(bg)
	
	# Mini harita içeriği
	var map_label = Label.new()
	map_label.text = "🗺️"
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	map_label.add_theme_font_size_override("font_size", 48)
	minimap.add_child(map_label)

func _show_initial_ui() -> void:
	# Başlangıçta sadece top ve bottom bar görünür
	top_bar.visible = true
	bottom_bar.visible = true

# ── Event Handlers ──────────────────────────────────────────────

func _on_action_button_pressed(action: String) -> void:
	match action:
		"attack":
			_show_action_menu()
		"build":
			_show_build_menu()
		"recruit":
			_show_recruit_menu()
		"trade":
			_show_trade_menu()
		"profession":
			_toggle_panel("ProfessionPanel")
		"quests":
			_toggle_panel("QuestPanel")
		"inventory":
			_toggle_panel("InventoryPanel")

func _on_menu_item_pressed(item_id: String) -> void:
	action_performed.emit(item_id, {})
	action_menu.visible = false
	current_menu = ""

func _on_profession_selected(prof_id: int) -> void:
	action_performed.emit("profession_select", {"profession": prof_id})
	_close_panel("ProfessionPanel")
	show_notification("Meslek değiştirildi!")

func _on_settings_pressed() -> void:
	_toggle_panel("SettingsPanel")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_inventory_item_pressed(item_id: String) -> void:
	action_performed.emit("use_item", {"item": item_id})

# ── Helpers ─────────────────────────────────────────────────────

func _toggle_panel(panel_name: String) -> void:
	var panel = get_node_or_null(panel_name)
	if not panel:
		return
	
	if panel.visible:
		panel.visible = false
		current_menu = ""
		menu_closed.emit(panel_name)
	else:
		# Diğer panelleri kapat
		for p in ["ProfessionPanel", "QuestPanel", "SettingsPanel", "InventoryPanel"]:
			var other = get_node_or_null(p)
			if other:
				other.visible = false
		
		panel.visible = true
		current_menu = panel_name
		menu_opened.emit(panel_name)

func _close_panel(panel_name: String) -> void:
	var panel = get_node_or_null(panel_name)
	if panel:
		panel.visible = false
		current_menu = ""
		menu_closed.emit(panel_name)

func show_notification(message: String, duration: float = 3.0) -> void:
	var notif = notification_area.get_node_or_null("NotificationText")
	if notif:
		notif.text = message
		notif.add_theme_color_override("font_color", theme_colors["secondary"])
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 0.0, duration)
		tween.tween_callback(func(): notif.text = "")

func show_error(message: String) -> void:
	var notif = notification_area.get_node_or_null("NotificationText")
	if notif:
		notif.text = "❌ " + message
		notif.add_theme_color_override("font_color", theme_colors["danger"])
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 0.0, 3.0)
		tween.tween_callback(func(): notif.text = "")

func show_success(message: String) -> void:
	var notif = notification_area.get_node_or_null("NotificationText")
	if notif:
		notif.text = "✅ " + message
		notif.add_theme_color_override("font_color", theme_colors["success"])
		
		var tween = create_tween()
		tween.tween_property(notif, "modulate:a", 0.0, 2.0)
		tween.tween_callback(func(): notif.text = "")

func _show_action_menu() -> void:
	action_menu.visible = true
	current_menu = "ActionMenu"
	menu_opened.emit("ActionMenu")

func _show_build_menu() -> void:
	show_notification("İnşa menüsü açılıyor...")

func _show_recruit_menu() -> void:
	show_notification("Üretim menüsü açılıyor...")

func _show_trade_menu() -> void:
	show_notification("Ticaret menüsü açılıyor...")

func update_resources(gold: int, food: int, materials: int) -> void:
	var gold_lbl = get_node_or_null("TopBar/GoldContainer/GoldValue")
	if gold_lbl:
		gold_lbl.text = str(gold)
	
	var food_lbl = get_node_or_null("TopBar/FoodContainer/FoodValue")
	if food_lbl:
		food_lbl.text = str(food)
	
	var mats_lbl = get_node_or_null("TopBar/MaterialsContainer/MaterialsValue")
	if mats_lbl:
		mats_lbl.text = str(materials)

func update_profession(name: String, level: int) -> void:
	var prof_lbl = get_node_or_null("TopBar/ProfessionLabel")
	if prof_lbl:
		prof_lbl.text = " ⚔️ %s Lv.%d" % [name, level]

func update_turn(turn: int) -> void:
	var turn_lbl = get_node_or_null("TopBar/TurnLabel")
	if turn_lbl:
		turn_lbl.text = "Tur: %d" % turn

func show_loading_screen(message: String = "Yükleniyor...") -> void:
	loading_screen.visible = true
	var progress_lbl = loading_screen.get_node_or_null("Progress")
	if progress_lbl:
		progress_lbl.text = message

func hide_loading_screen() -> void:
	loading_screen.visible = false