extends Node
class_name ConquestSystem

## Genshin tarzı fetih sistemi - Açık dünya savaşları

signal region_conquered(region_id: String, new_owner: String)
signal battle_started(region_id: String, attacker: String, defender: String)
signal battle_ended(region_id: String, winner: String, casualties: int)
signal siege_started(region_id: String, duration: int)
signal siege_ended(region_id: String, result: String)

const CastleSystem = preload("res://scenes/3d/scripts/CastleSystem.gd")
var castle_system: CastleSystem

## Bölgeler
var regions: Dictionary = {}
var factions: Dictionary = {}

## Savaş tarihi
var battle_history: Array = []

## Kuşatma durumu
var active_sieges: Dictionary = {}

func _init() -> void:
	castle_system = CastleSystem.new()
	_init_regions()
	_init_factions()

func _init_factions() -> void:
	factions = {
		"ottoman": {
			"name": "Osmanlı",
			"color": Color(0.9, 0.7, 0.1),
			"type": "player",
			"total_troops": 0,
			"total_gold": 5000,
			"allied_with": [],
			"at_war_with": ["byzantine", "karamanid"]
		},
		"byzantine": {
			"name": "Bizans",
			"color": Color(0.3, 0.5, 0.9),
			"type": "enemy",
			"total_troops": 5000,
			"total_gold": 3000,
			"allied_with": [],
			"at_war_with": ["ottoman"]
		},
		"karamanid": {
			"name": "Karamanlı",
			"color": Color(0.2, 0.7, 0.4),
			"type": "enemy",
			"total_troops": 4000,
			"total_gold": 2500,
			"allied_with": ["byzantine"],
			"at_war_with": ["ottoman"]
		},
		"albania": {
			"name": "Arnavutluk",
			"color": Color(0.85, 0.2, 0.2),
			"type": "enemy",
			"total_troops": 2000,
			"total_gold": 1500,
			"allied_with": [],
			"at_war_with": ["ottoman"]
		},
		"venice": {
			"name": "Venedik",
			"color": Color(0.6, 0.3, 0.8),
			"type": "neutral",
			"total_troops": 3000,
			"total_gold": 4000,
			"allied_with": [],
			"at_war_with": []
		},
		"akkoyunlu": {
			"name": "Akkoyunlu",
			"color": Color(0.9, 0.5, 0.1),
			"type": "enemy",
			"total_troops": 4500,
			"total_gold": 3500,
			"allied_with": [],
			"at_war_with": ["ottoman"]
		}
	}

func _init_regions() -> void:
	regions = {
		"istanbul": {
			"id": "istanbul",
			"name": "İstanbul",
			"owner": "byzantine",
			"position": Vector3(0, 0, 0),
			"troops": 3000,
			"income": 500,
			"defense": 800,
			"strategic": true,
			"has_castle": true,
			"resources": {"food": 100, "ore": 50, "wood": 80},
			"connections": ["edirne", "bursa"],
			"terrain": "city"
		},
		"edirne": {
			"id": "edirne",
			"name": "Edirne",
			"owner": "ottoman",
			"position": Vector3(-80, 0, -30),
			"troops": 5000,
			"income": 300,
			"defense": 400,
			"strategic": true,
			"has_castle": true,
			"resources": {"food": 80, "ore": 30, "wood": 50},
			"connections": ["istanbul", "selanik"],
			"terrain": "plains"
		},
		"bursa": {
			"id": "bursa",
			"name": "Bursa",
			"owner": "ottoman",
			"position": Vector3(50, 0, 60),
			"troops": 2000,
			"income": 200,
			"defense": 200,
			"strategic": false,
			"has_castle": false,
			"resources": {"food": 120, "ore": 20, "wood": 100},
			"connections": ["istanbul", "karaman"],
			"terrain": "forest"
		},
		"selanik": {
			"id": "selanik",
			"name": "Selanik",
			"owner": "ottoman",
			"position": Vector3(-60, 0, 50),
			"troops": 1500,
			"income": 180,
			"defense": 150,
			"strategic": true,
			"has_castle": false,
			"resources": {"food": 60, "ore": 40, "wood": 30},
			"connections": ["edirne", "arnavutluk"],
			"terrain": "hills"
		},
		"karaman": {
			"id": "karaman",
			"name": "Karaman",
			"owner": "karamanid",
			"position": Vector3(100, 0, 80),
			"troops": 2500,
			"income": 160,
			"defense": 300,
			"strategic": false,
			"has_castle": true,
			"resources": {"food": 40, "ore": 80, "wood": 20},
			"connections": ["bursa", "akkoyunlu"],
			"terrain": "mountains"
		},
		"arnavutluk": {
			"id": "arnavutluk",
			"name": "Arnavutluk",
			"owner": "albania",
			"position": Vector3(-20, 0, 80),
			"troops": 1800,
			"income": 100,
			"defense": 250,
			"strategic": false,
			"has_castle": false,
			"resources": {"food": 50, "ore": 10, "wood": 90},
			"connections": ["selanik", "venedik_adalar"],
			"terrain": "forest"
		},
		"venedik_adalar": {
			"id": "venedik_adalar",
			"name": "Ege Adaları",
			"owner": "venice",
			"position": Vector3(30, 0, 100),
			"troops": 1200,
			"income": 250,
			"defense": 180,
			"strategic": true,
			"has_castle": false,
			"resources": {"food": 30, "ore": 5, "wood": 10},
			"connections": ["arnavutluk", "karaman"],
			"terrain": "island"
		},
		"akkoyunlu": {
			"id": "akkoyunlu",
			"name": "Akkoyunlu Toprakları",
			"owner": "akkoyunlu",
			"position": Vector3(150, 0, 50),
			"troops": 4000,
			"income": 200,
			"defense": 350,
			"strategic": true,
			"has_castle": true,
			"resources": {"food": 70, "ore": 100, "wood": 40},
			"connections": ["karaman"],
			"terrain": "desert"
		}
	}

