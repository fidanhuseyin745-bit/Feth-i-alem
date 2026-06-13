extends Node
class_name CastleSystem

## Kale sistemi - İnşa, upgrade, savunma

signal castle_built(castle_id: String, level: int)
signal castle_upgraded(castle_id: String, new_level: int)
signal castle_attacked(castle_id: String, damage: int)
signal castle_destroyed(castle_id: String)
signal siege_started(castle_id: String, attacker: String)

## Kale türleri
enum CastleType {
	WOODEN,      # Ahşap kale (başlangıç)
	STONE,       # Taş kale (seviye 2+)
	FORTIFIED,   # Güçlendirilmiş (seviye 3+)
	IMPERIAL     # İmparatorluk (seviye 5+)
}

const CASTLE_TYPES = {
	CastleType.WOODEN: {
		"name": "Ahşap Kale",
		"desc": "Basit savunma yapısı",
		"icon": "🏰",
		"max_level": 3,
		"upgrade_cost": [0, 500, 1000],
		"defense_bonus": 1.0,
		"troop_capacity": 100,
		"build_time": 2  # tur
	},
	CastleType.STONE: {
		"name": "Taş Kale",
		"desc": "Güçlü taş yapı",
		"icon": "🏯",
		"max_level": 4,
		"upgrade_cost": [0, 800, 1500, 2500],
		"defense_bonus": 1.5,
		"troop_capacity": 250,
		"build_time": 4
	},
	CastleType.FORTIFIED: {
		"name": "Kalkan Duvarlı Kale",
		"desc": "Müstahkem mevki",
		"icon": "⚔️",
		"max_level": 5,
		"upgrade_cost": [0, 1200, 2000, 3000, 4000],
		"defense_bonus": 2.0,
		"troop_capacity": 500,
		"build_time": 6
	},
	CastleType.IMPERIAL: {
		"name": "İmparatorluk Kalesi",
		"desc": "Efsanevi kale",
		"icon": "👑",
		"max_level": 6,
		"upgrade_cost": [0, 2000, 4000, 6000, 8000, 12000],
		"defense_bonus": 3.0,
		"troop_capacity": 1000,
		"build_time": 10
	}
}

## Kale verileri
var castles: Dictionary = {}

## Kaleleri oluştur
func _init() -> void:
	_init_default_castles()

func _init_default_castles() -> void:
	castles = {
		"istanbul_castle": {
			"id": "istanbul_castle",
			"name": "İstanbul Kalesi",
			"region_id": "istanbul",
			"type": CastleType.IMPERIAL,
			"level": 5,
			"health": 10000,
			"max_health": 10000,
			"defense": 500,
			"troops": 3000,
			"troop_capacity": 1000,
			"built": true,
			"position": Vector3(0, 0, 0),
			"owner": "byzantine"
		},
		"edirne_castle": {
			"id": "edirne_castle",
			"name": "Edirne Kalesi",
			"region_id": "edirne",
			"type": CastleType.STONE,
			"level": 4,
			"health": 8000,
			"max_health": 8000,
			"defense": 400,
			"troops": 5000,
			"troop_capacity": 500,
			"built": true,
			"position": Vector3(-80, 0, -30),
			"owner": "ottoman"
		},
		"bursa_castle": {
			"id": "bursa_castle",
			"name": "Bursa Kalesi",
			"region_id": "bursa",
			"type": CastleType.STONE,
			"level": 3,
			"health": 6000,
			"max_health": 6000,
			"defense": 300,
			"troops": 2000,
			"troop_capacity": 250,
			"built": true,
			"position": Vector3(50, 0, 60),
			"owner": "ottoman"
		},
		"karaman_castle": {
			"id": "karaman_castle",
			"name": "Karaman Kalesi",
			"region_id": "karaman",
			"type": CastleType.FORTIFIED,
			"level": 3,
			"health": 7000,
			"max_health": 7000,
			"defense": 350,
			"troops": 2500,
			"troop_capacity": 400,
			"built": true,
			"position": Vector3(100, 0, 80),
			"owner": "karamanid"
		}
	}

func get_castle_data(castle_id: String) -> Dictionary:
	if castles.has(castle_id):
		return castles[castle_id]
	return {}

func get_castles_by_owner(owner: String) -> Array:
	var result = []
	for castle_id in castles:
		if castles[castle_id]["owner"] == owner:
			result.append(castles[castle_id])
	return result

