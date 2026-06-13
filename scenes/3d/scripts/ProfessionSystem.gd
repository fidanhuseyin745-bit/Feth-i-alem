class_name ProfessionSystem
extends RefCounted

enum Profession {
	NONE = 0,
	WARRIOR = 1,
	MERCHANT = 2,
	FARMER = 3,
	MINER = 4,
	FISHER = 5,
	BLACKSMITH = 6,
	ARCHER = 7,
	HEALER = 8,
	EXPLORER = 9,
	KNIGHT = 10,
}

static func get_profession_info(profession: Profession) -> Dictionary:
	var info := {
		Profession.NONE: {"name": "Yok", "bonus": 0},
		Profession.WARRIOR: {"name": "Savasci", "bonus": 20},
		Profession.MERCHANT: {"name": "Tuccar", "bonus": 30},
		Profession.FARMER: {"name": "Ciftci", "bonus": 50},
		Profession.MINER: {"name": "Madenci", "bonus": 60},
		Profession.FISHER: {"name": "Balikci", "bonus": 70},
		Profession.BLACKSMITH: {"name": "Demirci", "bonus": 50},
		Profession.ARCHER: {"name": "Okcu", "bonus": 50},
		Profession.HEALER: {"name": "Sifaci", "bonus": 50},
		Profession.EXPLORER: {"name": "Kaseif", "bonus": 60},
		Profession.KNIGHT: {"name": "Sovalye", "bonus": 40},
	}
	return info.get(profession, info[Profession.NONE])
