extends Node
class_name CityManager

## Genişletilmiş şehir sistemi - 25+ şehir, binalar, kaynaklar

signal city_discovered(city: CityData)
signal city_captured(city_id: String, new_owner: String)
signal trade_route_established(route_id: String)

class CityData:
	var city_id: String
	var city_name: String
	var city_type: int  # Village, Town, City, Fortress, Capital
	var owner: String
	var position: Vector3
	
	# Özellikler
	var population: int = 1000
	var defense_strength: int = 100
	var max_defense: int = 200
	var income_per_turn: int = 100
	
	# Kaynaklar
	var gold: int = 500
	var food: int = 1000
	var materials: int = 500
	var special_resource: String = ""  # "iron", "gold_ore", "fish", "wood"
	
	# Binalar
	var buildings: Array[String] = ["kale"]
	var available_buildings: Array = [
		{"id": "kale", "name": "Kale", "cost": 300, "defense_bonus": 20},
		{"id": "kışla", "name": "Kışla", "cost": 500, "spawn_unit": "piyade"},
		{"id": "ahır", "name": "Ahır", "cost": 400, "spawn_unit": "süvari"},
		{"id": "okçuluk", "name": "Okçuluk", "cost": 350, "spawn_unit": "okçu"},
		{"id": "depo", "name": "Depo", "cost": 200, "storage_bonus": 100},
		{"id": "değirmen", "name": "Değirmen", "cost": 150, "income_bonus": 20},
		{"id": "kervansaray", "name": "Kervansaray", "cost": 400, "income_bonus": 50},
		{"id": "sur", "name": "Güçlü Sur", "cost": 600, "defense_bonus": 40},
		{"id": "hamam", "name": "Hamam", "cost": 250, "income_bonus": 30},
		{"id": "cami", "name": "Cami", "cost": 800, "income_bonus": 60, "defense_bonus": 10},
		{"id": "çarşı", "name": "Çarşı", "cost": 500, "income_bonus": 80},
		{"id": "tersane", "name": "Tersane", "cost": 1000, "spawn_unit": "gemiler"},
		{"id": "maden", "name": "Maden", "cost": 700, "resource_bonus": 30},
		{"id": "balıkçılık", "name": "Balıkçılık", "cost": 300, "resource_bonus": 40},
	]
	
	# Ticaret
	var market_prices: Dictionary = {
		"wheat": 10, "iron": 50, "gold": 200, "fish": 15, "wood": 20, "cloth": 40
	}
	var trade_partners: Array[String] = []
	
	# Durum
	var current_state: int = 0  # PEACEFUL, BESIEGED, CAPTURED
	var siege_turns: int = 0
	var loyalty: int = 100  # Şehir sadakati
	
	func get_city_type_name() -> String:
		match city_type:
			0: return "Köy"
			1: return "Kasaba"
			2: return "Şehir"
			3: return "Kale"
			4: return "Başkent"
		return "Bilinmiyor"

var cities: Dictionary = {}
var player_cities: Array = []
var enemy_cities: Array = []
var discovered_cities: Array = []