func get_castle_health_percent(castle_id: String) -> float:
	if not castles.has(castle_id):
		return 0.0
	var data = castles[castle_id]
	return float(data["health"]) / float(data["max_health"])

func can_build_castle(region_id: String, gold: int) -> Dictionary:
	var castle_type = _get_available_castle_type(gold)
	if castle_type == CastleType.WOODEN and gold < 300:
		return {"can_build": false, "reason": "Yetersiz altın (300 gerekli)"}
	return {
		"can_build": true,
		"type": castle_type,
		"cost": CASTLE_TYPES[castle_type]["upgrade_cost"][0]
	}

func build_castle(region_id: String, position: Vector3, owner: String, gold: int) -> Dictionary:
	var check = can_build_castle(region_id, gold)
	if not check["can_build"]:
		return check
	
	var castle_type = check["type"]
	var castle_id = region_id + "_castle"
	
	castles[castle_id] = {
		"id": castle_id,
		"name": _get_region_name(region_id) + " Kalesi",
		"region_id": region_id,
		"type": castle_type,
		"level": 1,
		"health": 2000,
		"max_health": 2000,
		"defense": 100,
		"troops": 100,
		"troop_capacity": 100,
		"built": true,
		"position": position,
		"owner": owner,
		"under_construction": false,
		"construction_progress": 0
	}
	
	castle_built.emit(castle_id, 1)
	return {"success": true, "castle_id": castle_id, "cost": check["cost"]}

func can_upgrade(castle_id: String, gold: int) -> Dictionary:
	if not castles.has(castle_id):
		return {"can_upgrade": false, "reason": "Kale bulunamadı"}
	
	var data = castles[castle_id]
	var castle_type = data["type"]
	var type_data = CASTLE_TYPES[castle_type]
	var current_level = data["level"]
	
	if current_level >= type_data["max_level"]:
		return {"can_upgrade": false, "reason": "Maksimum seviyede"}
	
	var cost = type_data["upgrade_cost"][current_level]
	if gold < cost:
		return {"can_upgrade": false, "reason": "Yetersiz altın (%d gerekli)" % cost, "cost": cost}
	
	return {"can_upgrade": true, "cost": cost, "new_level": current_level + 1}

func upgrade_castle(castle_id: String, gold: int) -> Dictionary:
	var check = can_upgrade(castle_id, gold)
	if not check["can_upgrade"]:
		return check
	
	var data = castles[castle_id]
	var castle_type = data["type"]
	var type_data = CASTLE_TYPES[castle_type]
	var old_level = data["level"]
	var new_level = old_level + 1
	var cost = check["cost"]
	
	# Yeni değerler
	var health_increase = type_data["defense_bonus"] * 1000 * (new_level - old_level)
	var defense_increase = type_data["defense_bonus"] * 50 * (new_level - old_level)
	var capacity_increase = type_data["troop_capacity"] * (new_level - old_level)
	
	data["level"] = new_level
	data["max_health"] += health_increase
	data["health"] = data["max_health"]  # Tam onarım
	data["defense"] += defense_increase
	data["troop_capacity"] += capacity_increase
	
	castle_upgraded.emit(castle_id, new_level)
	return {"success": true, "castle_id": castle_id, "new_level": new_level, "cost": cost}

func repair_castle(castle_id: String, gold: int) -> Dictionary:
	if not castles.has(castle_id):
		return {"success": false, "reason": "Kale bulunamadı"}
	
	var data = castles[castle_id]
	var missing_health = data["max_health"] - data["health"]
	if missing_health <= 0:
		return {"success": false, "reason": "Tamir gerekmiyor"}
	
	var repair_cost = int(missing_health * 0.1)  # Her 10 HP = 1 altın
	if gold < repair_cost:
		return {"success": false, "reason": "Yetersiz altın (%d gerekli)" % repair_cost}
	
	data["health"] = data["max_health"]
	return {"success": true, "healed": missing_health, "cost": repair_cost}

