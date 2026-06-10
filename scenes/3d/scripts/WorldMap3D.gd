extends Node3D
class_name WorldMap3D

## Ana harita sahne yöneticisi - 3D Açık Dünya

signal turn_changed(turn: int)
signal resource_updated(gold: int, food: int, materials: int)
signal city_captured(city: City, new_owner: String)
signal message_shown(msg: String)

const Unit = preload("res://scenes/3d/scripts/Unit.gd")
const Army = preload("res://scenes/3d/scripts/Army.gd")
const City = preload("res://scenes/3d/scripts/City.gd")
const EnemyAI = preload("res://scenes/3d/scripts/EnemyAI.gd")
const SiegeSystem = preload("res://scenes/3d/scripts/SiegeSystem.gd")
const InteriorSystem = preload("res://scenes/3d/scripts/InteriorSystem.gd")

# Oyun durumu
var turn: int = 1
var gold: int = 5000
var food: int = 1000
var materials: int = 500
var game_paused: bool = false

# Kaynaklar
var income_per_turn: int = 0
var unit_upkeep: int = 0

# Referanslar
@onready var camera: RTSCamera = $RTSCamera
@onready var unit_selection: UnitSelection = $UnitSelection
@onready var ground: StaticBody3D = $Ground
@onready var cities_container: Node3D = $Cities
@onready var units_container: Node3D = $Units
@onready var siege_system: SiegeSystem = $SiegeSystem
@onready var interior_system: InteriorSystem = $InteriorSystem

# Sistemler
var enemy_ai: EnemyAI = null

# Şehirler
var cities: Dictionary = {}
var player_cities: Array[City] = []
var enemy_cities: Array[City] = []

# Birimler
var player_units: Array[Unit] = []

# Harita boyutları
var map_size: Vector3 = Vector3(500, 0, 500)

# Seçili şehir
var selected_city: City = null

func _ready():
	_setup_world()
	_setup_cities()
	_spawn_initial_units()
	_setup_ai()
	_setup_ui()
	_calculate_income()
	
	# Sinyal bağlantıları
	unit_selection.selection_changed.connect(_on_selection_changed)

func _setup_world():
	# Zemin ayarları
	if ground:
		var mesh_instance = ground.get_node_or_null("MeshInstance3D") as MeshInstance3D
		if mesh_instance:
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.35, 0.55, 0.25)
			material.uv1_scale = Vector3(50, 50, 50)
			mesh_instance.material = material
	
	# Işık ayarları
	var sun_light = DirectionalLight3D.new()
	sun_light.rotation_degrees = Vector3(-45, 30, 0)
	sun_light.light_energy = 1.0
	sun_light.shadow_enabled = true
	add_child(sun_light)
	
	# Ortam ışığı
	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6, 0.7, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	ambient.environment = env
	add_child(ambient)

func _setup_cities():
	_create_city("istanbul", Vector3(0, 0, 0), City.CityType.CITY, "byzantine")
	_create_city("edirne", Vector3(-80, 0, -30), City.CityType.CITY, "ottoman")
	_create_city("bursa", Vector3(50, 0, 60), City.CityType.TOWN, "ottoman")
	_create_city("selanik", Vector3(-60, 0, 50), City.CityType.TOWN, "ottoman")
	_create_city("karaman", Vector3(100, 0, 80), City.CityType.TOWN, "karamanid")
	_create_city("arnavutluk", Vector3(-120, 0, 30), City.CityType.FORTRESS, "albania")
	_create_city("venedik_adalar", Vector3(-40, 0, -80), City.CityType.VILLAGE, "venice")
	_create_city("akkoyunlu", Vector3(180, 0, 40), City.CityType.TOWN, "akkoyunlu")

func _create_city(city_id: String, pos: Vector3, city_type: int, owner: String):
	var city = City.new()
	city.city_name = _get_city_name(city_id)
	city.city_type = city_type
	city.owner = owner
	city.global_position = pos
	city.name = city_id
	
	cities_container.add_child(city)
	cities[city_id] = city
	
	if owner == "ottoman":
		player_cities.append(city)
	else:
		enemy_cities.append(city)
	
	city.city_captured.connect(_on_city_captured)
	_create_city_visual(city)

