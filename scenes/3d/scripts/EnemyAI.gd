extends Node
class_name EnemyAI

## Düşman yapay zeka sistemi

signal ai_decision_made(faction: String, action: String, target)
signal ai_attack_launched(faction: String, target_city: String)
signal ai_unit_spawned(faction: String, unit_type: String)

const City = preload("res://scenes/3d/scripts/City.gd")
const Unit = preload("res://scenes/3d/scripts/Unit.gd")

# AI profilleri - her fraksiyonun kendine özgü davranışı
var ai_profiles: Dictionary = {
	"byzantine": {
		"aggression": 0.6,
		"defense_priority": 0.8,
		"economic_priority": 0.5,
		"target_faction": "ottoman"
	},
	"karamanid": {
		"aggression": 0.7,
		"defense_priority": 0.5,
		"economic_priority": 0.4,
		"target_faction": "ottoman"
	},
	"albania": {
		"aggression": 0.4,
		"defense_priority": 0.9,
		"economic_priority": 0.6,
		"target_faction": "ottoman"
	},
	"venice": {
		"aggression": 0.5,
		"defense_priority": 0.6,
		"economic_priority": 0.8,
		"target_faction": "ottoman"
	},
	"akkoyunlu": {
		"aggression": 0.8,
		"defense_priority": 0.4,
		"economic_priority": 0.3,
		"target_faction": "ottoman"
	}
}

# AI kaynakları
var ai_gold: Dictionary = {
	"byzantine": 1000,
	"karamanid": 800,
	"albania": 600,
	"venice": 1200,
	"akkoyunlu": 900
}

# Referanslar
var cities: Dictionary = {}
var world_map: Node = null

func _ready():
	# AI gold başlangıç
	for faction in ai_gold:
		ai_gold[faction] = randi() % 500 + 500

func setup(world_map_ref: Node):
	world_map = world_map_ref
	cities = world_map.cities

func _process(delta):
	# AI kararları - her 5 saniyede bir
	pass

func simulate_faction_turn(faction: String):
	if not ai_profiles.has(faction):
		return
	
	var profile = ai_profiles[faction]
	
	# 1. Ekonomik kararlar - birim üretimi
	_simulate_economic_decisions(faction, profile)
	
	# 2. Savunma kararları - şehir takviyesi
	_simulate_defense_decisions(faction, profile)
	
	# 3. Saldırı kararları - Osmanlı'ya karşı
	_simulate_attack_decisions(faction, profile)

func _simulate_economic_decisions(faction: String, profile: Dictionary):
	var gold = ai_gold[faction]
	var faction_cities = _get_faction_cities(faction)
	
	if gold >= 200 and randf() < profile["economic_priority"]:
		# Birim üret
		var unit_type = _choose_unit_type(profile)
		var cost = _get_unit_cost(unit_type)
		
		if gold >= cost and faction_cities.size() > 0:
			var city = faction_cities[randi() % faction_cities.size()]
			if city.gold >= cost:
				city.gold -= cost
				_spawn_ai_unit(city, unit_type, faction)
				ai_gold[faction] -= cost
				ai_unit_spawned.emit(faction, unit_type)

func _simulate_defense_decisions(faction: String, profile: Dictionary):
	var faction_cities = _get_faction_cities(faction)
	
	for city in faction_cities:
		# Kritik şehirleri takviye et
		if city.defense_strength < city.max_defense * 0.5:
			if randf() < profile["defense_priority"]:
				city.defense_strength += 20
				city.defense_strength = min(city.defense_strength, city.max_defense)

func _simulate_attack_decisions(faction: String, profile: Dictionary):
	if randf() > profile["aggression"]:
		return  # Saldırı eşiği geçilmedi
	
	var faction_cities = _get_faction_cities(faction)
	if faction_cities.size() == 0:
		return
	
	# Güçlü bir şehri saldırıya hazırla
	var aggressive_city = _find_aggressive_city(faction_cities)
	if not aggressive_city:
		return
	
	# Hedef - Osmanlı şehri
	var target_city = _find_nearest_ottoman_city(aggressive_city)
	if target_city and _calculate_city_strength(aggressive_city) > target_city.defense_strength * 0.8:
		# Saldırı başlat
		_launch_attack(aggressive_city, target_city, faction)

