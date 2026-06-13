extends Node

class_name ProfessionSystem

enum Profession {
	WARRIOR,
	MERCHANT,
	FARMER,
	MINER,
	FISHER,
	BLACKSMITH,
	ARCHER,
	HEALER,
	SCOUT,
	KNIGHT
}

var current_profession: int = Profession.WARRIOR

func get_profession_name() -> String:
	match current_profession:
		Profession.WARRIOR: return "Savaşçı"
		Profession.MERCHANT: return "Tüccar"
		Profession.FARMER: return "Çiftçi"
		Profession.MINER: return "Madenci"
		Profession.FISHER: return "Balıkçı"
		Profession.BLACKSMITH: return "Demirci"
		Profession.ARCHER: return "Okçu"
		Profession.HEALER: return "Şifacı"
		Profession.SCOUT: return "Kaşif"
		Profession.KNIGHT: return "Şövalye"
	return "Bilinmeyen Meslek"

func set_profession(prof_id: int):
	current_profession = prof_id


func get_profession_id() -> int:
	return current_profession