func _get_city_name(city_id: String) -> String:
	var names = {
		"istanbul": "İstanbul",
		"edirne": "Edirne",
		"bursa": "Bursa",
		"selanik": "Selanik",
		"karaman": "Karaman",
		"arnavutluk": "Arnavutluk Kalesi",
		"venedik_adalar": "Ege Adaları",
		"akkoyunlu": "Akkoyunlu"
	}
	return names.get(city_id, city_id)

func _create_city_visual(city: City):
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	
	match city.city_type:
		City.CityType.VILLAGE:
			box_mesh.size = Vector3(6, 3, 6)
		City.CityType.TOWN:
			box_mesh.size = Vector3(10, 5, 10)
		City.CityType.CITY:
			box_mesh.size = Vector3(15, 8, 15)
		City.CityType.FORTRESS:
			box_mesh.size = Vector3(12, 10, 12)
	
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = _get_faction_color(city.owner)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material = material
	mesh_instance.position = Vector3(0, box_mesh.size.y / 2, 0)
	city.add_child(mesh_instance)
	
	# Bayrak direği
	var flag = MeshInstance3D.new()
	var flag_mesh = CylinderMesh.new()
	flag_mesh.top_radius = 0.1
	flag_mesh.bottom_radius = 0.1
	flag_mesh.height = 8
	flag.mesh = flag_mesh
	flag.position = Vector3(0, box_mesh.size.y, 0)
	city.add_child(flag)
	
	# İsim etiketi
	var label = Label3D.new()
	label.text = city.city_name
	label.font_size = 32
	label.position = Vector3(0, box_mesh.size.y + 4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	label.outline_size = 8
	label.outline_modulate = Color(0.2, 0.2, 0.2, 1)
	city.add_child(label)

func _get_faction_color(faction: String) -> Color:
	match faction:
		"ottoman": return Color(0.9, 0.7, 0.1)
		"byzantine": return Color(0.3, 0.5, 0.9)
		"karamanid": return Color(0.2, 0.7, 0.4)
		"albania": return Color(0.85, 0.2, 0.2)
		"venice": return Color(0.6, 0.3, 0.8)
		"akkoyunlu": return Color(0.9, 0.5, 0.1)
		_: return Color(0.5, 0.5, 0.5)

func _spawn_initial_units():
	var start_pos = cities["edirne"].global_position
	
	# Piyade
	for i in 5:
		var unit = _create_unit("piyade", start_pos + Vector3(randf() * 4 - 2, 0, randf() * 4 - 2))
		player_units.append(unit)
	
	# Süvari
	for i in 3:
		var unit = _create_unit("süvari", start_pos + Vector3(randf() * 6 - 3, 0, randf() * 6 - 3))
		player_units.append(unit)
	
	# Okçu
	for i in 2:
		var unit = _create_unit("okçu", start_pos + Vector3(randf() * 6 - 3, 0, randf() * 6 - 3))
		player_units.append(unit)

func _create_unit(unit_type: String, pos: Vector3) -> Unit:
	var unit = Unit.new()
	unit.global_position = pos
	unit.team = "player"
	
	match unit_type:
		"piyade":
			unit.unit_name = "Piyade"
			unit.unit_type = Unit.UnitType.INFANTRY
			unit.health = 100
			unit.damage = 15
			unit.defense = 8
			unit.speed = 4.0
		"süvari":
			unit.unit_name = "Süvari"
			unit.unit_type = Unit.UnitType.CAVALRY
			unit.health = 120
			unit.damage = 20
			unit.defense = 5
			unit.speed = 7.0
		"okçu":
			unit.unit_name = "Okçu"
			unit.unit_type = Unit.UnitType.ARCHER
			unit.health = 70
			unit.damage = 18
			unit.defense = 3
			unit.speed = 4.0
			unit.attack_range = 8.0
	
	units_container.add_child(unit)
	unit_selection.register_unit(unit)
	unit.unit_died.connect(_on_unit_died)
	
	return unit

func _setup_ai():
	enemy_ai = EnemyAI.new()
	add_child(enemy_ai)
	enemy_ai.setup(self)

func _setup_ui():
	var hud = $GameHUD
	if hud:
		hud.end_turn_btn.pressed.connect(_on_end_turn_pressed)
		hud.attack_btn.pressed.connect(_on_attack_pressed)
		hud.build_btn.pressed.connect(_on_build_pressed)
		hud.recruit_btn.pressed.connect(_on_recruit_pressed)
		
		if hud.get_node_or_null("CityInfo/EnterCityBtn"):
			hud.get_node("CityInfo/EnterCityBtn").pressed.connect(_on_enter_city_pressed)

func _on_selection_changed(selected: Array[Unit]):
	var hud = $GameHUD
	if hud:
		hud.update_selection(selected.size(), _get_selection_info(selected))

func _get_selection_info(selected: Array[Unit]) -> String:
	if selected.size() == 0:
		return ""
	
	var types = {"piyade": 0, "süvari": 0, "okçu": 0}
	for unit in selected:
		match unit.unit_type:
			Unit.UnitType.INFANTRY: types["piyade"] += 1
			Unit.UnitType.CAVALRY: types["süvari"] += 1
			Unit.UnitType.ARCHER: types["okçu"] += 1
	
	return "🗡 %d  🐴 %d  🏹 %d" % [types["piyade"], types["süvari"], types["okçu"]]

func _calculate_income():
	income_per_turn = 0
	for city in player_cities:
		income_per_turn += city.income_per_turn
	
	unit_upkeep = player_units.size() * 5
	_update_hud()

func _update_hud():
	var hud = $GameHUD
	if hud:
		hud.update_resources(gold, food, materials)
		hud.update_turn(turn)

func _process(delta):
	# Şehir kuşatmaları
	for city in cities.values():
		if city.current_state == City.CityState.BESIEGED:
			city._process_siege()

# ── Tur Sistemi ────────────────────────────────────────────────────────────

func _on_end_turn_pressed():
	end_turn()

func end_turn():
	turn += 1
	
	var income = income_per_turn - unit_upkeep
	gold += income
	
	# Yiyecek tüketimi
	food -= player_units.size() * 2
	if food < 0:
		food = 0
	
	# AI turu
	if enemy_ai:
		for faction in ["byzantine", "karamanid", "albania", "venice", "akkoyunlu"]:
			enemy_ai.simulate_faction_turn(faction)
			enemy_ai.collect_faction_income(faction)
	
	turn_changed.emit(turn)
	resource_updated.emit(gold, food, materials)
	_calculate_income()
	
	_show_message("Tur %d - Gelir: %d Altın" % [turn, income])

# ── Eylemler ───────────────────────────────────────────────────────────────

func _on_attack_pressed():
	if selected_city and selected_city.owner != "ottoman":
		attack_city(selected_city.name)
	else:
		_show_message("Saldırmak için bir şehir seçin!")

func _on_build_pressed():
	if selected_city and selected_city.owner == "ottoman":
		_show_build_menu(selected_city)
	else:
		_show_message("İnşa etmek için kendi şehrinizi seçin!")

func _on_recruit_pressed():
	if selected_city and selected_city.owner == "ottoman":
		_show_recruit_menu(selected_city)
	else:
		_show_message("Üretim için bir şehir seçin!")

func _on_enter_city_pressed():
	if selected_city:
		if selected_city.owner == "ottoman":
			_show_message("Kendi şehrinize giremezsiniz!")
		elif selected_city.current_state == City.CityState.BESIEGED:
			interior_system.enter_city(selected_city)
			_show_message("%s içine giriliyor..." % selected_city.city_name)
		else:
			_show_message("Önce şehri kuşatmanız gerekiyor!")

func attack_city(city_id: String):
	if not cities.has(city_id):
		return
	
	var city = cities[city_id]
	var selected = unit_selection.get_selected_army()
	
	if selected.size() == 0:
		_show_message("Saldırmak için birim seçin!")
		return
	
	# Birimleri şehir önüne hareket ettir
	var attack_pos = city.global_position + Vector3(randf() * 10 - 5, 0, randf() * 10 - 5)
	
	for unit in selected:
		if unit.current_state != Unit.UnitState.DEAD:
			unit.set_target_position(attack_pos)
	
	# Kuşatma başlat
	siege_system.start_siege(city, null)
	city.start_siege(null)
	
	_show_message("%s kuşatıldı!" % city.city_name)

func _show_build_menu(city: City):
	var message = "İnşa Et:\n\n"
	for building in city.available_buildings:
		var cost = building["cost"]
		var can_build = city.can_build(building["id"]) or building["id"] in city.buildings
		var status = "✓" if building["id"] in city.buildings else ("(%d altın)" % cost if can_build else "(Yetersiz altın)")
		message += "%s %s\n" % [building["name"], status]
	
	_show_message(message)

func _show_recruit_menu(city: City):
	_show_message("""Birim Üret:
🗡 Piyade - 50 altın
🐴 Süvari - 80 altın  
🏹 Okçu - 60 altın""")

func select_city(city: City):
	selected_city = city
	var hud = $GameHUD
	if hud:
		hud.update_city_info(city)
		hud.show_city_panel(true)

func _show_city_panel(show: bool):
	var hud = $GameHUD
	if hud and hud.get_node_or_null("CityInfo"):
		hud.get_node("CityInfo").visible = show

func _show_message(msg: String):
	var hud = $GameHUD
	if hud and hud.get_node_or_null("MessageLabel"):
		hud.get_node("MessageLabel").text = msg
		hud.get_node("MessageLabel").modulate = Color(1, 0.9, 0.2)
	message_shown.emit(msg)
	
	# 3 saniye sonra temizle
	await get_tree().create_timer(3.0).timeout
	if hud and hud.get_node_or_null("MessageLabel"):
		hud.get_node("MessageLabel").text = ""

func _on_city_captured(city: City, new_owner: String):
	if new_owner == "ottoman":
		_show_message("☪️ %s fethedildi!" % city.city_name)
		
		# İstanbul fethedildi mi kontrol et
		if city.name == "istanbul":
			_show_victory()
	else:
		_show_message("⚠️ %s kaybedildi!" % city.city_name)
	
	# Şehir listesini güncelle
	_update_cities_lists()

func _on_unit_died(unit: Unit):
	player_units.erase(unit)

func _update_cities_lists():
	player_cities.clear()
	enemy_cities.clear()
	
	for city_id in cities:
		var city = cities[city_id]
		if city.owner == "ottoman":
			player_cities.append(city)
		else:
			enemy_cities.append(city)

func _show_victory():
	_show_message("☪️ ZAFER! İSTANBUL FETHEDİLDİ! ☪️")
	game_paused = true

# ── Kayıt / Yükleme ────────────────────────────────────────────────────────

func get_save_data() -> Dictionary:
	return {
		"turn": turn,
		"gold": gold,
		"food": food,
		"materials": materials,
		"cities": _get_cities_save_data(),
		"units": _get_units_save_data()
	}

func _get_cities_save_data() -> Dictionary:
	var data = {}
	for city_id in cities:
		var city = cities[city_id]
		data[city_id] = {
			"owner": city.owner,
			"gold": city.gold,
			"defense_strength": city.defense_strength,
			"buildings": city.buildings
		}
	return data

func _get_units_save_data() -> Array:
	var data = []
	for unit in player_units:
		data.append(unit.get_save_data())
	return data

func load_save_data(data: Dictionary):
	turn = data.get("turn", 1)
	gold = data.get("gold", 5000)
	food = data.get("food", 1000)
	materials = data.get("materials", 500)
	
	var cities_data = data.get("cities", {})
	for city_id in cities_data:
		if cities.has(city_id):
			var city_data = cities_data[city_id]
			cities[city_id].owner = city_data.get("owner", "ottoman")
			cities[city_id].gold = city_data.get("gold", 0)
			cities[city_id].defense_strength = city_data.get("defense_strength", 100)
			cities[city_id].buildings = city_data.get("buildings", [])
	
	_update_cities_lists()
	_calculate_income()