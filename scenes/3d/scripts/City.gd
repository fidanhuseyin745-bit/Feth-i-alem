extends Node3D
class_name City

## Şehir ve Kale sistemi - Şehir yönetimi, savunma ve fetih

signal city_captured(city: City, new_owner: String)
signal city_under_attack(city: City, attacker: Army)
signal garrison_updated(city: City)
signal building_constructed(city: City, building: String)

enum CityType { VILLAGE, TOWN, CITY, FORTRESS }
enum CityState { PEACEFUL, BESIEGED, CAPTURED }

@export var city_name: String = "Şehir"
@export var city_type: CityType = CityType.TOWN
@export var owner: String = "ottoman"
@export var current_state: CityState = CityState.PEACEFUL

# Şehir özellikleri
@export var population: int = 1000
@export var income_per_turn: int = 100
@export var defense_strength: int = 100
@export var max_defense: int = 200
@export var walls_level: int = 1

# Kaynaklar
@export var gold: int = 500
@export var food: int = 1000
@export var materials: int = 500

# Binalar
var buildings: Array[String] = ["kale"]
var available_buildings: Array = [
	{"id": "kale", "name": "Kale", "cost": 300, "defense_bonus": 20},
	{"id": "kışla", "name": "Kışla", "cost": 500, "spawn_unit": "piyade"},
	{"id": "ahır", "name": "Ahır", "cost": 400, "spawn_unit": "süvari"},
	{"id": "okçuluk", "name": "Okçuluk Salonu", "cost": 350, "spawn_unit": "okçu"},
	{"id": "depo", "name": "Depo", "cost": 200, "storage_bonus": 100},
	{"id": " değirmen", "name": "Değirmen", "cost": 150, "income_bonus": 20},
	{"id": "kervansaray", "name": "Kervansaray", "cost": 400, "income_bonus": 50},
	{"id": "sur", "name": "Güçlendirilmiş Sur", "cost": 600, "defense_bonus": 40},
]

# Mevcut kuşatma
var besieging_army: Army = null
var siege_turns: int = 0

# Referanslar
@onready var city_mesh: MeshInstance3D
@onready var walls_mesh: MeshInstance3D
@onready var flag_mesh: MeshInstance3D

func _ready():
	_setup_city()
	_update_visual()

func _setup_city():
	# Şehir tipine göre değerleri ayarla
	match city_type:
		CityType.VILLAGE:
			population = 500
			income_per_turn = 50
			defense_strength = 50
			max_defense = 100
		CityType.TOWN:
			population = 1000
			income_per_turn = 100
			defense_strength = 100
			max_defense = 200
		CityType.CITY:
			population = 3000
			income_per_turn = 200
			defense_strength = 200
			max_defense = 400
		CityType.FORTRESS:
			population = 500
			income_per_turn = 80
			defense_strength = 400
			max_defense = 800
			walls_level = 3

func _update_visual():
	# Şehir sahip rengini güncelle
	if flag_mesh:
		var owner_color = _get_faction_color(owner)
		flag_mesh.get_surface_material(0).albedo_color = owner_color

func _get_faction_color(faction: String) -> Color:
	match faction:
		"ottoman": return Color(0.9, 0.7, 0.1)
		"byzantine": return Color(0.3, 0.5, 0.9)
		"karamanid": return Color(0.2, 0.7, 0.4)
		"albania": return Color(0.85, 0.2, 0.2)
		"venice": return Color(0.6, 0.3, 0.8)
		"akkoyunlu": return Color(0.9, 0.5, 0.1)
		_: return Color(0.5, 0.5, 0.5)

# ── Savunma ve Saldırı ─────────────────────────────────────────────────────

func start_siege(attacker: Army):
	besieging_army = attacker
	current_state = CityState.BESIEGED
	siege_turns = 0
	city_under_attack.emit(self, attacker)

func end_siege(victory: bool):
	if victory:
		# Kuşatan kazandı - şehir el değiştirir
		if besieging_army:
			capture_city(besieging_army.team)
	else:
		# Kuşatma kaldırıldı
		besieging_army = null
		current_state = CityState.PEACEFUL

func capture_city(new_owner: String):
	var old_owner = owner
	owner = new_owner
	defense_strength = max_defense / 2  # Yarısına düşer
	besieging_army = null
	current_state = CityState.PEACEFUL
	
	_update_visual()
	city_captured.emit(self, new_owner)

func take_damage(amount: int):
	defense_strength -= amount
	if defense_strength <= 0:
		defense_strength = 0
		# Kale düştü
		if besieging_army:
			capture_city(besieging_army.team)
	else:
		# Hasar verildi mesajı
		pass

