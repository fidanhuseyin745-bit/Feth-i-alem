extends Node3D
class_name WorldMap3D

## Dünya Haritası Yöneticisi - 3D Açık Dünya Sistemi

signal city_selected(city_id: int)
signal region_captured(region_id: int)

@export var map_size: Vector3 = Vector3(800, 0, 800)
@export var city_count: int = 30

var cities: Array = []
var regions: Dictionary = {}
var current_player_faction: int = 0

func _ready():
	_generate_world()
	_setup_regions()

func _generate_world():
	print("Dünya haritası oluşturuluyor...")
	# Şehirleri oluştur
	for i in range(city_count):
		var city_data = {
			"id": i,
			"name": _get_city_name(i),
			"position": _get_random_position(),
			"faction": randi() % 4,
			"population": randi() % 10000 + 1000,
			"prosperity": randf(),
			"is_capital": i == 0 or i == 15 or i == 28
		}
		cities.append(city_data)
	
	print("Toplam " + str(cities.size()) + " şehir oluşturuldu")

func _setup_regions():
	# Bölgeleri ayarla
	regions = {
		0: {"name": "Anadolu", "cities": []},
		1: {"name": "Balkanlar", "cities": []},
		2: {"name": "Arabistan", "cities": []},
		3: {"name": "Kafkasya", "cities": []}
	}

func _get_city_name(index: int) -> String:
	var names = [
		"İstanbul", "Edirne", "Bursa", "Samsun", "Trabzon",
		"Erzurum", "Diyarbakır", "Mosul", "Halep", "Şam",
		"Kudüs", "Kahire", "Belgrat", "Budapeşte", "Viyana",
		"Roma", "Venedik", "Floransa", "Milano", "Napoli",
		"Atina", "Selanik", "Sofya", "Bükreş", "Karaosman"
	]
	if index < names.size():
		return names[index]
	return "Şehir " + str(index)

func _get_random_position() -> Vector3:
	return Vector3(
		randf() * map_size.x - map_size.x/2,
		0,
		randf() * map_size.z - map_size.z/2
	)

func select_city(city_id: int):
	if city_id < cities.size():
		emit_signal("city_selected", city_id)
		print("Şehir seçildi: " + cities[city_id]["name"])

func capture_region(region_id: int, faction: int):
	if regions.has(region_id):
		emit_signal("region_captured", region_id)
		print("Bölge fethedildi: " + regions[region_id]["name"])

func get_cities_by_faction(faction: int) -> Array:
	var result = []
	for city in cities:
		if city["faction"] == faction:
			result.append(city)
	return result

func get_nearest_city(position: Vector3) -> Dictionary:
	var nearest = null
	var min_dist = INF
	
	for city in cities:
		var dist = position.distance_to(city["position"])
		if dist < min_dist:
			min_dist = dist
			nearest = city
	
	return nearest if nearest else {}

func get_map_size() -> Vector3:
	return map_size

func get_city_count() -> int:
	return cities.size()

func get_all_cities() -> Array:
	return cities