# Savaş hesaplamaları
func calculate_battle(attacker_troops: int, defender_troops: int, attacker_power: float, defender_bonus: float) -> Dictionary:
	var attack_power = attacker_troops * attacker_power
	var defense_power = defender_troops * defender_bonus
	
	var total_power = attack_power + defense_power
	if total_power == 0:
		return {"attacker_wins": false, "attacker_losses": 0, "defender_losses": 0}
	
	var attacker_win_chance = attack_power / total_power
	
	# Rastgele sonuç
	var roll = randf()
	var attacker_wins = roll < attacker_win_chance
	
	var attacker_losses = int(attacker_troops * (0.3 if attacker_wins else 0.6))
	var defender_losses = int(defender_troops * (0.6 if attacker_wins else 0.3))
	
	return {
		"attacker_wins": attacker_wins,
		"attacker_losses": attacker_losses,
		"defender_losses": defender_losses,
		"attacker_win_chance": attacker_win_chance
	}

func attack_region(region_id: String, attacking_troops: int, faction: String) -> Dictionary:
	if not regions.has(region_id):
		return {"success": false, "reason": "Bölge bulunamadı"}
	
	var region = regions[region_id]
	var defender_faction = region["owner"]
	
	if defender_faction == faction:
		return {"success": false, "reason": "Kendi bölgenize saldıramazsınız"}
	
	battle_started.emit(region_id, faction, defender_faction)
	
	# Kale bonusu
	var castle_bonus = 1.0
	if region["has_castle"]:
		var castle_id = region_id + "_castle"
		castle_bonus = castle_system.get_defense_bonus(castle_id)
	
	# Faktör bonusu
	var attacker_data = factions[faction]
	var defender_data = factions[defender_faction]
	
	var attack_power = 1.0 + (attacker_data.get("aggression", 0) * 0.1)
	var defense_bonus = castle_bonus + (defender_data.get("defense", 0) * 0.05)
	
	var result = calculate_battle(attacking_troops, region["troops"], attack_power, defense_bonus)
	
	# Sonuçları uygula
	region["troops"] -= result["defender_losses"]
	attacker_data["total_troops"] -= result["attacker_losses"]
	
	# Kayıt
	var battle_record = {
		"region_id": region_id,
		"attacker": faction,
		"defender": defender_faction,
		"attacker_troops": attacking_troops,
		"defender_troops": region["troops"],
		"result": result
	}
	battle_history.append(battle_record)
	
	if result["attacker_wins"]:
		var old_owner = region["owner"]
		region["owner"] = faction
		region["defense"] = int(region["defense"] * 0.5)  # Yeni sahip daha az savunma
		region_conquered.emit(region_id, faction)
		return {
			"success": true,
			"conquered": true,
			"region_name": region["name"],
			"losses": result["attacker_losses"],
			"enemy_losses": result["defender_losses"]
		}
	else:
		battle_ended.emit(region_id, defender_faction, result["defender_losses"])
		return {
			"success": true,
			"conquered": false,
			"losses": result["attacker_losses"],
			"enemy_losses": result["defender_losses"],
			"remaining_enemy_troops": region["troops"]
		}