func repair_walls(cost: int) -> bool:
	if gold >= cost and walls_level < 5:
		gold -= cost
		walls_level += 1
		max_defense += 50
		defense_strength = min(defense_strength + 30, max_defense)
		return true
	return false

# ── Bina Yönetimi ─────────────────────────────────────────────────────────

func can_build(building_id: String) -> bool:
	if building_id in buildings:
		return false
	
	var building_data = _get_building_data(building_id)
	if not building_data:
		return false
	
	return gold >= building_data["cost"]

func build_building(building_id: String) -> bool:
	if not can_build(building_id):
		return false
	
	var building_data = _get_building_data(building_id)
	gold -= building_data["cost"]
	buildings.append(building_id)
	
	# Bina etkilerini uygula
	_apply_building_effects(building_data)
	
	building_constructed.emit(self, building_id)
	return true

func _get_building_data(building_id: String) -> Dictionary:
	for building in available_buildings:
		if building["id"] == building_id:
			return building
	return {}

func _apply_building_effects(building_data: Dictionary):
	if building_data.has("defense_bonus"):
		max_defense += building_data["defense_bonus"]
		defense_strength += building_data["defense_bonus"] / 2
	if building_data.has("income_bonus"):
		income_per_turn += building_data["income_bonus"]
	if building_data.has("spawn_unit"):
		# Birim üretimi için hazırlık
		pass

# ── Birim Üretimi ─────────────────────────────────────────────────────────

func can_spawn_unit(unit_type: String, cost: int) -> bool:
	return gold >= cost

func spawn_unit(unit_type: String, cost: int) -> Unit:
	if not can_spawn_unit(unit_type, cost):
		return null
	
	gold -= cost
	
	var new_unit = _create_unit(unit_type)
	add_child(new_unit)
	new_unit.global_position = global_position + Vector3(randf() * 4 - 2, 0, randf() * 4 - 2)
	
	return new_unit

func _create_unit(unit_type: String) -> Unit:
	var unit = preload("res://scenes/3d/scripts/Unit.gd").new()
	unit.team = owner
	
	match unit_type:
		"piyade":
			unit.unit_name = "Piyade"
			unit.unit_type = Unit.UnitType.INFANTRY
			unit.health = 100
			unit.damage = 15
			unit.defense = 8
			unit.cost = 50
		"süvari":
			unit.unit_name = "Süvari"
			unit.unit_type = Unit.UnitType.CAVALRY
			unit.health = 120
			unit.damage = 20
			unit.defense = 5
			unit.speed = 7.0
			unit.cost = 80
		"okçu":
			unit.unit_name = "Okçu"
			unit.unit_type = Unit.UnitType.ARCHER
			unit.health = 70
			unit.damage = 18
			unit.defense = 3
			unit.attack_range = 8.0
			unit.cost = 60
	
	return unit

# ── Kaynak Yönetimi ────────────────────────────────────────────────────────

func collect_income():
	gold += income_per_turn
	return income_per_turn

func add_gold(amount: int):
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

# ── Kuşatma Döngüsü ────────────────────────────────────────────────────────

func _process_siege():
	if current_state == CityState.BESIEGED and besieging_army:
		siege_turns += 1
		
		# Her tur savunma azalır
		var siege_damage = 10 + (siege_turns * 2)
		defense_strength -= siege_damage
		
		# Yiyecek tükenirse savunma daha hızlı düşer
		if food <= 0:
			defense_strength -= 5
		
		if defense_strength <= 0:
			capture_city(besieging_army.team)

# ── UI için bilgiler ───────────────────────────────────────────────────────

func get_info_text() -> String:
	var state_text = ""
	match current_state:
		CityState.PEACEFUL: state_text = "Huzurlu"
		CityState.BESIEGED: state_text = "Kuşatma altında!"
		CityState.CAPTURED: state_text = "Fethedildi!"
	
	return """%s
Tür: %s
Sahip: %s
Nüfus: %d
Savunma: %d/%d
Gelir: %d/turn
Binalar: %s
Altın: %d
Yiyecek: %d""" % [
		city_name,
		_get_city_type_name(),
		owner.to_upper(),
		population,
		defense_strength,
		max_defense,
		income_per_turn,
		buildings.join(", "),
		gold,
		food
	]

func _get_city_type_name() -> String:
	match city_type:
		CityType.VILLAGE: return "Köy"
		CityType.TOWN: return "Kasaba"
		CityType.CITY: return "Şehir"
		CityType.FORTRESS: return "Kale"
		_: return "Bilinmiyor"