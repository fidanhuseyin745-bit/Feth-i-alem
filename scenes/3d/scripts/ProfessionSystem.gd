extends Node
class_name ProfessionSystem

## Meslek sistemi - Oyuncunun açık dünyada farklı meslekleri seçmesi

signal profession_changed(old_prof: String, new_prof: String)
signal skill_gained(skill: String)
signal level_up(profession: String, level: int)

enum Profession {
	NONE,
	WARRIOR,      # Savaşçı
	MERCHANT,     # Tüccar
	FARMER,       # Çiftçi
	MINER,        # Madenci
	FISHER,       # Balıkçı
	CARPENTER,    # Marangoz
	BLACKSMITH,   # Demirci
	ARCHER,       # Okçu
	KNIGHT,       # Şövalye
	BERSERKER,    # Berserker
	HEALER,       # Şifacı
	SCOUT,        # Kaşif
	TRADER,       # Gezgin Tüccar
	PIRATE        # Korsan
}

var current_profession: Profession = Profession.NONE
var profession_level: int = 1
var experience: int = 0
var experience_to_next_level: int = 100

# Meslek bonusları
var stat_bonuses: Dictionary = {
	"damage": 0,
	"defense": 0,
	"speed": 0,
	"trade_bonus": 0,
	"craft_bonus": 0,
	"resource_bonus": 0
}

# Yetenekler
var skills: Array[String] = []
var unlocked_abilities: Array[String] = []

# Meslek ağacı
var profession_tree: Dictionary = {
	Profession.WARRIOR: {
		"name": "Savaşçı",
		"description": "Yakın dövüş ustası. Hasar +20%, Savunma +10%",
		"icon": "⚔️",
		"base_stats": {"damage": 20, "defense": 10, "speed": 5},
		"skills": ["Güçlü Vuruş", "Kalkan Blok", "Savaş Narası"],
		"upgrades_to": [Profession.KNIGHT, Profession.BERSERKER]
	},
	Profession.MERCHANT: {
		"name": "Tüccar",
		"description": "Ticaret uzmanı. Satış fiyatları +30%, Alış fiyatları -20%",
		"icon": "💰",
		"base_stats": {"damage": 0, "defense": 5, "speed": 10, "trade_bonus": 30},
		"skills": ["Ticaret Hıncı", "Fiyat Bilgisi", "Kalabalık Pazarlık"],
		"upgrades_to": [Profession.TRADER]
	},
	Profession.FARMER: {
		"name": "Çiftçi",
		"description": "Tarım ustası. Hasat +50%, Hayvancılık +30%",
		"icon": "🌾",
		"base_stats": {"damage": 0, "defense": 5, "speed": 5, "resource_bonus": 50},
		"skills": ["Verimli Toprak", "Hayvan Terbiyesi", "Depolama"],
		"upgrades_to": []
	},
	Profession.MINER: {
		"name": "Madenci",
		"description": "Maden çıkarma ustası. Maden +60%, Değerli taş +20%",
		"icon": "⛏️",
		"base_stats": {"damage": 5, "defense": 10, "speed": 3, "resource_bonus": 60},
		"skills": ["Gözü Kara", "Yer Bulma", "Patlayıcı Kullanımı"],
		"upgrades_to": [Profession.BLACKSMITH]
	},
	Profession.FISHER: {
		"name": "Balıkçı",
		"description": "Deniz ustası. Balık +70%, Deniz ticareti +40%",
		"icon": "🐟",
		"base_stats": {"damage": 0, "defense": 3, "speed": 8, "trade_bonus": 20},
		"skills": ["Balık Takibi", "Deniz Haritası", "Dalış"],
		"upgrades_to": [Profession.PIRATE]
	},
	Profession.CARPENTER: {
		"name": "Marangoz",
		"description": "İnşaat ustası. Bina +40%, Onarım +30%",
		"icon": "🪓",
		"base_stats": {"damage": 0, "defense": 5, "speed": 5, "craft_bonus": 40},
		"skills": ["Sağlam İnşaat", "Dekorasyon", "Mobilya Yapımı"],
		"upgrades_to": []
	},
	Profession.BLACKSMITH: {
		"name": "Demirci",
		"description": "Silah yapım ustası. Silah +50%, Zırh +30%",
		"icon": "🔨",
		"base_stats": {"damage": 15, "defense": 15, "speed": 0, "craft_bonus": 50},
		"skills": ["Silah Dövme", "Zırh Yapımı", "Nadir Metal İşleme"],
		"upgrades_to": []
	},
	Profession.ARCHER: {
		"name": "Okçu",
		"description": "Uzaktan saldırı ustası. Menzil +50%, Hassas nişan",
		"icon": "🏹",
		"base_stats": {"damage": 25, "defense": 0, "speed": 10, "resource_bonus": 10},
		"skills": ["Hassas Nişan", "Gizli Ok", "Çoklu Ok"],
		"upgrades_to": [Profession.SCOUT]
	},
	Profession.KNIGHT: {
		"name": "Şövalye",
		"description": "Osmanlı süvari birliği. At +40%, Kalkan +30%",
		"icon": "🛡️",
		"base_stats": {"damage": 25, "defense": 25, "speed": 15},
		"skills": ["At Binme", "Şarampol", "Şövalye Onuru"],
		"upgrades_to": []
	},
	Profession.BERSERKER: {
		"name": "Berserker",
		"description": "Çılgın savaşçı. Hasar +60%, Savunma -20%, Can +30%",
		"icon": "🪓",
		"base_stats": {"damage": 40, "defense": -10, "speed": 10},
		"skills": ["Öfke", "Kan Susamışlığı", "Kırıcı Darbe"],
		"upgrades_to": []
	},
	Profession.HEALER: {
		"name": "Şifacı",
		"description": "Şifa ustası. Can yenileme +50%, Iyileştirme +40%",
		"icon": "💊",
		"base_stats": {"damage": 0, "defense": 10, "speed": 5},
		"skills": ["Şifa Büyüsü", "Bitki Bilgisi", "Tıp"],
		"upgrades_to": []
	},
	Profession.SCOUT: {
		"name": "Kaşif",
		"description": "Keşif ustası. Harita +60%, Gizlenme +40%",
		"icon": "🗺️",
		"base_stats": {"damage": 10, "defense": 5, "speed": 20},
		"skills": ["Gizli Yürüyüş", "Harita Yapımı", "İstihbarat"],
		"upgrades_to": []
	},
	Profession.TRADER: {
		"name": "Gezgin Tüccar",
		"description": "Uzak ticaret uzmanı. Karavan +50%, Yol güvenliği +30%",
		"icon": "🐪",
		"base_stats": {"damage": 0, "defense": 10, "speed": 15, "trade_bonus": 50},
		"skills": ["Kervan Yönetimi", "Yol Bilgisi", "Dilbilgisi"],
		"upgrades_to": []
	},
	Profession.PIRATE: {
		"name": "Korsan",
		"description": "Deniz haydutu. Yağma +60%, Tekne +40%",
		"icon": "🏴‍☠️",
		"base_stats": {"damage": 30, "defense": 5, "speed": 15},
		"skills": ["Korsanlık", "Tekne Kullanımı", "Ganimet"],
		"upgrades_to": []
	}
}