func start_siege(region_id: String, attacking_faction: String, troops: int) -> Dictionary:
	if not regions.has(region_id):
		return {"success": false, "reason": "Bölge bulunamadı"}
	
	if active_sieges.has(region_id):
		return {"success": false, "reason": "Kuşatma zaten aktif"}
	
	var region = regions[region_id]
	var duration = 3 if region["strategic"] else 2
	
	active_sieges[region_id] = {
		"attacker": attacking_faction,
		"troops": troops,
		"duration": duration,
		"progress": 0,
		"start_time": Time.get_unix_time_from_system()
	}
	
	siege_started.emit(region_id, duration)
	return {"success": true, "duration": duration}

func end_siege(region_id: String) -> Dictionary:
	if not active_sieges.has(region_id):
		return {"success": false, "reason": "Aktif kuşatma yok"}
	
	var siege = active_sieges[region_id]
	active_sieges.erase(region_id)
	
	# Kuşatma sonucu - otomatik saldırı
	var result = attack_region(region_id, siege["troops"], siege["attacker"])
	result["siege_duration"] = siege["duration"]
	
	siege_ended.emit(region_id, "ended")
	return result

func get_region_info(region_id: String) -> Dictionary:
	if not regions.has(region_id):
		return {}
	return regions[region_id].duplicate()

func get_faction_regions(faction: String) -> Array:
	var owned = []
	for rid in regions:
		if regions[rid]["owner"] == faction:
			owned.append(regions[rid])
	return owned

func get_faction_total_troops(faction: String) -> int:
	var total = 0
	for rid in regions:
		if regions[rid]["owner"] == faction:
			total += regions[rid]["troops"]
	return total

func get_faction_total_income(faction: String) -> int:
	var income = 0
	for rid in regions:
		if regions[rid]["owner"] == faction:
			income += regions[rid]["income"]
	return income

func is_at_war(faction1: String, faction2: String) -> bool:
	if factions.has(faction1) and factions[faction2]["at_war_with"].has(faction2):
		return true
	if factions.has(faction2) and factions[faction2]["at_war_with"].has(faction1):
		return true
	return false

func can_attack(faction: String, target_faction: String) -> bool:
	if not factions.has(faction) or not factions.has(target_faction):
		return false
	return factions[faction]["at_war_with"].has(target_faction)

func get_connected_regions(region_id: String) -> Array:
	if not regions.has(region_id):
		return []
	return regions[region_id]["connections"]

func get_battle_history(count: int = 10) -> Array:
	var history = battle_history.duplicate()
	history.reverse()
	return history.slice(0, count)

func simulate_enemy_turn() -> void:
	# AI saldirilari
	for faction_id in factions:
		if faction_id == "ottoman":
			continue
		
		var faction = factions[faction_id]
		if faction["type"] != "enemy":
			continue
		
		# Saldırı şansı
		if randf() > 0.2:
			continue
		
		var owned_regions = get_faction_regions(faction_id)
		if owned_regions.size() == 0:
			continue
		
		# Rastgele bölge seç
		var region = owned_regions[randi() % owned_regions.size()]
		
		# Bağlı bölgelere saldır
		for connected_id in region["connections"]:
			if not regions.has(connected_id):
				continue
			var target = regions[connected_id]
			if can_attack(faction_id, target["owner"]):
				# Saldırı
				var troops = int(region["troops"] * 0.3)
				if troops > 0:
					attack_region(connected_id, troops, faction_id)
				break

func get_map_summary() -> String:
	var summary = "=== BÖLGE DURUMU ===\n\n"
	for rid in regions:
		var r = regions[rid]
		summary += "[%s] %s - %s\n  Asker: %d | Savunma: %d | Gelir: %d/gün\n" % [
			factions[r["owner"]]["name"],
			r["name"],
			r["terrain"],
			r["troops"],
			r["defense"],
			r["income"]
		]
	return summary