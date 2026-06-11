extends Node
class_name ProfessionSystem

## Genshin tarzı meslek sistemi - 10 farklı meslek

enum Profession {
	WARRIOR,      # Savaşçı
	MERCHANT,     # Tüccar
	FARMER,       # Çiftçi
	MINER,        # Madenci
	FISHER,       # Balıkçı
	BLACKSMITH,   # Demirci
	ARCHER,       # Okçu
	HEALER,       # Şifacı
	SCOUT,        # Kaşif
	KNIGHT        # Şövalye
}

## Meslek verileri
const PROFESSION_DATA: Dictionary = {
	Profession.WARRIOR: {
		"name": "Savaşçı",
		"desc": "Yakın dövüş ustası - Yüksek hasar ve savunma",
		"icon": "⚔️",
		"color": Color(0.9, 0.2, 0.2),
		"base_stats": {"attack": 50, "defense": 30, "speed": 20, "magic": 5},
		"skills": ["Güçlü Vuruş", "Kalkan Darbesi", "Öfke"],
		"unlock_cost": 0
	},
	Profession.MERCHANT: {
		"name": "Tüccar",
		"desc": "Ticaret uzmanı - Düşük fiyat, yüksek gelir",
		"icon": "💰",
		"color": Color(1.0, 0.85, 0.0),
		"base_stats": {"attack": 10, "defense": 15, "speed": 25, "magic": 10},
		"skills": ["Ticaret Ustası", "Pazarlık", "Altın Algı"],
		"unlock_cost": 1000
	},
	Profession.FARMER: {
		"name": "Çiftçi",
		"desc": "Tarım ustası - Yüksek yiyecek üretimi",
		"icon": "🌾",
		"color": Color(0.4, 0.7, 0.2),
		"base_stats": {"attack": 15, "defense": 25, "speed": 15, "magic": 5},
		"skills": ["Verimli Toprak", "Hasat", "Sulama"],
		"unlock_cost": 500
	},
	Profession.MINER: {
		"name": "Madenci",
		"desc": "Maden ustası - Yüksek cevher üretimi",
		"icon": "⛏️",
		"color": Color(0.6, 0.5, 0.3),
		"base_stats": {"attack": 25, "defense": 35, "speed": 10, "magic": 0},
		"skills": ["DejaVu", "Patlatma", "Madencilik"],
		"unlock_cost": 800
	},
	Profession.FISHER: {
		"name": "Balıkçı",
		"desc": "Deniz ustası - Yüksek balık üretimi",
		"icon": "🐟",
		"color": Color(0.2, 0.5, 0.9),
		"base_stats": {"attack": 20, "defense": 20, "speed": 30, "magic": 10},
		"skills": ["Balık Ağı", "Dalış", "Deniz Durumu"],
		"unlock_cost": 600
	},
	Profession.BLACKSMITH: {
		"name": "Demirci",
		"desc": "Silah ustası - Yüksek silah üretimi",
		"icon": "🔨",
		"color": Color(0.7, 0.3, 0.1),
		"base_stats": {"attack": 40, "defense": 40, "speed": 10, "magic": 5},
		"skills": ["Dövme", "Kalite Kontrol", "Usta Ekipman"],
		"unlock_cost": 1200
	},
	Profession.ARCHER: {
		"name": "Okçu",
		"desc": "Uzaktan usta - Yüksek kritik vuruş",
		"icon": "🏹",
		"color": Color(0.2, 0.8, 0.3),
		"base_stats": {"attack": 45, "defense": 15, "speed": 35, "magic": 0},
		"skills": ["Hassas Nişan", "Zehirli Ok", "Rüzgar Oku"],
		"unlock_cost": 700
	},
	Profession.HEALER: {
		"name": "Şifacı",
		"desc": "Şifa ustası - Takım restorasyonu",
		"icon": "💊",
		"color": Color(1.0, 0.8, 0.9),
		"base_stats": {"attack": 10, "defense": 20, "speed": 20, "magic": 50},
		"skills": ["Şifa", "İyileştirme", "Can Yenileme"],
		"unlock_cost": 1500
	},
	Profession.SCOUT: {
		"name": "Kaşif",
		"desc": "Keşif ustası - Hızlı hareket, harita bilgisi",
		"icon": "🗺️",
		"color": Color(0.5, 0.3, 0.7),
		"base_stats": {"attack": 25, "defense": 15, "speed": 50, "magic": 15},
		"skills": ["Gözlem", "Gizlenme", "Hızlı Koşu"],
		"unlock_cost": 900
	},
	Profession.KNIGHT: {
		"name": "Şövalye",
		"desc": "Süvari birliği - Yüksek savunma, kalkan",
		"icon": "🛡️",
		"color": Color(0.3, 0.5, 0.8),
		"base_stats": {"attack": 35, "defense": 50, "speed": 15, "magic": 5},
		"skills": ["Kalkan Duvarı", "Şarj", "Onur"],
		"unlock_cost": 2000
	}
}