# Şehir veritabanı
var city_database: Array = [
	# ANADOLU
	{"id": "istanbul", "name": "İstanbul", "type": 4, "owner": "byzantine", "pos": Vector3(0, 0, 0), "special": "gold", "desc": "Doğu'nun en büyük şehri, fethedilmeyi bekliyor"},
	{"id": "edirne", "name": "Edirne", "type": 4, "owner": "ottoman", "pos": Vector3(-80, 0, -30), "special": "", "desc": "Osmanlı'nın başkenti"},
	{"id": "bursa", "name": "Bursa", "type": 2, "owner": "ottoman", "pos": Vector3(50, 0, 60), "special": "gold_ore", "desc": "İpek yolu üzerinde önemli ticaret merkezi"},
	{"id": "ankara", "name": "Ankara", "type": 2, "owner": "ottoman", "pos": Vector3(120, 0, 30), "special": "iron", "desc": "Anadolu'nun kalbi"},
	{"id": "kayseri", "name": "Kayseri", "type": 2, "owner": "ottoman", "pos": Vector3(150, 0, 50), "special": "iron", "desc": "Kapadokya'nın merkezi"},
	{"id": "konya", "name": "Konya", "type": 2, "owner": "ottoman", "pos": Vector3(180, 0, 70), "special": "", "desc": "Selçuklu mirası"},
	{"id": "sivas", "name": "Sivas", "type": 2, "owner": "ottoman", "pos": Vector3(200, 0, 20), "special": "iron", "desc": "Doğu ticaret yolları"},
	{"id": " trabzon", "name": "Trabzon", "type": 3, "owner": "ottoman", "pos": Vector3(280, 0, -10), "special": "fish", "desc": "Karadeniz'in incisi"},
	{"id": "diyarbakir", "name": "Diyarbakır", "type": 3, "owner": "ottoman", "pos": Vector3(260, 0, 80), "special": "iron", "desc": "Kürdistan'ın kapısı"},
	{"id": "erzurum", "name": "Erzurum", "type": 3, "owner": "ottoman", "pos": Vector3(300, 0, 30), "special": "", "desc": "Doğu'nun kalesi"},
	{"id": "karaman", "name": "Karaman", "type": 2, "owner": "karamanid", "pos": Vector3(100, 0, 80), "special": "", "desc": "Karamanoğulları'nın kalbi"},
	{"id": "nigde", "name": "Niğde", "type": 1, "owner": "ottoman", "pos": Vector3(160, 0, 60), "special": "", "desc": "Orta Anadolu"},
	{"id": "kirsehir", "name": "Kırşehir", "type": 1, "owner": "ottoman", "pos": Vector3(140, 0, 45), "special": "", "desc": "Kırşehir"},
	
	# BALKANLAR
	{"id": "selanik", "name": "Selanik", "type": 2, "owner": "ottoman", "pos": Vector3(-60, 0, 50), "special": "", "desc": "Ege'nin incisi"},
	{"id": "filibe", "name": "Filibe", "type": 2, "owner": "ottoman", "pos": Vector3(-40, 0, 20), "special": "", "desc": "Trakya'nın merkezi"},
	{"id": "sofya", "name": "Sofya", "type": 2, "owner": "byzantine", "pos": Vector3(-100, 0, 0), "special": "iron", "desc": "Balkanların kapısı"},
	{"id": "belgrat", "name": "Belgrat", "type": 3, "owner": "byzantine", "pos": Vector3(-160, 0, -20), "special": "", "desc": "Tuna'nın bekçisi"},
	{"id": "budapeşte", "name": "Budapeşte", "type": 3, "owner": "byzantine", "pos": Vector3(-200, 0, -40), "special": "", "desc": "Macaristan'ın kalbi"},
	{"id": "saraybosna", "name": "Saraybosna", "type": 2, "owner": "byzantine", "pos": Vector3(-130, 0, 20), "special": "", "desc": "Bosna'nın incisi"},
	{"id": "arnavutluk", "name": "Kruje", "type": 3, "owner": "albania", "pos": Vector3(-120, 0, 30), "special": "", "desc": "Arnavutluk'un kalesi"},
	{"id": "iskodra", "name": "İskodra", "type": 2, "owner": "albania", "pos": Vector3(-140, 0, 40), "special": "fish", "desc": "Adriatik kıyısı"},
	
	# EGE ADALARI VE AKDENİZ
	{"id": "venedik", "name": "Venedik", "type": 4, "owner": "venice", "pos": Vector3(-60, 0, -80), "special": "", "desc": "Denizlerin kraliçesi"},
	{"id": "kandiye", "name": "Kandiye", "type": 3, "owner": "venice", "pos": Vector3(-20, 0, -120), "special": "", "desc": "Girit'in incisi"},
	{"id": "rodosc", "name": "Rodos", "type": 2, "owner": "venice", "pos": Vector3(20, 0, -100), "special": "fish", "desc": "Şövalyeler adası"},
	{"id": "dubrovnik", "name": "Dubrovnik", "type": 2, "owner": "venice", "pos": Vector3(-80, 0, -60), "special": "fish", "desc": "Dalmaçya'nın incisi"},
	{"id": "midilli", "name": "Midilli", "type": 1, "owner": "venice", "pos": Vector3(-30, 0, -50), "special": "olive", "desc": "Ege'nin incisi"},
	
	# DOĞU
	{"id": "akkoyunlu", "name": "Tebriz", "type": 4, "owner": "akkoyunlu", "pos": Vector3(380, 0, 40), "special": "gold", "desc": "Doğu'nun büyük şehri"},
	{"id": "erivan", "name": "Erivan", "type": 2, "owner": "akkoyunlu", "pos": Vector3(400, 0, 60), "special": "iron", "desc": "Ermenistan'ın kalbi"},
	{"id": "kars", "name": "Kars", "type": 3, "owner": "akkoyunlu", "pos": Vector3(340, 0, 50), "special": "", "desc": "Doğu sınırı"},
	{"id": "musul", "name": "Musul", "type": 3, "owner": "akkoyunlu", "pos": Vector3(320, 0, 100), "special": "oil", "desc": "Mezopotamya'nın kapısı"},
	{"id": "halep", "name": "Halep", "type": 3, "owner": "akkoyunlu", "pos": Vector3(280, 0, 130), "special": "", "desc": "Suriye'nin kalbi"},
	{"id": "suriye", "name": "Şam", "type": 3, "owner": "akkoyunlu", "pos": Vector3(260, 0, 150), "special": "", "desc": "Eski şehir"},
	
	# ANADOLU KÖYLERİ
	{"id": "biga", "name": "Biga", "type": 0, "owner": "ottoman", "pos": Vector3(30, 0, -20), "special": "", "desc": "Küçük tarım kasabası"},
	{"id": "bolu", "name": "Bolu", "type": 1, "owner": "ottoman", "pos": Vector3(70, 0, 20), "special": "wood", "desc": "Ormanlık bölge"},
	{"id": "sakarya", "name": "Sakarya", "type": 0, "owner": "ottoman", "pos": Vector3(60, 0, 10), "special": "", "desc": "Tarım bölgesi"},
	{"id": "kocaeli", "name": "İzmit", "type": 1, "owner": "ottoman", "pos": Vector3(40, 0, -5), "special": "", "desc": "İstanbul'a yakın"},
]