func _launch_attack(source_city: City, target_city: City, faction: String):
	ai_attack_launched.emit(faction, target_city.name)
	
	# Şehir kuşatması
	target_city.start_siege(null)
	
	# Saldırı mesajı
	if world_map:
		_show_ai_message(faction, "%s saldırdı!" % target_city.city_name)

func _find_aggressive_city(cities: Array) -> City:
	var strongest: City = null
	var max_strength = 0
	
	for city in cities:
		var strength = _calculate_city_strength(city)
		if strength > max_strength:
			max_strength = strength
			strongest = city
	
	return strongest

func _calculate_city_strength(city: City) -> float:
	var strength = city.defense_strength
	
	# Binalar bonus
	for building in city.buildings:
		if building == "kale":
			strength += 50
		elif building == "sur":
			strength += 30
	
	# Nüfus bonus
	strength += city.population * 0.1
	
	return strength

func _find_nearest_ottoman_city(from: City) -> City:
	var nearest: City = null
	var min_distance = INF
	
	if not world_map:
		return null
	
	for city_id in world_map.cities:
		var city = world_map.cities[city_id]
		if city.owner == "ottoman":
			var distance = from.global_position.distance_to(city.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = city
	
	return nearest

func _get_faction_cities(faction: String) -> Array[City]:
	var faction_cities: Array[City] = []
	
	if world_map and world_map.cities:
		for city_id in world_map.cities:
			if world_map.cities[city_id].owner == faction:
				faction_cities.append(world_map.cities[city_id])
	
	return faction_cities

func _choose_unit_type(profile: Dictionary) -> String:
	var roll = randf()
	
	if roll < 0.5:
		return "piyade"
	elif roll < 0.8:
		return "okçu"
	else:
		return "süvari"

func _get_unit_cost(unit_type: String) -> int:
	match unit_type:
		"piyade": return 50
		"süvari": return 80
		"okçu": return 60
		_: return 50

func _spawn_ai_unit(city: City, unit_type: String, faction: String):
	var unit = Unit.new()
	unit.unit_type = _get_unit_type_enum(unit_type)
	unit.team = faction
	unit.unit_name = "AI %s" % unit_type
	
	match unit_type:
		"piyade":
			unit.health = 80
			unit.damage = 12
		"süvari":
			unit.health = 100
			unit.damage = 18
			unit.speed = 6.0
		"okçu":
			unit.health = 60
			unit.damage = 15
			unit.attack_range = 10.0
	
	unit.global_position = city.global_position + Vector3(randf() * 10 - 5, 0, randf() * 10 - 5)
	
	if world_map and world_map.get_node("Units"):
		world_map.get_node("Units").add_child(unit)

func _get_unit_type_enum(type: String) -> int:
	match type:
		"piyade": return Unit.UnitType.INFANTRY
		"süvari": return Unit.UnitType.CAVALRY
		"okçu": return Unit.UnitType.ARCHER
		_: return Unit.UnitType.INFANTRY

func _show_ai_message(faction: String, message: String):
	var faction_names = {
		"byzantine": "Bizans",
		"karamanid": "Karamanoğlu",
		"albania": "Arnavutluk",
		"venice": "Venedik",
		"akkoyunlu": "Akkoyunlu"
	}
	
	if world_map:
		var label = world_map.get_node_or_null("GameHUD/MessageLabel")
		if label:
			label.text = "[%s] %s" % [faction_names.get(faction, faction), message]
			label.modulate = Color(1, 0.3, 0.3)

func collect_faction_income(faction: String):
	var income = 0
	for city in _get_faction_cities(faction):
		income += city.income_per_turn
	
	ai_gold[faction] += income

func get_faction_gold(faction: String) -> int:
	return ai_gold.get(faction, 0)