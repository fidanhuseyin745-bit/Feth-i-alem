extends Node
class_name SiegeSystem

## Kuşatma Sistemi - Kaleler ve Şehirler İçin

signal siege_started(castle_id: int, attacker: int)
signal siege_progress(castle_id: int, progress: float)
signal siege_ended(castle_id: int, winner: int)
signal wall_breached(castle_id: int)

@export var siege_duration: float = 300.0  # 5 dakika
@export var breach_threshold: float = 0.7  # %70 hasar = sur yıkılır

var active_sieges: Dictionary = {}
var siege_engines: Array = []

const SIEGE_TYPE_BATTLE = 0
const SIEGE_TYPE_STARVE = 1
const SIEGE_TYPE_ASSAULT = 2

func _ready():
	print("Kuşatma sistemi hazır")

func start_siege(castle_id: int, attacker_faction: int, siege_type: int = SIEGE_TYPE_BATTLE):
	if castle_id in active_sieges:
		return  # Zaten kuşatma altında
	
	var siege_data = {
		"castle_id": castle_id,
		"attacker": attacker_faction,
		"defender": -1,  # Belirlenecek
		"type": siege_type,
		"start_time": Time.get_ticks_msec() / 1000.0,
		"duration": siege_duration,
		"progress": 0.0,
		"wall_health": 100.0,
		"is_breached": false,
		"engine_count": 0
	}
	
	active_sieges[castle_id] = siege_data
	emit_signal("siege_started", castle_id, attacker_faction)
	print("Kuşatma başladı - Kale: " + str(castle_id))

func update_siege(castle_id: int, delta: float):
	if castle_id not in active_sieges:
		return
	
	var siege = active_sieges[castle_id]
	var elapsed = Time.get_ticks_msec() / 1000.0 - siege["start_time"]
	
	siege["progress"] = clamp(elapsed / siege["duration"], 0.0, 1.0)
	
	# Kuşatma tipine göre ilerleme
	match siege["type"]:
		SIEGE_TYPE_BATTLE:
			_process_battle_siege(siege, delta)
		SIEGE_TYPE_STARVE:
			_process_starve_siege(siege, delta)
		SIEGE_TYPE_ASSAULT:
			_process_assault_siege(siege, delta)
	
	emit_signal("siege_progress", castle_id, siege["progress"])
	
	# Sür başarılırsa
	if siege["wall_health"] <= 0 and not siege["is_breached"]:
		siege["is_breached"] = true
		emit_signal("wall_breached", castle_id)
	
	# Kuşatma tamamlanırsa
	if siege["progress"] >= 1.0:
		end_siege(castle_id, siege["attacker"])

func _process_battle_siege(siege: Dictionary, delta: float):
	# Savaş kuşatması - sürekli hasar
	var damage = delta * (5.0 + siege["engine_count"] * 2.0)
	siege["wall_health"] -= damage

func _process_starve_siege(siege: Dictionary, delta: float):
	# Açlık kuşatması - yavaş ama emin
	var damage = delta * 0.5
	siege["wall_health"] -= damage

func _process_assault_siege(siege: Dictionary, delta: float):
	# Saldırı kuşatması - hızlı ama riskli
	var damage = delta * (10.0 + siege["engine_count"] * 5.0)
	siege["wall_health"] -= damage

func add_siege_engine(castle_id: int):
	if castle_id in active_sieges:
		active_sieges[castle_id]["engine_count"] += 1
		print("Kuşatma engines eklendi")

func remove_siege_engine(castle_id: int):
	if castle_id in active_sieges:
		active_sieges[castle_id]["engine_count"] = max(0, active_sieges[castle_id]["engine_count"] - 1)

func end_siege(castle_id: int, winner: int):
	if castle_id in active_sieges:
		emit_signal("siege_ended", castle_id, winner)
		print("Kuşatma sona erdi - Kazanan: " + str(winner))
		active_sieges.erase(castle_id)

func cancel_siege(castle_id: int):
	if castle_id in active_sieges:
		active_sieges.erase(castle_id)
		print("Kuşatma iptal edildi")

func is_under_siege(castle_id: int) -> bool:
	return castle_id in active_sieges

func get_siege_progress(castle_id: int) -> float:
	if castle_id in active_sieges:
		return active_sieges[castle_id]["progress"]
	return 0.0

func get_siege_info(castle_id: int) -> Dictionary:
	if castle_id in active_sieges:
		return active_sieges[castle_id]
	return {}

func get_all_active_sieges() -> Dictionary:
	return active_sieges

func get_siege_count() -> int:
	return active_sieges.size()