func _ready():
	initialize_cities()

func initialize_cities():
	for city_info in city_database:
		create_city(city_info)

func create_city(info: Dictionary) -> CityData:
	var city = CityData.new()
	city.city_id = info["id"]
	city.city_name = info["name"]
	city.city_type = info["type"]
	city.owner = info["owner"]
	city.position = info["pos"]
	city.special_resource = info.get("special", "")
	
	# Şehir tipine göre değerler
	match city.city_type:
		0:  # Village
			city.population = 200 + randi() % 300
			city.defense_strength = 30
			city.max_defense = 60
			city.income_per_turn = 30 + randi() % 20
		1:  # Town
			city.population = 500 + randi() % 1000
			city.defense_strength = 80
			city.max_defense = 150
			city.income_per_turn = 80 + randi() % 40
		2:  # City
			city.population = 2000 + randi() % 3000
			city.defense_strength = 150
			city.max_defense = 300
			city.income_per_turn = 150 + randi() % 100
		3:  # Fortress
			city.population = 300 + randi() % 200
			city.defense_strength = 300
			city.max_defense = 500
			city.income_per_turn = 60 + randi() % 40
		4:  # Capital
			city.population = 5000 + randi() % 5000
			city.defense_strength = 400
			city.max_defense = 800
			city.income_per_turn = 300 + randi() % 200
	
	cities[city.city_id] = city
	_update_city_lists()
	
	return city

func _update_city_lists():
	player_cities.clear()
	enemy_cities.clear()
	discovered_cities.clear()
	
	for city_id in cities:
		var city = cities[city_id]
		if city.owner == "ottoman":
			player_cities.append(city)
		else:
			enemy_cities.append(city)
		discovered_cities.append(city)

func get_city(city_id: String) -> CityData:
	return cities.get(city_id)

func get_all_cities() -> Array:
	return cities.values()

func get_player_cities() -> Array:
	return player_cities

func get_enemy_cities() -> Array:
	return enemy_cities

func get_nearest_city(pos: Vector3, owner_filter: String = "") -> CityData:
	var nearest: CityData = null
	var min_distance = INF
	
	for city_id in cities:
		var city = cities[city_id]
		if owner_filter != "" and city.owner != owner_filter:
			continue
		
		var distance = pos.distance_to(city.position)
		if distance < min_distance:
			min_distance = distance
			nearest = city
	
	return nearest

func capture_city(city_id: String, new_owner: String):
	if not cities.has(city_id):
		return
	
	var city = cities[city_id]
	var old_owner = city.owner
	city.owner = new_owner
	city.loyalty = 50  # Düşük sadakat
	
	_update_city_lists()
	city_captured.emit(city_id, new_owner)

func get_cities_by_resource(resource: String) -> Array:
	var result: Array = []
	for city_id in cities:
		var city = cities[city_id]
		if city.special_resource == resource:
			result.append(city)
	return result

func get_trade_routes() -> Array:
	var routes: Array = []
	
	# Otomatik ticaret rotaları
	for city_id in cities:
		var city = cities[city_id]
		if city.owner == "ottoman" and city.buildings.has("kervansaray"):
			var connected = _find_trade_partners(city)
			for partner in connected:
				if not routes.has([city_id, partner]):
					routes.append([city_id, partner])
	
	return routes