func train_troops(castle_id: String, troop_type: String, amount: int, gold: int) -> Dictionary:
	if not castles.has(castle_id):
		return {"success": false, "reason": "Kale bulunamadı"}
	
	var data = castles[castle_id]
	
	# Maliyet hesaplama
	var cost_per_troop: int
	match troop_type:
		"infantry": cost_per_troop = 50
		"cavalry": cost_per_troop = 80
		"archer": cost_per_troop = 60
		"knight": cost_per_troop = 150
		"siege": cost_per_troop = 200
		_: return {"success": false, "reason": "Geçersiz birlik türü"}
	
	var total_cost = cost_per_troop * amount
	var current_troops = data["troops"]
	var capacity = data["troop_capacity"]
	
	if current_troops + amount > capacity:
		amount = capacity - current_troops
		if amount <= 0:
			return {"success": false, "reason": "Kale dolu"}
	
	if gold < total_cost:
		return {"success": false, "reason": "Yetersiz altın (%d gerekli)" % total_cost}
	
	data["troops"] += amount
	return {"success": true, "troops_added": amount, "cost": total_cost}

func attack_castle(castle_id: String, attacking_troops: int, attacker_power: float) -> Dictionary:
	if not castles.has(castle_id):
		return {"success": false, "reason": "Kale bulunamadı"}
	
	var data = castles[castle_id]
	var castle_defense = data["defense"] + (data["troops"] * 0.5)
	
	# Hasar hesaplama
	var damage_ratio = attacker_power / (attacker_power + castle_defense)
	var damage_dealt = int(attacking_troops * damage_ratio * 2)
	var troops_lost = int(damage_dealt * 0.3)
	
	# Savunma hasarı
	data["health"] -= damage_dealt
	data["troops"] -= troops_lost
	
	castle_attacked.emit(castle_id, damage_dealt)
	
	# Kale yıkıldı mı?
	if data["health"] <= 0:
		data["health"] = 0
		castle_destroyed.emit(castle_id)
		return {
			"conquered": true,
			"castle_id": castle_id,
			"damage_dealt": damage_dealt,
			"troops_lost": troops_lost,
			"new_owner": "conqueror"
		}
	
	return {
		"conquered": false,
		"castle_id": castle_id,
		"damage_dealt": damage_dealt,
		"troops_lost": troops_lost,
		"castle_health_percent": get_castle_health_percent(castle_id)
	}

func siege_castle(castle_id: String, attacker: String, siege_power: float) -> Dictionary:
	if not castles.has(castle_id):
		return {"success": false, "reason": "Kale bulunamadı"}
	
	var data = castles[castle_id]
	siege_started.emit(castle_id, attacker)
	
	return attack_castle(castle_id, int(siege_power * 100), siege_power)

func _get_available_castle_type(gold: int) -> CastleType:
	if gold >= 10000:
		return CastleType.IMPERIAL
	elif gold >= 5000:
		return CastleType.FORTIFIED
	elif gold >= 2000:
		return CastleType.STONE
	else:
		return CastleType.WOODEN

func _get_region_name(region_id: String) -> String:
	var names = {
		"istanbul": "İstanbul",
		"edirne": "Edirne",
		"bursa": "Bursa",
		"selanik": "Selanik",
		"karaman": "Karaman",
		"arnavutluk": "Arnavutluk",
		"venedik_adalar": "Ege Adaları",
		"akkoyunlu": "Akkoyunlu"
	}
	return names.get(region_id, region_id)

func get_castle_icon(castle_id: String) -> String:
	if castles.has(castle_id):
		var castle_type = castles[castle_id]["type"]
		if CASTLE_TYPES.has(castle_type):
			return CASTLE_TYPES[castle_type]["icon"]
	return "🏰"

func get_castle_type_name(castle_id: String) -> String:
	if castles.has(castle_id):
		var castle_type = castles[castle_id]["type"]
		if CASTLE_TYPES.has(castle_type):
			return CASTLE_TYPES[castle_type]["name"]
	return "Kale"

func get_defense_bonus(castle_id: String) -> float:
	if castles.has(castle_id):
		var data = castles[castle_id]
		var castle_type = data["type"]
		var type_data = CASTLE_TYPES[castle_type]
		return type_data["defense_bonus"] * (1 + data["level"] * 0.1)
	return 1.0

func get_troop_capacity(castle_id: String) -> int:
	if castles.has(castle_id):
		return castles[castle_id]["troop_capacity"]
	return 0

func get_castle_summary() -> String:
	var summary = "=== Kale Durumu ===\n"
	for castle_id in castles:
		var data = castles[castle_id]
		var health_pct = get_castle_health_percent(castle_id)
		summary += "%s [%s] Lv.%d - HP: %d%% - Asker: %d/%d\n" % [
			data["name"],
			data["owner"],
			data["level"],
			int(health_pct * 100),
			data["troops"],
			data["troop_capacity"]
		]
	return summary