func _ready():
	pass

func get_available_professions() -> Array:
	return profession_tree.keys()

func get_profession_info(prof: Profession) -> Dictionary:
	if profession_tree.has(prof):
		return profession_tree[prof]
	return {}

func set_profession(prof: Profession) -> bool:
	if not profession_tree.has(prof):
		return false
	
	var old_prof = current_profession
	current_profession = prof
	
	# Statları güncelle
	_apply_profession_bonuses(prof)
	
	# Yetenekleri güncelle
	_update_skills(prof)
	
	profession_changed.emit(_get_profession_name(old_prof), _get_profession_name(prof))
	
	return true

func _apply_profession_bonuses(prof: Profession):
	var prof_data = profession_tree[prof]
	var base_stats = prof_data.get("base_stats", {})
	
	# Seviye bonusu
	var level_multiplier = 1.0 + (profession_level - 1) * 0.1
	
	stat_bonuses = {
		"damage": base_stats.get("damage", 0) * level_multiplier,
		"defense": base_stats.get("defense", 0) * level_multiplier,
		"speed": base_stats.get("speed", 0) * level_multiplier,
		"trade_bonus": base_stats.get("trade_bonus", 0),
		"craft_bonus": base_stats.get("craft_bonus", 0),
		"resource_bonus": base_stats.get("resource_bonus", 0)
	}

func _update_skills(prof: Profession):
	var prof_data = profession_tree[prof]
	skills = prof_data.get("skills", [])
	
	# Kilit açma
	unlocked_abilities.clear()
	for skill in skills:
		if profession_level >= 2 or skills.find(skill) < 3:
			unlocked_abilities.append(skill)

func gain_experience(amount: int):
	experience += amount
	
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level_up_internal()

func level_up_internal():
	profession_level += 1
	experience_to_next_level = 100 + (profession_level * 50)
	
	_apply_profession_bonuses(current_profession)
	_update_skills(current_profession)
	
	level_up.emit(_get_profession_name(current_profession), profession_level)

func get_total_damage(base_damage: int) -> int:
	return base_damage + stat_bonuses["damage"]

func get_total_defense(base_defense: int) -> int:
	return base_defense + stat_bonuses["defense"]

func get_trade_modifier() -> float:
	return 1.0 + (stat_bonuses["trade_bonus"] / 100.0)

func get_resource_modifier(resource_type: String) -> float:
	return 1.0 + (stat_bonuses["resource_bonus"] / 100.0)

func _get_profession_name(prof: Profession) -> String:
	if profession_tree.has(prof):
		return profession_tree[prof]["name"]
	return "Yok"

func get_current_profession_name() -> String:
	return _get_profession_name(current_profession)

func get_profession_icon() -> String:
	if profession_tree.has(current_profession):
		return profession_tree[current_profession]["icon"]
	return "❓"

func can_upgrade_to(prof: Profession) -> bool:
	if not profession_tree.has(prof):
		return false
	
	var prof_data = profession_tree[current_profession]
	var upgrades = prof_data.get("upgrades_to", [])
	return prof in upgrades

func get_upgrade_options() -> Array[Profession]:
	if not profession_tree.has(current_profession):
		return []
	
	var prof_data = profession_tree[current_profession]
	var upgrades = prof_data.get("upgrades_to", [])
	return upgrades

func get_profession_description() -> String:
	if profession_tree.has(current_profession):
		return profession_tree[current_profession]["description"]
	return "Henüz meslek seçmediniz."

func reset_profession():
	current_profession = Profession.NONE
	profession_level = 1
	experience = 0
	stat_bonuses = {"damage": 0, "defense": 0, "speed": 0, "trade_bonus": 0, "craft_bonus": 0, "resource_bonus": 0}
	skills.clear()
	unlocked_abilities.clear()

func save_data() -> Dictionary:
	return {
		"current_profession": current_profession,
		"profession_level": profession_level,
		"experience": experience
	}

func load_data(data: Dictionary):
	current_profession = data.get("current_profession", Profession.NONE)
	profession_level = data.get("profession_level", 1)
	experience = data.get("experience", 0)
	
	if profession_tree.has(current_profession):
		_apply_profession_bonuses(current_profession)
		_update_skills(current_profession)