func _find_trade_partners(city: CityData) -> Array:
	var partners: Array = []
	var max_distance = 200.0
	
	for other_id in cities:
		if other_id == city.city_id:
			continue
		
		var other = cities[other_id]
		if city.position.distance_to(other.position) < max_distance:
			partners.append(other_id)
	
	return partners

func collect_all_income() -> int:
	var total = 0
	for city in player_cities:
		total += city.income_per_turn
		# Bina bonusları
		for building in city.buildings:
			if building == "değirmen":
				total += 20
			elif building == "çarşı":
				total += 80
			elif building == "cami":
				total += 60
			elif building == "hamam":
				total += 30
	return total

func get_total_defense() -> int:
	var total = 0
	for city in player_cities:
		total += city.defense_strength
		# Bina bonusları
		for building in city.buildings:
			if building == "sur":
				total += 40
			elif building == "kale":
				total += 20
	return total

func get_total_population() -> int:
	var total = 0
	for city in player_cities:
		total += city.population
	return total

func build_in_city(city_id: String, building_id: String) -> bool:
	if not cities.has(city_id):
		return false
	
	var city = cities[city_id]
	if city.owner != "ottoman":
		return false
	
	if building_id in city.buildings:
		return false
	
	# Bina maliyetini kontrol et
	var building_data = _get_building_data(city, building_id)
	if not building_data:
		return false
	
	var cost = building_data.get("cost", 100)
	if city.gold < cost:
		return false
	
	city.gold -= cost
	city.buildings.append(building_id)
	
	# Bina etkilerini uygula
	_apply_building_effects(city, building_data)
	
	return true

func _get_building_data(city: CityData, building_id: String) -> Dictionary:
	for building in city.available_buildings:
		if building["id"] == building_id:
			return building
	return {}

func _apply_building_effects(city: CityData, building_data: Dictionary):
	if building_data.has("defense_bonus"):
		city.max_defense += building_data["defense_bonus"]
		city.defense_strength += building_data["defense_bonus"] / 2
	if building_data.has("income_bonus"):
		city.income_per_turn += building_data["income_bonus"]
	if building_data.has("resource_bonus"):
		# Özel kaynak bonusu
		pass

func get_city_description(city_id: String) -> String:
	if not cities.has(city_id):
		return ""
	
	var city = cities[city_id]
	var buildings_text = ""
	for building in city.buildings:
		buildings_text += "🏛️ " + building + "\n"
	
	var special_text = ""
	if city.special_resource != "":
		var resource_names = {
			"gold": "💰 Altın madeni",
			"gold_ore": "⛏️ Altın cevheri",
			"iron": "⚒️ Demir madeni",
			"fish": "🐟 Balıkçılık",
			"wood": "🪵 Kereste",
			"olive": "🫒 Zeytin",
			"oil": "🛢️ Petrol"
		}
		special_text = "\n\n📦 Özel Kaynak: " + resource_names.get(city.special_resource, "")
	
	return """%s (%s)
👥 Nüfus: %d
🏰 Savunma: %d/%d
💰 Gelir: %d/turn
🪙 Şehir Altını: %d
🍖 Yiyecek: %d

%s

%s""" % [
		city.city_name,
		city.get_city_type_name(),
		city.population,
		city.defense_strength,
		city.max_defense,
		city.income_per_turn,
		city.gold,
		city.food,
		buildings_text if buildings_text else "Bina yok\n",
		special_text
	]

func save_data() -> Dictionary:
	var cities_data = {}
	for city_id in cities:
		var city = cities[city_id]
		cities_data[city_id] = {
			"owner": city.owner,
			"gold": city.gold,
			"food": city.food,
			"defense_strength": city.defense_strength,
			"buildings": city.buildings,
			"loyalty": city.loyalty
		}
	return {"cities": cities_data}

func load_data(data: Dictionary):
	var cities_data = data.get("cities", {})
	for city_id in cities_data:
		if cities.has(city_id):
			var city = cities[city_id]
			var city_data = cities_data[city_id]
			city.owner = city_data.get("owner", "ottoman")
			city.gold = city_data.get("gold", 0)
			city.food = city_data.get("food", 0)
			city.defense_strength = city_data.get("defense_strength", 100)
			city.buildings = city_data.get("buildings", ["kale"])
			city.loyalty = city_data.get("loyalty", 100)
	_update_city_lists()