## Oyuncu profili
var current_profession: Profession = Profession.WARRIOR
var profession_level: int = 1
var profession_exp: int = 0
var unlocked_professions: Array = [Profession.WARRIOR]

## İstatistikler
var stats: Dictionary = {
	"attack": 10,
	"defense": 10,
	"speed": 10,
	"magic": 10,
	"health": 100,
	"stamina": 100
}

## Seviye başına EXP
const EXP_PER_LEVEL: int = 100

signal profession_changed(profession: Profession, level: int)
signal level_up(level: int)
signal exp_gained(amount: int)

func _init() -> void:
	_apply_profession_stats()

func get_profession_name() -> String:
	if PROFESSION_DATA.has(current_profession):
		return PROFESSION_DATA[current_profession]["name"]
	return "Bilinmeyen"

func get_profession_icon() -> String:
	if PROFESSION_DATA.has(current_profession):
		return PROFESSION_DATA[current_profession]["icon"]
	return "❓"

func get_profession_color() -> Color:
	if PROFESSION_DATA.has(current_profession):
		return PROFESSION_DATA[current_profession]["color"]
	return Color.WHITE

func get_profession_desc() -> String:
	if PROFESSION_DATA.has(current_profession):
		return PROFESSION_DATA[current_profession]["desc"]
	return ""

func get_all_skills() -> Array:
	if PROFESSION_DATA.has(current_profession):
		return PROFESSION_DATA[current_profession]["skills"]
	return []

func get_stats_text() -> String:
	return "ATK: %d | DEF: %d | HIZ: %d | BÜYÜ: %d" % [
		stats["attack"], stats["defense"], stats["speed"], stats["magic"]
	]

func _apply_profession_stats() -> void:
	if PROFESSION_DATA.has(current_profession):
		var base = PROFESSION_DATA[current_profession]["base_stats"]
		stats["attack"] = base["attack"] + (profession_level - 1) * 5
		stats["defense"] = base["defense"] + (profession_level - 1) * 5
		stats["speed"] = base["speed"] + (profession_level - 1) * 3
		stats["magic"] = base["magic"] + (profession_level - 1) * 3
		stats["health"] = 100 + (profession_level - 1) * 20
		stats["stamina"] = 100 + (profession_level - 1) * 10

func change_profession(prof: Profession) -> bool:
	if not PROFESSION_DATA.has(prof):
		return false
	
	if not unlocked_professions.has(prof):
		var cost = PROFESSION_DATA[prof]["unlock_cost"]
		return false  # Unlock etmeden önce kontrol yapılmalı
	
	current_profession = prof
	_apply_profession_stats()
	profession_changed.emit(current_profession, profession_level)
	return true

func unlock_profession(prof: Profession, gold_cost: int, current_gold: int) -> bool:
	if unlocked_professions.has(prof):
		return false
	
	var cost = PROFESSION_DATA[prof]["unlock_cost"]
	if current_gold < cost:
		return false
	
	unlocked_professions.append(prof)
	return true

func add_exp(amount: int) -> void:
	profession_exp += amount
	exp_gained.emit(amount)
	
	while profession_exp >= EXP_PER_LEVEL:
		profession_exp -= EXP_PER_LEVEL
		_level_up()

func _level_up() -> void:
	profession_level += 1
	_apply_profession_stats()
	level_up.emit(profession_level)

func get_level_progress() -> float:
	return float(profession_exp) / float(EXP_PER_LEVEL)

func is_unlocked(prof: Profession) -> bool:
	return unlocked_professions.has(prof)

func get_all_professions_data() -> Array:
	var result = []
	for prof in PROFESSION_DATA.keys():
		var data = PROFESSION_DATA[prof].duplicate()
		data["id"] = prof
		data["unlocked"] = unlocked_professions.has(prof)
		data["level_required"] = 1 if prof == Profession.WARRIOR else 5
		result.append(data)
	return result

# Bonus hesaplama (meslek bazlı)
func get_production_bonus(production_type: String) -> float:
	match current_profession:
		Profession.MERCHANT:
			if production_type in ["gold", "trade"]:
				return 0.5  # +50%
		Profession.FARMER:
			if production_type in ["food", "farm"]:
				return 0.5
		Profession.MINER:
			if production_type in ["ore", "mine"]:
				return 0.6
		Profession.FISHER:
			if production_type in ["fish", "sea"]:
				return 0.5
		Profession.BLACKSMITH:
			if production_type in ["weapon", "armor"]:
				return 0.5
	return 0.0

# Savaş bonusu
func get_damage_bonus() -> float:
	match current_profession:
		Profession.WARRIOR: return 0.3
		Profession.ARCHER: return 0.25
		Profession.KNIGHT: return 0.2
		Profession.BLACKSMITH: return 0.15
	return 0.0

func get_defense_bonus() -> float:
	match current_profession:
		Profession.KNIGHT: return 0.4
		Profession.WARRIOR: return 0.25
		Profession.MINER: return 0.2
	return 0.0