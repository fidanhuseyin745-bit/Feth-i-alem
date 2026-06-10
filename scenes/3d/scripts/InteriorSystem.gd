extends Node
class_name InteriorSystem

## İç mekan fetih sistemi - Kaleler ve şehirler içinde savaş

signal interior_entered(city: City)
signal interior_exited()
signal room_cleared(room_id: String)
signal enemy_encountered(enemies: Array)
signal interior_completed(city: City)

const Unit = preload("res://scenes/3d/scripts/Unit.gd")

enum RoomType { HALL, BARRACKS, ARMORY, STORAGE, GATE, TOWER, THRONE }

var current_city: City = null
var current_room: String = "giris"
var enemies_in_room: Array[Unit] = []
var cleared_rooms: Array[String] = []

# Oda verileri
var rooms: Dictionary = {
	"giris": {
		"name": "Giriş Kapısı",
		"type": RoomType.GATE,
		"enemies": 3,
		"enemy_type": "piyade",
		"cleared": false,
		"next_rooms": ["avlu", "kışla"]
	},
	"avlu": {
		"name": "Avlu",
		"type": RoomType.HALL,
		"enemies": 5,
		"enemy_type": "karışık",
		"cleared": false,
		"next_rooms": ["giris", "kale_duvarı"]
	},
	"kışla": {
		"name": "Kışla",
		"type": RoomType.BARRACKS,
		"enemies": 8,
		"enemy_type": "piyade",
		"cleared": false,
		"next_rooms": ["giris", "silah_depo"]
	},
	"kale_duvarı": {
		"name": "Kale Duvarı",
		"type": RoomType.TOWER,
		"enemies": 6,
		"enemy_type": "okçu",
		"cleared": false,
		"next_rooms": ["avlu", "kule"]
	},
	"silah_depo": {
		"name": "Silah Deposu",
		"type": RoomType.ARMORY,
		"enemies": 4,
		"enemy_type": "süvari",
		"cleared": false,
		"next_rooms": ["kışla", "ambar"]
	},
	"ambar": {
		"name": "Ambar",
		"type": RoomType.STORAGE,
		"enemies": 3,
		"enemy_type": "piyade",
		"cleared": false,
		"next_rooms": ["silah_depo", "taht"]
	},
	"kule": {
		"name": "Kule",
		"type": RoomType.TOWER,
		"enemies": 4,
		"enemy_type": "okçu",
		"cleared": false,
		"next_rooms": ["kale_duvarı"]
	},
	"taht": {
		"name": "Taht Odası",
		"type": RoomType.THRONE,
		"enemies": 10,
		"enemy_type": "karışık",
		"cleared": false,
		"next_rooms": ["ambar"]
	}
}

func enter_city(city: City):
	current_city = city
	current_room = "giris"
	cleared_rooms.clear()
	_spawn_room_enemies()
	interior_entered.emit(city)

func exit_city():
	current_city = null
	_clear_enemies()
	interior_exited.emit()

func _spawn_room_enemies():
	if not rooms.has(current_room):
		return
	
	var room_data = rooms[current_room]
	_clear_enemies()
	
	if room_data["cleared"]:
		return  # Zaten temizlendiyse düşman yok
	
	var enemy_count = room_data["enemies"]
	var enemy_type = room_data["enemy_type"]
	
	for i in enemy_count:
		var enemy = _create_enemy(enemy_type)
		enemy.global_position = _get_random_room_position()
		enemies_in_room.append(enemy)
	
	if enemies_in_room.size() > 0:
		enemy_encountered.emit(enemies_in_room)

func _create_enemy(enemy_type: String) -> Unit:
	var enemy = Unit.new()
	enemy.team = "enemy"
	
	# Oda tipine göre güçlü düşmanlar
	match current_room:
		"taht":
			enemy.max_health = 150
			enemy.damage = 25
			enemy.unit_name = "Şövalye"
		"kule":
			enemy.max_health = 80
			enemy.damage = 22
			enemy.attack_range = 10.0
			enemy.unit_name = "Okçu"
		_:
			enemy.max_health = 80
			enemy.damage = 15
			enemy.unit_name = "Savunucu"
	
	enemy.health = enemy.max_health
	
	match enemy_type:
		"piyade":
			enemy.unit_type = Unit.UnitType.INFANTRY
		"süvari":
			enemy.unit_type = Unit.UnitType.CAVALRY
			enemy.speed = 6.0
		"okçu":
			enemy.unit_type = Unit.UnitType.ARCHER
			enemy.attack_range = 12.0
		"karışık":
			var types = [Unit.UnitType.INFANTRY, Unit.UnitType.CAVALRY, Unit.UnitType.ARCHER]
			enemy.unit_type = types[randi() % types.size()]
	
	return enemy

func _get_random_room_position() -> Vector3:
	# Rastgele oda içi pozisyon
	var base = current_city.global_position if current_city else Vector3.ZERO
	return base + Vector3(
		randf() * 10 - 5,
		0,
		randf() * 10 - 5
	)

func _clear_enemies():
	for enemy in enemies_in_room:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_in_room.clear()

func _process(delta):
	# Düşman AI kontrolü
	for enemy in enemies_in_room:
		if is_instance_valid(enemy) and enemy.current_state != Unit.UnitState.DEAD:
			# Düşman oyuncuya doğru hareket et
			_update_enemy_ai(enemy, delta)

func _update_enemy_ai(enemy: Unit, delta: float):
	# Basit AI - en yakın oyuncu birimine saldır
	var target = _find_closest_player_unit(enemy)
	if target:
		enemy.target = target
		enemy.current_state = Unit.UnitState.ATTACKING

func _find_closest_player_unit(from: Unit) -> Unit:
	# Burada oyuncu birimlerini bulmalıyız
	# Şimdilik null döndür
	return null

func attack_enemy(unit: Unit, enemy: Unit):
	unit.target = enemy
	unit.current_state = Unit.UnitState.ATTACKING

func clear_room():
	if not rooms.has(current_room):
		return
	
	rooms[current_room]["cleared"] = true
	cleared_rooms.append(current_room)
	room_cleared.emit(current_room)
	
	# Odadan çıkış seçenekleri
	var room_data = rooms[current_room]
	var available_exits = room_data["next_rooms"].duplicate()
	
	# Temizlenmemiş odalara geçiş
	for exit in available_exits:
		if exit in cleared_rooms:
			available_exits.erase(exit)
	
	if current_room == "taht" and "taht" in cleared_rooms:
		# Kale tamamen fethedildi!
		_complete_interior()

func _complete_interior():
	interior_completed.emit(current_city)

func get_current_room_info() -> Dictionary:
	if not rooms.has(current_room):
		return {}
	
	var room_data = rooms[current_room]
	var enemy_count = 0
	for enemy in enemies_in_room:
		if is_instance_valid(enemy) and enemy.current_state != Unit.UnitState.DEAD:
			enemy_count += 1
	
	return {
		"name": room_data["name"],
		"enemies_remaining": enemy_count,
		"cleared": room_data["cleared"],
		"exits": room_data["next_rooms"]
	}

func move_to_room(room_id: String):
	if not rooms.has(room_id):
		return
	
	var room_data = rooms[current_room]
	if room_id in room_data["next_rooms"]:
		current_room = room_id
		_spawn_room_enemies()

func get_available_rooms() -> Array:
	if not rooms.has(current_room):
		return []
	return rooms[current_room]["next_rooms"]

func is_room_cleared(room_id: String) -> bool:
	return room_id in cleared_rooms

func reset_city_state():
	cleared_rooms.clear()
	for room_id in rooms:
		rooms[room_id]["cleared"] = false