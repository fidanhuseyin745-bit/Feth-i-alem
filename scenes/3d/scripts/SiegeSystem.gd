extends Node
class_name SiegeSystem

## Kuşatma sistemi - Kale fethi mekanikleri

signal siege_started(city: City, attacking_army: Army)
signal siege_progress_updated(city: City, progress: float)
signal siege_ended(city: City, victor: String, losses: Dictionary)
signal wall_breached(city: City)

const City = preload("res://scenes/3d/scripts/City.gd")
const Army = preload("res://scenes/3d/scripts/Army.gd")

# Kuşatma parametreleri
@export var breach_threshold: float = 0.8  # Sur aşmak için gereken ilerleme
@export var daily_damage_to_walls: int = 5  # Günlük sur hasarı
@export var defender_reinforcement_chance: float = 0.2
@export var food_consumption_rate: int = 10  # Günlük yiyecek tüketimi

# Aktif kuşatmalar
var active_sieges: Dictionary = {}  # city_id -> siege_data

# Kuşatma döngüsü
var siege_timer: float = 0.0
var day_duration: float = 10.0  # Saniye başına 1 gün

func _process(delta):
	siege_timer += delta
	if siege_timer >= day_duration:
		siege_timer = 0.0
		_process_siege_days()

func _process_siege_days():
	for city_id in active_sieges:
		var siege = active_sieges[city_id]
		_process_single_siege(siege)

func _process_single_siege(siege: Dictionary):
	var city: City = siege["city"]
	var attacker: Army = siege["attacker"]
	
	if not is_instance_valid(city) or not is_instance_valid(attacker):
		end_siege(city, null, false)
		return
	
	# Saldırgan yiyecek tüketimi
	siege["food_consumed"] += food_consumption_rate * attacker.units.size()
	
	# Yiyecek bitti mi kontrol et
	if siege["food_consumed"] >= siege["food_available"]:
		# Kuşatma kaldırıldı - yiyecek yok
		end_siege(city, attacker, false)
		return
	
	# Saldırı ilerlemesi
	var attack_progress = _calculate_attack_progress(attacker, city)
	siege["progress"] += attack_progress
	
	siege_progress_updated.emit(city, siege["progress"])
	
	# Sur kırıldı mı?
	if siege["progress"] >= breach_threshold and not siege["walls_breached"]:
		siege["walls_breached"] = true
		wall_breached.emit(city)
	
	# Savunma azalması
	city.defense_strength -= daily_damage_to_walls
	
	# Savunucu takviyesi
	if randf() < defender_reinforcement_chance:
		_spawn_defender_reinforcements(city)
	
	# Kale düştü mü?
	if city.defense_strength <= 0:
		_end_siege_victory(city, attacker)

func _calculate_attack_progress(attacker: Army, city: City) -> float:
	var attack_power = attacker.get_army_strength()
	var defense_power = city.defense_strength
	
	# Güç oranına göre ilerleme
	var ratio = attack_power / (attack_power + defense_power)
	
	# Bonuslar
	var siege_weapons_bonus = siege.get("has_siege_weapons", false) * 0.2
	var numbers_bonus = min(attacker.units.size() * 0.01, 0.3)
	
	return ratio * 0.1 + siege_weapons_bonus + numbers_bonus

func start_siege(city: City, attacking_army: Army):
	if city.current_state == City.CityState.BESIEGED:
		return
	
	# Kuşatma başlat
	city.start_siege(attacking_army)
	
	var siege_data = {
		"city": city,
		"attacker": attacking_army,
		"progress": 0.0,
		"walls_breached": false,
		"food_consumed": 0,
		"food_available": city.food,
		"start_time": Time.get_unix_time_from_system(),
		"days": 0
	}
	
	active_sieges[city.name] = siege_data
	siege_started.emit(city, attacking_army)
	
	# Saldırgan ordusunu şehir önüne konumlandır
	var siege_position = _calculate_siege_position(city, attacking_army)
	attacking_army.move_to(siege_position)

func _calculate_siege_position(city: City, attacker: Army) -> Vector3:
	var base_pos = city.global_position
	var direction = Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	
	# Şehir etrafında çember pozisyonu
	var distance = 15.0  # Kale duvarından uzaklık
	return base_pos + direction * distance

func end_siege(city: City, attacker: Army, victory: bool):
	if not active_sieges.has(city.name):
		return
	
	var siege = active_sieges[city.name]
	active_sieges.erase(city.name)
	
	if victory and attacker:
		city.capture_city(attacker.team)
		var losses = _calculate_siege_losses(siege)
		siege_ended.emit(city, attacker.team, losses)
	else:
		city.end_siege(false)
		siege_ended.emit(city, city.owner, {})

func _end_siege_victory(city: City, attacker: Army):
	var losses = _calculate_siege_losses(active_sieges.get(city.name, {}))
	city.capture_city(attacker.team)
	siege_ended.emit(city, attacker.team, losses)
	
	if active_sieges.has(city.name):
		active_sieges.erase(city.name)

func _calculate_siege_losses(siege: Dictionary) -> Dictionary:
	var losses = {
		"attacker_dead": 0,
		"attacker_wounded": 0,
		"defender_dead": 0,
		"walls_destroyed": siege.get("walls_breached", false)
	}
	
	if siege.has("attacker"):
		var attacker: Army = siege["attacker"]
		var total_units = attacker.units.size()
		losses["attacker_dead"] = int(total_units * siege["progress"] * 0.3)
	
	return losses

func _spawn_defender_reinforcements(city: City):
	# Şehir içinde rastgele takviye
	var reinforcements = City.new()
	reinforcements.name = "temp"
	add_child(reinforcements)
	
	var unit = Unit.new()
	unit.unit_name = "Savunucu"
	unit.unit_type = Unit.UnitType.INFANTRY
	unit.health = 80
	unit.damage = 12
	unit.team = city.owner
	
	city.add_child(unit)

func add_siege_weapons(city_id: String):
	if active_sieges.has(city_id):
		active_sieges[city_id]["has_siege_weapons"] = true

func add_supplies(city_id: String, amount: int):
	if active_sieges.has(city_id):
		active_sieges[city_id]["food_available"] += amount

func get_siege_progress(city_id: String) -> float:
	if active_sieges.has(city_id):
		return active_sieges[city_id]["progress"]
	return 0.0

func is_city_under_siege(city_id: String) -> bool:
	return active_sieges.has(city_id)

func get_siege_days(city_id: String) -> int:
	if active_sieges.has(city_id):
		return active_sieges[city_id]["days"]
	return 0